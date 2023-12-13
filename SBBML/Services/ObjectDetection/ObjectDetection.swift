//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import AVFoundation
import Vision
import UIKit
import Combine
import Accelerate
import CoreML

class ObjectDetection: ObjectDetectionProtocol {
    
    var detectedObjectsPublisher: AnyPublisher<[DetectedObject], Never> {
        detectedObjectsSubject
            .removeDuplicates()
            .eraseToAnyPublisher()
    }
    private let detectedObjectsSubject = CurrentValueSubject<[DetectedObject], Never>([DetectedObject]())
    
    var errorPublishe