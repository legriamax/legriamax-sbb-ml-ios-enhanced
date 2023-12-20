//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import UIKit

extension UIDeviceOrientation {
    
    var exifOrientation: CGImagePropertyOrientation {
        switch self {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            return .left
        case UIDeviceOrientation.landscapeLeft:       // Device oriented horizontally, home button on the right
            return .upMirrored
        case UIDeviceOrientation.landscapeRight:      // Device oriented horizontally, home button on the left
            return .down
        case UIDeviceOrientation.portrait:            // Device oriented vertically, home button on the bottom
            return .right
        default:
            return .right
        }
    }
    
    var rotationForBoundingboxToFrame: CGFloat {
        switch self {
        case UIDeviceOrientation.portraitUpsideDown:  // Device oriented vertically, home button on the top
            return 0
        case UIDeviceOrientation.landscapeLeft:       // Device o