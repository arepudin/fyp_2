# Unity-Flutter Integration Guide

This guide explains how to integrate the Unity AR project with the Flutter app.

## Prerequisites

- Unity 2022.3 LTS or later
- Flutter SDK
- Android Studio (for Android builds)
- Xcode (for iOS builds)

## Step 1: Unity Project Setup

1. **Open Unity Project**
   ```bash
   # Open Unity Hub and import the project
   unity/ARMeasurement/
   ```

2. **Install Required Packages**
   - AR Foundation 4.2+
   - ARCore XR Plugin (Android)
   - ARKit XR Plugin (iOS)
   - XR Management

3. **Configure Build Settings**
   - File > Build Settings
   - Add main AR scene to build
   - Set target platform (Android/iOS)

## Step 2: Android Setup

1. **Unity Player Settings (Android)**
   ```
   Company Name: com.sabacurtain.fyp2
   Product Name: ARMeasurement
   Minimum API Level: 24
   Target API Level: 33+
   Scripting Backend: IL2CPP
   Target Architectures: ARM64
   ```

2. **XR Management Settings**
   - Enable AR Core (Android)
   - Initialize on Startup: Yes

3. **Build Unity Project**
   ```bash
   # Export Unity project for Android
   # File > Build Settings > Build
   ```

4. **Copy Unity Build to Flutter**
   ```bash
   # Copy Unity build outputs to Flutter project
   cp -r unity_build/* android/unityLibrary/
   ```

## Step 3: iOS Setup

1. **Unity Player Settings (iOS)**
   ```
   Bundle Identifier: com.sabacurtain.fyp2
   Minimum iOS Version: 11.0
   Target Device: iPhone+iPad
   Architecture: ARM64
   ```

2. **XR Management Settings**
   - Enable ARKit (iOS)
   - Initialize on Startup: Yes

3. **Build Unity Project**
   ```bash
   # Export Unity project for iOS
   # File > Build Settings > Build
   ```

4. **Copy Unity Build to Flutter**
   ```bash
   # Copy Unity build outputs to Flutter project
   cp -r unity_build/* ios/UnityFramework/
   ```

## Step 4: Flutter Integration

1. **Update Flutter Dependencies**
   ```yaml
   dependencies:
     flutter_unity_widget: ^2022.2.1
   ```

2. **Update Android Gradle Files**
   ```gradle
   // android/settings.gradle
   include ':unityLibrary'
   project(':unityLibrary').projectDir = file('./unityLibrary')
   
   // android/app/build.gradle
   dependencies {
       implementation project(':unityLibrary')
   }
   ```

3. **Update iOS Podfile**
   ```ruby
   # ios/Podfile
   target 'Runner' do
     # ... existing pods
     pod 'UnityFramework', :path => 'UnityFramework'
   end
   ```

## Step 5: Testing

1. **Android Testing**
   ```bash
   flutter build apk --debug
   flutter install
   ```

2. **iOS Testing**
   ```bash
   flutter build ios --debug
   # Open in Xcode and run
   ```

## Step 6: Unity Communication Setup

1. **Unity Message Handling**
   - Unity sends JSON messages to Flutter
   - Flutter sends commands to Unity via method channels

2. **Message Format**
   ```json
   // Unity to Flutter
   {
     "method": "onPointPlaced",
     "data": "{\"id\":\"point_0\",\"position\":[0,0,0]}"
   }
   
   // Flutter to Unity
   {
     "command": "PlacePoint",
     "data": "{\"screenX\":100,\"screenY\":200}"
   }
   ```

## Step 7: Scene Configuration

1. **Create AR Scene in Unity**
   - Add AR Session
   - Add XR Origin (AR Camera)
   - Add AR Plane Manager
   - Add AR Raycast Manager
   - Add ARMeasurementManager script
   - Add UnityMessageManager script

2. **Configure Point Prefab**
   - Create sphere primitive
   - Scale to 0.02 units (2cm)
   - Apply red/green materials
   - Save as prefab

## Step 8: Build Configuration

1. **Unity Build Settings**
   ```
   Scenes in Build:
   - Assets/Scenes/ARMeasurementScene
   
   Platform: Android/iOS
   Texture Compression: ASTC
   Compression Method: LZ4HC
   ```

2. **Flutter Build Configuration**
   ```bash
   # Android
   flutter build apk --release
   
   # iOS
   flutter build ios --release
   ```

## Troubleshooting

### Common Issues

1. **Unity not loading in Flutter**
   - Check Unity build outputs are copied correctly
   - Verify flutter_unity_widget dependency
   - Check Android/iOS project configuration

2. **AR not working**
   - Verify device AR support
   - Check camera permissions
   - Ensure AR packages are installed in Unity

3. **Communication issues**
   - Check UnityMessageManager is attached to scene object
   - Verify JSON message format
   - Check Flutter method channel setup

### Debug Commands

```bash
# Check Flutter Unity Widget logs
flutter logs | grep Unity

# Check Unity console logs
adb logcat | grep Unity

# Test AR support
adb shell am start -a android.intent.action.VIEW -d "ar://test"
```

## Performance Optimization

1. **Unity Optimization**
   - Use object pooling for point markers
   - Limit concurrent raycast operations
   - Optimize AR plane detection frequency

2. **Flutter Optimization**
   - Minimize Unity widget rebuilds
   - Cache measurement calculations
   - Use efficient state management

## Deployment Checklist

- [ ] Unity project builds successfully
- [ ] AR functionality works on test devices
- [ ] Flutter-Unity communication working
- [ ] Measurement accuracy validated
- [ ] Error handling implemented
- [ ] Permissions configured correctly
- [ ] Performance optimized
- [ ] Fallback to manual guide works