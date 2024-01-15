//
// Copyright (C) Schweizerische Bundesbahnen SBB, 2021.
//

import Foundation

enum BuiltinMLModel: String, CaseIterable {
    case bahnhofM640Int8 = "bahnhof_yolov5m6_640_int8"
    case bahnhofM640Float16 = "bahnhof_yolov5m6_640_float16"
    case bahnhofM640Float32 = "bahnhof_yolov5m6_640_float32"
    case bahnhofS640Int8 = "bahnhof_yolov5s6_640_int8"
    case bahnhofS640Float16 = "bahnhof_yolov5s6_640_float16"
    case bahnhofS640Float32 = "bahnhof_yolov5s6_640_float32"
    
    case wagenM640Int8 = "wagen_yolov5m_640_int8"
    case wagenM640Float16 = "wagen_yolov5m_640_float16"
    case wagenM640Float32 = "wagen_yolov5m_640_float32"
    case wagenN640Int8 = "wagen_yolov5n_640_int8"
    case wagenN640Float16 = "wagen_yolov5n_640_float16"
    case wagenN640Float32 = "wagen_yolov5n_640_float32"
    
    case universalM640Int8 = "universal_yolov5m_640_int8"
    case universalM640Float16 = "universal_yolov5m_640