//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import Foundation
import Combine
import AVFoundation
import UIKit
@testable import SBBML

class FakeCameraController: CameraControllerProtocol {
    
    let cameraOutputSubject = PassthroughSubject<CameraOutput?, Never>()
    var cameraOutputPublisher: AnyPublisher<CameraOutput?, Never> {
        return cameraOutputSubject.eraseToAnyPublisher()
    }
    
    let errorSubject = PassthroughSubject<ObjectDetectionError?, Never>()
    var e