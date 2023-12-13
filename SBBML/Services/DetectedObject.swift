//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import Foundation
import UIKit
import AVFoundation

/// An Object containing information about a detected object while running the ObjectDetection algorithm from camera input.
public struct DetectedObject: Equatable, Identifiable {
    
    /// UUID strings, to uniquely identify this DetectedObject.
    public let id = UUID()
    
    /// The class label of the detected object (according to the used CoreML model).
    public let label: String
    
    /// The confidence of the prediction ranging from 0 to 1.
    public let confidence: Float
    
    /// The approximate distance of the device to the center of the detected object. This parameter is only set when running DepthData (can be configured using ObjectDetectionServiceConfiguration).
    public let depth: Float? // in m
    
    /// The normalized bounding box of the detected object. (0,0) is the bottom left corner.
    public var rect: CGRect
    
    /// The bounding box relative