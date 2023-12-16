//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import Foundation
import Combine
import AVFoundation
import UIKit

/// A Service who publishes ``DetectedObject``s, ``ObjectDetectionError`` and performance metrics. To use SBB ML, this service needs to be passed to ``CameraStreamView`` as init parameter.
public class ObjectDetectionService: ObjectDetectionServiceProtocol {
    
    /// Publishes all detected objects (and updates their frames)
    public var detectedObjectsPublisher: AnyPublisher<[DetectedObject], Never> {
        detectedObjectsSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    private let detectedObjectsSubject = CurrentValueSubject<[DetectedObject], Never>([DetectedObject]())
    private var detectedObjectsSubscription: Cancellable!
    
    /// Publishes all errors occuring during the usage of ``ObjectDetectionService``
    public var errorPublisher: AnyPublisher<ObjectDetectionError?, Never> {
        errorSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    private let errorSubject = CurrentValueSubject<ObjectDetectionError?, Never>(nil)
    private var errorSubscription: Cancellable!
    
    /// Publishes the inference time of every object detection iteration during the usage of ``ObjectDetectionService``
    public var currentObjectDetectionInferenceTimePublisher: AnyPublisher<TimeInterval, Never> {
        currentObjectDetectionInferenceTimeSubject
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .eraseToAnyPublisher()
    }
    private let currentObjectDetectionInferenceTimeSubject = CurrentValueSubject<TimeInterval, Never>(0)
    private var currentObjectDetectionInferenceTimeSubscription: Cancellable!
    
    private var cameraOutputSubscription: Cancellable!
    
    let configuration: ObjectDetectionServiceConfiguration
    let modelFileName: String
    var cameraController: CameraControllerProtocol
    private var objectDetection: ObjectDetectionProtocol
    private var objectTracking: ObjectTrackingProtocol
    private var lastObjectDetectionCall: TimeInterval = 0
    
    /**
     Returns an ``ObjectDetectionService`` who publishes ``DetectedObject``s, ``ObjectDetectionError`` and performance metrics.
     
     - Parameters:
        - modelFileName: The name (without suffix) of the CoreML model generated by the SBB ML pipeline. The CoreML model file needs to be added to your App target.
        - configuration: The parametrizable ``ObjectDetectionServiceConfiguration``. You should only specify a custom configuration, if you do not want to use the (optimized) default configuration.
     */
    public init(modelFileName: String, configuration: ObjectDetectionServiceConfiguration = ObjectDetectionServiceConfiguration()) {
        self.modelFileName = modelFileName
        self.configuration = configuration
        self.cameraController = CameraController(previewVideoGravity: configuration.previewVideoGravity, depthRecordingEnabled: configuration.distanceRecordingEnabled)
        self.objectDetection = ObjectDetection(modelProvider: ModelProvider(modelFileName: modelFileName, computeUnits: configuration.computeUnits), thresholdProvider: ThresholdProvider(confidenceThreshold: Double(configuration.confidenceThreshold), iouThreshold: configuration.iouThreshold), inferencePerformanceAnalysis: InferencePerformanceAnalysis(), depthRecognition: DepthRecognition())
        self.objectTracking = ObjectTracking(confidenceThreshold: configuration.objectTrackingConfidenceThreshold)
        
        setupSubsriptions(for: configuration)
    }
    
    /**
     Requests authorization for media capture (camera) and configures the AVCaptureDevice. By default, camera authorization is automatically requested when ``CameraStreamView`` appears for the first time on the screen. However you can also trigger the prompt manually by calling ``requestCameraAuthorization()`` (e.g. during Onboarding).
     */
    public func requestCameraAuthorization() {
        cameraController.requestCameraAuthorizationAndConfigureCaptureSession()
    }

    private func setupSubsriptions(for configuration: ObjectDetectionServiceConfiguration) {
        errorSubscription = objectDetection.errorPublisher
            .merge(with: cameraController.errorPublisher)
            .multicast(subject: errorSubject)
            .connect()
        
        detectedObjectsSubscription = objectDetection.detectedObjectsPublisher
            .map({ detectedObjects -> [DetectedObject] in
                guard let labels = configuration.detectableClassLabels else {
                    return detectedObjects
                }
                return detectedObjects.filter { labels.contains($0.label) }
            })
            .map({ [weak self] detectedObjects -> [DetectedObject] in
                if configuration.objectTrackingEnabled && !detectedObjects.isEmpty {
                    self?.objectTracking.startTracking(objects: detectedObjects)
                }
                return detectedObjects
            })
            .merge(with: objectTracking.trackedObjectsPublisher)
            .multicast(subject: detectedObjectsSubject)
            .connect()
        
        cameraOutputSubscription = cameraController.cameraOutputPublisher
            .compactMap { $0 }
            .sink { [weak self] cameraOutput in
                let currentDate = NSDate.timeIntervalSinceReferenceDate
                // Run object detection at the given pace and track objects in between
                if currentDate - (self?.lastObjectDetectionCall ?? 0) >= configuration.objectDetectionRate {
                    self?.lastObjectDetectionCall = currentDate
                    self?.objectTracking.stopTracking()
                    self?.objectDetection.detectObjects(in: cameraOutput.videoBuffer, depthBuffer: cameraOutput.depthBuffer)
                } else if configuration.objectTrackingEnabled && (self?.objectTracking.isTracking ?? false) {
                    self?.objectTracking.updateTrackedObjects(in: cameraOutput.videoBuffer)
                }
            }
        
        currentObjectDetectionInferenceTimeSubscription = objectDetection.inferencePerformanceAnalysis?.currentInferenceTimePublisher
            .multicast(subject: currentObjectDetectionInferenceTimeSubject)
            .connect()
    }
          
    func updatePreviewLayer() {
        objectDetection.previewLayer = cameraController.previewLayer
        objectTracking.previewLayer = cameraController.previewLayer
    }
    
    deinit {
        objectDetection.stop()
    }
    
    // Initializer used for UnitTesting
    init(configuration: ObjectDetectionServiceConfiguration = ObjectDetectionServiceConfiguration(), cameraController: CameraControllerProtocol, objectDetection: ObjectDetectionProtocol, objectTracking: ObjectTrackingProtocol) {
        self.modelFileName = ""
        self.configuration = configuration
        self.cameraController = cameraController
        self.objectDetection = objectDetection
        self.objectTracking = objectTracking
        
        setupSubsriptions(for: configuration)
    }
}
