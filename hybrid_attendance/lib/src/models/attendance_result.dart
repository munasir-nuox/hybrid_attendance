import 'attendance_status.dart';

/// Represents the result of an attendance check operation.
class AttendanceResult {
  /// The status of the attendance check.
  final AttendanceStatus status;
  
  /// Optional message providing additional details about the result.
  final String? message;
  
  /// Optional data containing additional information about the result.
  /// For BLE success: may contain device name that was found.
  /// For location success: may contain location details.
  /// For failures: may contain error details.
  final Map<String, dynamic>? data;

  /// Creates a new [AttendanceResult] with the specified [status] and optional [message] and [data].
  const AttendanceResult(
    this.status, {
    this.message,
    this.data,
  });

  /// Creates a successful BLE attendance result.
  factory AttendanceResult.successBle({
    String? deviceName,
    String? message,
  }) {
    return AttendanceResult(
      AttendanceStatus.successBle,
      message: message ?? 'Attendance verified via Bluetooth device${deviceName != null ? ': $deviceName' : ''}',
      data: deviceName != null ? {'deviceName': deviceName} : null,
    );
  }

  /// Creates a successful location attendance result.
  factory AttendanceResult.successLocation({
    double? latitude,
    double? longitude,
    double? distance,
    String? message,
  }) {
    return AttendanceResult(
      AttendanceStatus.successLocation,
      message: message ?? 'Attendance verified via location${distance != null ? ' (${distance.toStringAsFixed(1)}m away)' : ''}',
      data: {
        if (latitude != null) 'latitude': latitude,
        if (longitude != null) 'longitude': longitude,
        if (distance != null) 'distance': distance,
      },
    );
  }

  /// Creates a failed attendance result due to no matches.
  factory AttendanceResult.failedNoMatch({String? message}) {
    return AttendanceResult(
      AttendanceStatus.failedNoMatch,
      message: message ?? 'No matching Bluetooth devices found and not within any configured location',
    );
  }

  /// Creates a failed attendance result due to permissions.
  factory AttendanceResult.failedPermissions({String? message}) {
    return AttendanceResult(
      AttendanceStatus.failedPermissions,
      message: message ?? 'Required permissions not granted. Please enable Bluetooth and Location permissions.',
    );
  }

  /// Returns true if the attendance check was successful.
  bool get isSuccess => status.isSuccess;

  /// Returns true if the attendance check failed.
  bool get isFailure => status.isFailure;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceResult &&
        other.status == status &&
        other.message == message &&
        _mapEquals(other.data, data);
  }

  @override
  int get hashCode => status.hashCode ^ message.hashCode ^ data.hashCode;

  @override
  String toString() => 'AttendanceResult(status: $status, message: $message, data: $data)';

  /// Helper method to compare maps for equality.
  bool _mapEquals(Map<String, dynamic>? a, Map<String, dynamic>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (!b.containsKey(key) || a[key] != b[key]) return false;
    }
    return true;
  }
}
