//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import XCTest
import AVFoundation
@testable import SBBML

class ObjectDetectionServiceTests: XCTestCase {
    
    private let timeout = TimeInterval(3.0)
    private var objectDetectionService: ObjectDetectionService!
    private var fakeCameraController: FakeCameraController!
    private var fakeObjectDetection: FakeObjectDetection!
    private var fakeObjectTracking: FakeObjectTracking!
    
    private let fakeDetectedObjects1 = [DetectedObject(label: "Object 1", confidence: 0.9, depth: nil, rect: CGRect(), rectInPreviewLayer: CGRect())]
    private let fakeDetectedObjects2 = [DetectedObject(label: "Object 2", confidence: 0.2, depth: nil, rect: CGRect(), rectInPreviewLayer: CGRect())]

    override func setUpWithError() throws {
        self.fakeCameraController = FakeCameraController()
        self.fakeObjectDetection = FakeObjectDetection()
        self.fakeObjectTracking = FakeObjectTracking()
        self.objectDetectionService = ObjectDetectionService(cameraController: fakeCameraController, objectDetection: fakeObjectDetection, objectTracking: fakeObjectTracking)
    }
    
    // MARK: detectedObjectsPublisher tests

    func testDetectedObjectsArePublished() throws {
        let expectation = self.expectation(description: "wait for detected objects")
        
        var counter = 0
        let sub = objectDetectionService.detectedObjectsPublisher.sink { detectedObjects in
            counter += 1
            switch counter {
            case 1:
                XCTAssertTrue(detectedObjects.isEmpty)
                self.fakeObjectDetection.detectedObjectsSubject.send(self.fakeDetectedObjects1)
            case 2:
                XCTAssertEqual(detectedObjects, self.fakeDetectedObjects1)
                self.fakeObjectDetection.detectedObjectsSubject.send(self.fakeDetectedObjects2)
            case 3:
                XCTAssertEqual(detectedObjects, self.fakeDetectedObjects2)
                self.fakeObjectDetection.detectedObjectsSubject.send([])
            case 4:
                XCTAssertTrue(detectedObjects.isEmpty)
                expectation.fulfill()
            default:
                XCTFail()
            }
        }
                
        waitForExpectations(timeout: timeout) { _ in
            sub.cancel()
        }
    }
    
    func testObjectTrackingIsStarted() throws {
        self.objectDetectionService = ObjectDetectionService(configuration: ObjectDetectionServiceConfiguration(objectDetectionRate: 2, objectTrackingEnabled: true), cameraController: fakeCameraController, objectDetection: fakeObjectDetection, objectTracking: fakeObjectTracking)
        
        let expectation = self.expectation(description: "wait for detected objects")
        
        var counter = 0
        let sub = objectDetectionService.detectedObjectsPublisher.sink { detectedObjects in
            counter += 1
            switch cou