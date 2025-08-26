/// Represents the different possible outcomes of an attendance check.
enum AttendanceStatus {
  /// Attendance was successfully verified via Bluetooth Low Energy (BLE) device detection.
  successBle,
  
  /// Attendance was successfully verified via location-based check.
  successLocation,
  
  /// Attendance check failed - no matching BLE devices found and not within any configured location radius.
  failedNoMatch,
  
  /// Attendance check failed due to insufficient permissions (Bluetooth, Location, etc.).
  failedPermissions,
}

/// Extension methods for [AttendanceStatus] to provide additional functionality.
extension AttendanceStatusExtension on AttendanceStatus {
  /// Returns a human-readable description of the attendance status.
  String get description {
    switch (this) {
      case AttendanceStatus.successBle:
        return 'Attendance verified via Bluetooth device';
      case AttendanceStatus.successLocation:
        return 'Attendance verified via location';
      case AttendanceStatus.failedNoMatch:
        return 'No matching devices or locations found';
      case AttendanceStatus.failedPermissions:
        return 'Insufficient permissions';
    }
  }

  /// Returns true if the attendance check was successful.
  bool get isSuccess {
    return this == AttendanceStatus.successBle || 
           this == AttendanceStatus.successLocation;
  }

  /// Returns true if the attendance check failed.
  bool get isFailure => !isSuccess;
}
