
# legriamax-sbb-ml-ios-enhanced

The framework makes integration of SBB created Core ML Object Detection models into iOS apps achievable using Combine. It shows a CameraStream Preview in your SwiftUI View and publishes identified objects, which you can utilize to draw over the CameraStream preview or apply for further app logic.

## Maintainers
- legriamax

## Supported platforms
- iOS 

## Setup

The package can be added to your project using Swift Package Manager.

For HTTPS:
```
https://github.com/legriamax/legriamax-sbb-ml-ios-enhanced.git
```
For SSH:
```
ssh://git@github.com:legriamax/legriamax-sbb-ml-ios-enhanced.git
```

## Usage

DocC documentation can be created in XCode by selecting "Product" -> "Build Documentation".
The SBBML Lib contains the following components:

- **ObjectDetectionService**: the service that publishes the detected objects, errors, and metrics.
- **ObjectDetectionServiceConfiguration**: a struct containing all adjustable parameters for object detection.
- It includes three publishers:
- **detectedObjectsPublisher**: publishes a list of DetectedObject
- **errorPublisher**: publishes the errors that may occur in the framework
- **currentObjectDetectionInferenceTimePublisher**: publishes the last inference time

## Getting involved

We welcome contributions that improve existing UI elements or fix certain bugs. Contributions introducing new design elements will also be considered but may be rejected if they do not reflect our vision of the design system.