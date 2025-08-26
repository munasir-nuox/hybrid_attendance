import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'hybrid_attendance_method_channel.dart';
import 'src/models/attendance_config.dart';
import 'src/models/attendance_result.dart';

abstract class HybridAttendancePlatform extends PlatformInterface {
  /// Constructs a HybridAttendancePlatform.
  HybridAttendancePlatform() : super(token: _token);

  static final Object _token = Object();

  static HybridAttendancePlatform _instance = MethodChannelHybridAttendance();

  /// The default instance of [HybridAttendancePlatform] to use.
  ///
  /// Defaults to [MethodChannelHybridAttendance].
  static HybridAttendancePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [HybridAttendancePlatform] when
  /// they register themselves.
  static set instance(HybridAttendancePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }

  /// Performs attendance check using the provided configuration.
  ///
  /// Returns an [AttendanceResult] indicating the outcome of the check.
  /// The method will first scan for BLE devices, and if none are found,
  /// it will fall back to location-based verification.
  Future<AttendanceResult> checkAttendance(AttendanceConfig config) {
    throw UnimplementedError('checkAttendance() has not been implemented.');
  }
}
