import 'package:flutter_test/flutter_test.dart';
import 'package:hybrid_attendance/hybrid_attendance.dart';
import 'package:hybrid_attendance/hybrid_attendance_platform_interface.dart';
import 'package:hybrid_attendance/hybrid_attendance_method_channel.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockHybridAttendancePlatform
    with MockPlatformInterfaceMixin
    implements HybridAttendancePlatform {
  @override
  Future<String?> getPlatformVersion() => Future.value('42');

  @override
  Future<AttendanceResult> checkAttendance(AttendanceConfig config) =>
      Future.value(AttendanceResult.successBle(deviceName: 'Test Device'));

  @override
  Future<Map<String, dynamic>> requestPermissions() =>
      Future.value({'granted': true, 'message': 'All permissions granted'});
}

void main() {
  final HybridAttendancePlatform initialPlatform =
      HybridAttendancePlatform.instance;

  test('$MethodChannelHybridAttendance is the default instance', () {
    expect(initialPlatform, isInstanceOf<MethodChannelHybridAttendance>());
  });

  test('getPlatformVersion', () async {
    MockHybridAttendancePlatform fakePlatform = MockHybridAttendancePlatform();
    HybridAttendancePlatform.instance = fakePlatform;

    expect(await HybridAttendance.getPlatformVersion(), '42');
  });

  test('checkAttendance returns success', () async {
    MockHybridAttendancePlatform fakePlatform = MockHybridAttendancePlatform();
    HybridAttendancePlatform.instance = fakePlatform;

    final config = AttendanceConfig(
      bleDeviceNames: ['Test Device'],
      locations: [const LocationPoint(37.7749, -122.4194)],
    );

    final result = await HybridAttendance.checkAttendance(config: config);

    expect(result.isSuccess, true);
    expect(result.status, AttendanceStatus.successBle);
  });

  group('AttendanceConfig', () {
    test('creates with required parameters', () {
      final config = AttendanceConfig(
        bleDeviceNames: ['Device1', 'Device2'],
        locations: [const LocationPoint(1.0, 2.0)],
      );

      expect(config.bleDeviceNames, ['Device1', 'Device2']);
      expect(config.locations.length, 1);
      expect(config.radiusMeters, 100); // default
      expect(config.bleScanTimeout, const Duration(seconds: 20)); // default
      expect(config.exactBleMatch, true); // default
      expect(config.enableLogging, false); // default
    });

    test('creates with custom parameters', () {
      final config = AttendanceConfig(
        bleDeviceNames: ['Device1'],
        locations: [const LocationPoint(1.0, 2.0)],
        radiusMeters: 50,
        bleScanTimeout: const Duration(seconds: 10),
        exactBleMatch: false,
        enableLogging: true,
      );

      expect(config.radiusMeters, 50);
      expect(config.bleScanTimeout, const Duration(seconds: 10));
      expect(config.exactBleMatch, false);
      expect(config.enableLogging, true);
    });

    test('toJson and fromJson work correctly', () {
      final config = AttendanceConfig(
        bleDeviceNames: ['Device1', 'Device2'],
        locations: [
          const LocationPoint(37.7749, -122.4194),
          const LocationPoint(40.7128, -74.0060),
        ],
        radiusMeters: 150,
        bleScanTimeout: const Duration(seconds: 30),
        exactBleMatch: false,
        enableLogging: true,
      );

      final json = config.toJson();
      final restored = AttendanceConfig.fromJson(json);

      expect(restored.bleDeviceNames, config.bleDeviceNames);
      expect(restored.locations.length, config.locations.length);
      expect(restored.radiusMeters, config.radiusMeters);
      expect(restored.bleScanTimeout, config.bleScanTimeout);
      expect(restored.exactBleMatch, config.exactBleMatch);
      expect(restored.enableLogging, config.enableLogging);
    });
  });

  group('LocationPoint', () {
    test('creates correctly', () {
      const point = LocationPoint(37.7749, -122.4194);
      expect(point.latitude, 37.7749);
      expect(point.longitude, -122.4194);
    });

    test('toJson and fromJson work correctly', () {
      const point = LocationPoint(37.7749, -122.4194);
      final json = point.toJson();
      final restored = LocationPoint.fromJson(json);

      expect(restored.latitude, point.latitude);
      expect(restored.longitude, point.longitude);
    });

    test('equality works correctly', () {
      const point1 = LocationPoint(37.7749, -122.4194);
      const point2 = LocationPoint(37.7749, -122.4194);
      const point3 = LocationPoint(40.7128, -74.0060);

      expect(point1, point2);
      expect(point1, isNot(point3));
    });
  });

  group('AttendanceResult', () {
    test('factory constructors work correctly', () {
      final bleResult = AttendanceResult.successBle(deviceName: 'Test Device');
      expect(bleResult.status, AttendanceStatus.successBle);
      expect(bleResult.isSuccess, true);
      expect(bleResult.data?['deviceName'], 'Test Device');

      final locationResult = AttendanceResult.successLocation(
        latitude: 37.7749,
        longitude: -122.4194,
        distance: 50.0,
      );
      expect(locationResult.status, AttendanceStatus.successLocation);
      expect(locationResult.isSuccess, true);
      expect(locationResult.data?['latitude'], 37.7749);

      final failureResult = AttendanceResult.failedNoMatch();
      expect(failureResult.status, AttendanceStatus.failedNoMatch);
      expect(failureResult.isFailure, true);

      final permissionResult = AttendanceResult.failedPermissions();
      expect(permissionResult.status, AttendanceStatus.failedPermissions);
      expect(permissionResult.isFailure, true);
    });
  });

  group('AttendanceStatus', () {
    test('extension methods work correctly', () {
      expect(AttendanceStatus.successBle.isSuccess, true);
      expect(AttendanceStatus.successLocation.isSuccess, true);
      expect(AttendanceStatus.failedNoMatch.isFailure, true);
      expect(AttendanceStatus.failedPermissions.isFailure, true);

      expect(AttendanceStatus.successBle.description, contains('Bluetooth'));
      expect(
        AttendanceStatus.successLocation.description,
        contains('location'),
      );
    });
  });
}
