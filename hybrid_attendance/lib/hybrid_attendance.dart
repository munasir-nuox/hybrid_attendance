import 'hybrid_attendance_platform_interface.dart';
import 'src/models/attendance_config.dart';
import 'src/models/attendance_result.dart';

// Export public API
export 'src/models/attendance_config.dart';
export 'src/models/attendance_result.dart';
export 'src/models/attendance_status.dart';
export 'src/models/location_point.dart';

/// Main class for the Hybrid Attendance plugin.
///
/// This plugin provides functionality to check attendance using a hybrid approach:
/// 1. First, it scans for Bluetooth Low Energy (BLE) devices
/// 2. If no matching BLE devices are found, it falls back to location-based verification
///
/// Example usage:
/// ```dart
/// final config = AttendanceConfig(
///   bleDeviceNames: ['Office-Beacon-1', 'Office-Beacon-2'],
///   locations: [LocationPoint(37.7749, -122.4194)],
///   radiusMeters: 100,
///   bleScanTimeout: Duration(seconds: 20),
/// );
///
/// final result = await HybridAttendance.checkAttendance(config: config);
/// if (result.isSuccess) {
///   print('Attendance verified: ${result.message}');
/// } else {
///   print('Attendance failed: ${result.message}');
/// }
/// ```
class HybridAttendance {
  /// Private constructor to prevent instantiation.
  HybridAttendance._();

  /// Gets the platform version (for debugging purposes).
  static Future<String?> getPlatformVersion() {
    return HybridAttendancePlatform.instance.getPlatformVersion();
  }

  /// Performs attendance check using the provided configuration.
  ///
  /// This method implements the hybrid attendance checking logic:
  /// 1. Scans for BLE devices for up to [AttendanceConfig.bleScanTimeout] duration
  /// 2. If any configured device name is found, returns success immediately
  /// 3. If no BLE device found within timeout, checks current location
  /// 4. If within the radius of any configured location, returns success
  /// 5. Otherwise, returns failure
  ///
  /// Returns an [AttendanceResult] indicating the outcome of the check.
  ///
  /// Throws [ArgumentError] if the config is invalid.
  static Future<AttendanceResult> checkAttendance({
    required AttendanceConfig config,
  }) {
    return HybridAttendancePlatform.instance.checkAttendance(config);
  }
}
