# AR Measurement Scene Setup Guide

## Required GameObjects

### 1. AR Session
- Create empty GameObject
- Add AR Session component
- Add AR Input Manager component

### 2. XR Origin (AR Camera)
- Create XR Origin GameObject
- Includes AR Camera and device tracking
- Position: (0, 0, 0)
- Configure AR Camera settings

### 3. AR Plane Manager
- Add to XR Origin
- Enable plane detection (horizontal planes)
- Assign plane prefab for visualization
- Set detection mode to "Everything"

### 4. AR Raycast Manager
- Add to XR Origin
- Handles touch-to-AR-world raycasting
- Required for point placement

### 5. AR Measurement Manager
- Create empty GameObject named "ARMeasurementManager"
- Add ARMeasurementManager script
- Configure point prefab reference
- Set materials for placed/completed points

### 6. Unity Message Manager
- Create empty GameObject named "UnityMessageManager"
- Add UnityMessageManager script
- Ensure it's marked as DontDestroyOnLoad

## Prefabs to Create

### Point Marker Prefab
1. Create sphere primitive
2. Scale to (0.02, 0.02, 0.02)
3. Create materials:
   - Red material for placing points
   - Green material for completed measurement
4. Add to prefab folder
5. Reference in ARMeasurementManager

## Scene Build Settings
- Add scene to build settings (index 0)
- Ensure it's the first scene in build

## XR Management Configuration
- Window > XR > XR Management
- Enable appropriate providers:
  - ARCore (Android)
  - ARKit (iOS)
- Set Initialize on Startup: true

## Testing in Unity
1. Build and run on AR-capable device
2. Grant camera permissions
3. Point at flat surface
4. Tap to place 4 corner points
5. Verify measurement calculation

## Integration Notes
- Scene will be loaded by flutter_unity_widget
- Communication happens via UnityMessageManager
- Ensure all required scripts are attached
- Test AR capability detection