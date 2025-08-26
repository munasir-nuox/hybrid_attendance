# Hybrid Attendance

A Flutter plugin for hybrid attendance system using Bluetooth Low Energy (BLE) and Location services.

## Features

- **Hybrid Approach**: First attempts BLE device detection, then falls back to location-based verification
- **Configurable**: Supports multiple BLE device names and location points
- **Flexible Matching**: Exact or partial BLE device name matching
- **Battery Friendly**: Foreground-only operation with configurable timeouts
- **Cross Platform**: Supports both Android and iOS
- **Permission Handling**: Automatic permission management with user-friendly error messages
- **Detailed Logging**: Optional logging for debugging purposes

## Platform Support

| Platform | BLE Scanning | Location Services | Min Version |
|----------|--------------|-------------------|-------------|
| Android  | ✅           | ✅                | API 21 (5.0) |
| iOS      | ✅           | ✅                | iOS 13.0    |

## Installation

Add this to your package's `pubspec.yaml` file:

```yaml
dependencies:
  hybrid_attendance: ^0.0.1
```

## Permissions

### Android

The plugin automatically handles the following permissions:

- `BLUETOOTH` and `BLUETOOTH_ADMIN` (for older Android versions)
- `BLUETOOTH_SCAN` and `BLUETOOTH_CONNECT` (for Android 12+)
- `ACCESS_FINE_LOCATION` and `ACCESS_COARSE_LOCATION`

### iOS

Add the following to your `ios/Runner/Info.plist`:

```xml
<key>NSBluetoothAlwaysUsageDescription</key>
<string>This app uses Bluetooth to detect nearby attendance beacons.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>This app uses location services to verify attendance.</string>
```

## Usage

### Basic Example

```dart
import 'package:hybrid_attendance/hybrid_attendance.dart';

// Configure attendance parameters
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

// Check attendance
final result = await HybridAttendance.checkAttendance(config: config);

if (result.isSuccess) {
  print('Attendance verified: ${result.message}');
  if (result.status == AttendanceStatus.successBle) {
    print('Found device: ${result.data?['deviceName']}');
  } else if (result.status == AttendanceStatus.successLocation) {
    print('Distance: ${result.data?['distance']}m');
  }
} else {
  print('Attendance failed: ${result.message}');
}
```

### Advanced Configuration

```dart
final config = AttendanceConfig(
  bleDeviceNames: ['Beacon-*', 'Office-*'], // Partial matching
  locations: [
    LocationPoint(37.7749, -122.4194),
  ],
  radiusMeters: 50,                    // Smaller radius
  bleScanTimeout: Duration(seconds: 10), // Faster timeout
  exactBleMatch: false,                // Enable partial matching
  enableLogging: true,                 // Enable debug logging
);
```

## API Reference

### AttendanceConfig

Configuration class for attendance checking operations.

| Property | Type | Default | Description |
|----------|------|---------|-------------|
| `bleDeviceNames` | `List<String>` | required | BLE device names to scan for |
| `locations` | `List<LocationPoint>` | required | Valid attendance locations |
| `radiusMeters` | `int` | 100 | Radius around locations (meters) |
| `bleScanTimeout` | `Duration` | 20 seconds | BLE scan timeout |
| `exactBleMatch` | `bool` | true | Exact vs partial name matching |
| `enableLogging` | `bool` | false | Enable debug logging |

### LocationPoint

Represents a geographical location.

```dart
const LocationPoint(double latitude, double longitude)
```

### AttendanceResult

Result of an attendance check operation.

| Property | Type | Description |
|----------|------|-------------|
| `status` | `AttendanceStatus` | Result status |
| `message` | `String?` | Human-readable message |
| `data` | `Map<String, dynamic>?` | Additional result data |
| `isSuccess` | `bool` | Whether check was successful |
| `isFailure` | `bool` | Whether check failed |

### AttendanceStatus

Possible attendance check outcomes:

- `AttendanceStatus.successBle` - Success via BLE device
- `AttendanceStatus.successLocation` - Success via location
- `AttendanceStatus.failedNoMatch` - No devices/locations matched
- `AttendanceStatus.failedPermissions` - Insufficient permissions

## How It Works

1. **BLE Scanning Phase**: The plugin scans for Bluetooth Low Energy devices for the specified timeout duration
2. **Device Matching**: Found devices are matched against the configured device names (exact or partial)
3. **Early Success**: If a matching device is found, the scan stops immediately and returns success
4. **Location Fallback**: If no BLE devices are found, the plugin gets the current location
5. **Proximity Check**: Current location is compared against all configured locations using the specified radius
6. **Result**: Returns success if within any location's radius, otherwise returns failure

## Troubleshooting

### Permission Issues

**Android:**
- Ensure location services are enabled in device settings
- For Android 12+, make sure "Nearby devices" permission is granted
- Check that the app has location permission in app settings

**iOS:**
- Verify Bluetooth is enabled in device settings
- Check location permission in Settings > Privacy & Security > Location Services
- Ensure the app has "While Using App" location permission

### BLE Scanning Issues

- **No devices found**: Ensure BLE devices are advertising and within range
- **Partial matching not working**: Set `exactBleMatch: false` in configuration
- **Scan timeout too short**: Increase `bleScanTimeout` duration
- **Battery optimization**: Some Android devices may limit BLE scanning when battery optimization is enabled

### Location Issues

- **Inaccurate location**: GPS may take time to get accurate fix, especially indoors
- **Location not updating**: Try increasing the radius or moving to an area with better GPS signal
- **Permission denied**: Check location permissions and ensure location services are enabled

## Example App

The plugin includes a comprehensive example app that demonstrates:

- Configuration of BLE device names and locations
- Real-time attendance checking
- Result display with detailed information
- Settings adjustment (radius, timeout, matching mode)
- Permission status monitoring

To run the example:

```bash
cd example
flutter run
```

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## License

This project is licensed under the MIT License - see the LICENSE file for details.

