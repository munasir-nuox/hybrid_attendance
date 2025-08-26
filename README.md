# Hybrid Attendance Marker

A comprehensive Flutter plugin for hybrid attendance system using Bluetooth Low Energy (BLE) and Location services.

## 🎯 Overview

This project provides a Flutter plugin that implements a hybrid approach to attendance marking:

1. **Primary Method**: Scans for Bluetooth Low Energy (BLE) devices (beacons, phones, etc.)
2. **Fallback Method**: Uses GPS location verification when BLE devices are not found
3. **Smart Logic**: Stops BLE scanning immediately when a match is found to save battery
4. **Cross-Platform**: Works on both Android and iOS with proper permission handling

## 📁 Project Structure

```
hybrid-attendance-marker/
├── hybrid_attendance/          # Main Flutter plugin
│   ├── lib/                   # Dart API implementation
│   ├── android/               # Android native implementation (Kotlin)
│   ├── ios/                   # iOS native implementation (Swift)
│   ├── example/               # Comprehensive example app
│   └── test/                  # Unit tests
└── README.md                  # This file
```

## ✨ Features

- **Hybrid Detection**: BLE-first with location fallback
- **Configurable**: Multiple BLE devices and locations supported
- **Flexible Matching**: Exact or partial BLE device name matching
- **Battery Optimized**: Immediate stop on BLE match, configurable timeouts
- **Permission Management**: Automatic handling with user-friendly messages
- **Comprehensive Logging**: Optional detailed logging for debugging
- **Rich API**: Detailed result information with success/failure reasons

## 🚀 Quick Start

### 1. Plugin Development

```bash
cd hybrid_attendance
flutter pub get
flutter test                    # Run unit tests
flutter analyze                 # Check code quality
```

### 2. Example App

```bash
cd hybrid_attendance/example
flutter pub get
flutter run                     # Run on connected device
```

### 3. Platform Builds

```bash
# Android
flutter build apk --debug

# iOS  
flutter build ios --debug --no-codesign
```

## 📱 Platform Support

| Platform | BLE Scanning | Location Services | Min Version |
|----------|--------------|-------------------|-------------|
| Android  | ✅           | ✅                | API 21 (5.0) |
| iOS      | ✅           | ✅                | iOS 13.0    |

## 🔧 Configuration Example

```dart
final config = AttendanceConfig(
  bleDeviceNames: ['Office-Beacon-1', 'Office-Beacon-2'],
  locations: [
    LocationPoint(37.7749, -122.4194), // San Francisco
    LocationPoint(40.7128, -74.0060),  // New York
  ],
  radiusMeters: 100,
  bleScanTimeout: Duration(seconds: 20),
  exactBleMatch: true,
  enableLogging: false,
);

final result = await HybridAttendance.checkAttendance(config: config);
```

## 📋 Implementation Details

### Android Implementation
- **Language**: Kotlin
- **BLE**: Android Bluetooth APIs with proper permission handling
- **Location**: Google Play Services Location API with FusedLocationProviderClient
- **Permissions**: Runtime permission requests for Android 6.0+
- **Architecture**: Clean separation with PermissionManager, BluetoothScanner, LocationChecker

### iOS Implementation  
- **Language**: Swift
- **BLE**: Core Bluetooth framework with CBCentralManager
- **Location**: Core Location framework with CLLocationManager
- **Permissions**: Proper Info.plist entries and runtime permission requests
- **Architecture**: Modular design with dedicated manager classes

## 🧪 Testing

The plugin includes comprehensive unit tests covering:

- ✅ Configuration validation
- ✅ Data model serialization/deserialization  
- ✅ Result handling and status checking
- ✅ Platform interface mocking
- ✅ Edge cases and error conditions

Run tests with:
```bash
cd hybrid_attendance
flutter test
```

## 📖 Documentation

- **Plugin README**: `hybrid_attendance/README.md` - Detailed API documentation
- **Example App**: `hybrid_attendance/example/` - Interactive demo with full UI
- **API Reference**: Comprehensive inline documentation in Dart code
- **Platform Guides**: Implementation details for Android and iOS

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Make your changes
4. Add tests for new functionality
5. Ensure all tests pass
6. Submit a pull request

## 📄 License

This project is licensed under the MIT License - see the LICENSE file for details.

## 🙏 Acknowledgments

- Flutter team for the excellent plugin architecture
- Android and iOS teams for robust BLE and location APIs
- Community contributors and testers

---

**Built with ❤️ for the Flutter community**
