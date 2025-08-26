import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'hybrid_attendance_platform_interface.dart';
import 'src/models/attendance_config.dart';
import 'src/models/attendance_result.dart';
import 'src/models/attendance_status.dart';

/// An implementation of [HybridAttendancePlatform] that uses method channels.
class MethodChannelHybridAttendance extends HybridAttendancePlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('hybrid_attendance');

  @override
  Future<String?> getPlatformVersion() async {
    final version = await methodChannel.invokeMethod<String>(
      'getPlatformVersion',
    );
    return version;
  }

  @override
  Future<AttendanceResult> checkAttendance(AttendanceConfig config) async {
    try {
      final result = await methodChannel.invokeMethod<Map<String, dynamic>>(
        'checkAttendance',
        config.toJson(),
      );

      if (result == null) {
        return AttendanceResult.failedNoMatch(
          message: 'No response from platform',
        );
      }

      final statusString = result['status'] as String?;
      final message = result['message'] as String?;
      final data = result['data'] as Map<String, dynamic>?;

      final status = _parseAttendanceStatus(statusString);

      return AttendanceResult(status, message: message, data: data);
    } on PlatformException catch (e) {
      if (e.code == 'PERMISSION_DENIED') {
        return AttendanceResult.failedPermissions(message: e.message);
      }
      return AttendanceResult.failedNoMatch(
        message: 'Platform error: ${e.message}',
      );
    } catch (e) {
      return AttendanceResult.failedNoMatch(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<Map<String, dynamic>> requestPermissions() async {
    try {
      final result = await methodChannel.invokeMethod<Map<String, dynamic>>(
        'requestPermissions',
      );

      return result ??
          {'granted': false, 'message': 'No response from platform'};
    } on PlatformException catch (e) {
      return {'granted': false, 'message': 'Platform error: ${e.message}'};
    } catch (e) {
      return {'granted': false, 'message': 'Unexpected error: $e'};
    }
  }

  /// Parses a string representation of attendance status to [AttendanceStatus] enum.
  AttendanceStatus _parseAttendanceStatus(String? statusString) {
    switch (statusString) {
      case 'successBle':
        return AttendanceStatus.successBle;
      case 'successLocation':
        return AttendanceStatus.successLocation;
      case 'failedPermissions':
        return AttendanceStatus.failedPermissions;
      case 'failedNoMatch':
      default:
        return AttendanceStatus.failedNoMatch;
    }
  }
}
