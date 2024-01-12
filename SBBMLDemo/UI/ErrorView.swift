//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import SwiftUI
import SBBML

struct ErrorView: View {
    
    let error: ObjectDetectionError
    
    var body: some View {
        VStack(spacing: 8) {
            Spacer()
            Image(sbbName: "camera", size: .medium)
            Text("An error 