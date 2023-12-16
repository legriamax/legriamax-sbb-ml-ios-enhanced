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
        