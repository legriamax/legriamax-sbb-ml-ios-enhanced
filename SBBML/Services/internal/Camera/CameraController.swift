//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import UIKit
import AVFoundation
import Combine

class CameraController: NSObject, CameraControllerProtocol {
    
    var cameraOutputPublisher: AnyPublisher<CameraOutput?, Never> {
        cameraOutputSubject
            .eraseToAnyPublisher()
    }
    private let cameraOutputSubject = CurrentValueSubject<CameraOutput?, Never>(nil)
    
    var errorPublisher: AnyPublisher<ObjectDetectionError?, Never> {
        errorSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    private let errorSubject = CurrentValueSubject<ObjectDetectionError?, Never>(nil)
        
    var previewLayer: AVCaptureVideoPreviewLayer
    private let captureSession: AVCaptureSession
    private let videoDataOutput = AVCaptureVideoDataOutput()
    private let depthDataOutput = AVCaptureDepthDataOutput()
    private var outputSynchronizer: AVCaptureDataOutputSynchronizer?
    private let previewVideoGravity: AVLayerVideoGravity
    private var depthRecordingEnabled: Bool
    private var currentDeviceSupportsDepthRecording = false
        
    init(previewVideoGravity: AVLayerVideoGravity, depthRecordingEnabled: Bool) {
        self.previewVideoGravity = previewVideoGravity
        self.depthRecordingEnabled = depthRecordingEnabled
        let captureSession = AVCaptureSession()
        self.captureSession = captureSession
        self.previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        
        super.init()
    }
    
    func requestCameraAuthorizationAndConfigureCaptureSession() {
        configure(depthRecordingEnabled: depthRecordingEnabled)
    }
        
    func displayPreview(on view: UIView) {
        self.previewLayer.videoGravity = previewVideoGravity
        
        view.layer.insertSublayer(self.previewLayer, at: 0)
        self.previewLayer.frame = view.frame
        
        self.captureSession.startRunning()
    }
    
    func removePreview() {
        self.previewLayer.removeFromSuperlayer()
        self.captureSession.stopRunning()
    }
    
    func updatePreview(for bounds: CGRect, deviceOrientation: UIDeviceOrientation) {
        previewLayer.frame = bounds
        
        switch deviceOrientation {
        case .landscapeLeft:
            previewLayer.connection?.videoOrientation = .landscapeRight
        case .landscapeRight:
            previewLayer.connection?.videoOrientation = .landscapeLeft
        case .portraitUpsideDown:
            previewLayer.connection?.videoOrientation = .portraitUpsideDown
        case .portrait:
            previewLayer.connection?.videoOrientation = .portrait
        default:
            previewLayer.connection?.videoOrientation = .portrait
        }
    }
    
    private func configure(depthRecordingEnabled: Bool) {
        self.depthRecordingEnabled = depthRecordingEnabled
        DispatchQueue(label: "prepare").async {
            guard AVCaptureDevice.authorizationStatus(for: .video) != .denied else {
                self.errorSubject.send(.deniedCameraAuthorization)
                return
            }
            
            guard self.captureSession.outputs.isEmpty && self.captureSession.inputs.isEmpty else {
                // return, since configure has already been called
                return
            }
            
            do {
                let camera = try self.configureCaptureDevices(depthRecordingEnabled: depthRecordingEnabled)
                try self.configureDeviceInputs(for: camera)
                try self.configureDeviceOutputs(depthRecordingEnabled: depthRecordingEnabled)
            } catch let error as ObjectDetectionError {
                self.errorSubject.send(error)
            } catch {
                Logger.log("Unknown error while trying to configure CameraController: \(error)", .error)
            }
        }
    }
    
    private func configureCaptureDevices(depthRecordingEnabled: Bool) throws -> AVCaptureDevice {
        guard let camera = availableCaptureDevice(depthRecordingEnabled: depthRecordingEnabled) else {
            throw ObjectDetectionError.noCamerasAvailable
        }
        
        try camera.lockForConfiguration()
        if camera.deviceType == .builtInDualWideCamera {
            // Search for highest resolution with half-point depth values
            let depthFormats = camera.activeFormat.supportedDepthDataFormats
            let filtered = depthFormats.filter({
                CMFormatDescriptionGetMediaSubType($0.formatDescription) == kCVPixelFormatType_DepthFloat16
            })
            let selectedFormat = filtered.max(by: {
                first, second in CMVideoFormatDescriptionGetDimensions(first.formatDescription).width < CMVideoFormatDescriptionGetDimensions(second.formatDescription).width
            })
            camera.activeDepthDataFormat = selectedFormat
        }
        camera.unlockForConfiguration()
        
        return camera
    }
    
    private func availableCaptureDevice(depthRecordingEnabled: Bool) -> AVCaptureDevice? {
        if depthRecordingEnabled, let device = AVCaptureDevice.default(.builtInDualWideCamera, for: .video, position: .back) {
            currentDeviceSupportsDepthRecording = true
            return device
        } else if let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back) {
            return device
        } else {
            return nil
        }
    }
    
    private func configureDeviceInputs(for camera: AVCaptureDevice) throws {
        let cameraInput = try AVCaptureDeviceInput(device: camera)
        
        captureSession.beginConfiguration()
        captureSession.sessionPreset = .vga640x480 // higher resolution is critical because it will lead to buffers being dropped
        
        if captureSession.canAddInput(cameraInput) {
            captureSession.addInput(cameraInput)
        } else {
            captureSession.commitConfiguration()
            throw ObjectDetectionError.inputsAreInvalid
        }
        
        captureSession.commitConfiguration()
    }
    
    private func configureDeviceOutputs(depthRecordingEnabled: Bool) throws {
        if captureSession.canAddOutput(videoDataOutput) {
            captureSession.addOutput(videoDataOutput)
            
            videoDataOutput.alwaysDiscardsLateVideoFrames = tr