# AR Measurement Unity Project

This Unity project provides AR Foundation-based measurement functionality for the Flutter app.

## Setup Instructions

### Requirements
- Unity 2022.3 LTS or later
- AR Foundation 4.2+
- ARCore XR Plugin (Android)
- ARKit XR Plugin (iOS)

### Installation

1. Open Unity Hub
2. Open this project folder (`unity/ARMeasurement`)
3. Install required packages via Window > Package Manager:
   - AR Foundation
   - ARCore XR Plugin (for Android)
   - ARKit XR Plugin (for iOS)

### Building for Flutter

1. **Configure Build Settings:**
   - File > Build Settings
   - Select Android or iOS platform
   - Switch Platform

2. **Player Settings:**
   - Android: Set minimum API level to 24
   - iOS: Set minimum iOS version to 11.0
   - Enable XR settings for AR

3. **Export for Flutter:**
   - Build the project to generate platform-specific AR libraries
   - Copy built libraries to Flutter project structure

### Scene Setup

The main scene should include:
- ARSession (AR session management)
- XR Origin (AR camera and tracking)
- AR Plane Manager (plane detection)
- AR Raycast Manager (touch raycasting)
- ARMeasurementManager (measurement logic)
- UnityMessageManager (Flutter communication)

### Scripts Overview

- **ARMeasurementManager.cs**: Main AR measurement logic
  - Handles point placement via raycasting
  - Calculates window measurements
  - Manages visual markers
  - Communicates with Flutter

- **UnityMessageManager.cs**: Flutter-Unity communication bridge
  - Receives commands from Flutter
  - Sends measurement data to Flutter
  - Handles AR capability checking

### Communication Protocol

#### Flutter to Unity Messages
```json
{
  "command": "InitializeAR",
  "data": {
    "planeDetection": true,
    "pointCloud": true
  }
}
```

#### Unity to Flutter Messages
```json
{
  "method": "onPointPlaced",
  "data": {
    "id": "point_0",
    "position": [0.1, 0.0, 0.5],
    "timestamp": "2024-01-01T12:00:00Z"
  }
}
```

### Material Setup

Create materials for visual markers:
- **PlacedPointMaterial**: Red material for placed points
- **CompletedPointMaterial**: Green material when measurement complete

### Prefab Setup

Create a simple sphere prefab for point markers:
- Add a sphere primitive
- Apply appropriate material
- Scale to 0.02 units (2cm)
- Save as prefab in Assets/Prefabs/

### Testing

1. Build and run on AR-supported device
2. Point camera at flat surface
3. Tap to place 4 corner points
4. Verify measurements are calculated correctly
5. Test unit switching (meters/inches)

### Troubleshooting

- Ensure AR permissions are granted
- Check ARCore/ARKit installation on device
- Verify plane detection is working
- Check Unity console for error messages
- Test Flutter-Unity communication bridge