import 'location_point.dart';

/// Configuration class for attendance checking operations.
class AttendanceConfig {
  /// List of Bluetooth Low Energy (BLE) device names to scan for.
  /// These are the device names that will be considered valid for attendance.
  final List<String> bleDeviceNames;
  
  /// List of geographical locations where attendance is valid.
  final List<LocationPoint> locations;
  
  /// The radius in meters around each location point where attendance is considered valid.
  /// Default is 100 meters.
  final int radiusMeters;
  
  /// Maximum duration to scan for BLE devices before falling back to location check.
  /// Default is 20 seconds.
  final Duration bleScanTimeout;
  
  /// Whether to use exact matching for BLE device names.
  /// If true (default), device names must match exactly.
  /// If false, device names can be partial matches (contains).
  final bool exactBleMatch;
  
  /// Whether to enable detailed logging for debugging purposes.
  /// Default is false.
  final bool enableLogging;

  /// Creates a new [AttendanceConfig] with the specified parameters.
  AttendanceConfig({
    required this.bleDeviceNames,
    required this.locations,
    this.radiusMeters = 100,
    this.bleScanTimeout = const Duration(seconds: 20),
    this.exactBleMatch = true,
    this.enableLogging = false,
  }) : assert(bleDeviceNames.isNotEmpty || locations.isNotEmpty, 
              'At least one BLE device name or location must be provided'),
       assert(radiusMeters > 0, 'Radius must be greater than 0'),
       assert(bleScanTimeout.inSeconds > 0, 'BLE scan timeout must be greater than 0');

  /// Creates an [AttendanceConfig] from a JSON map.
  factory AttendanceConfig.fromJson(Map<String, dynamic> json) {
    return AttendanceConfig(
      bleDeviceNames: List<String>.from(json['bleDeviceNames'] ?? []),
      locations: (json['locations'] as List<dynamic>?)
          ?.map((e) => LocationPoint.fromJson(e as Map<String, dynamic>))
          .toList() ?? [],
      radiusMeters: json['radiusMeters'] as int? ?? 100,
      bleScanTimeout: Duration(seconds: json['bleScanTimeoutSeconds'] as int? ?? 20),
      exactBleMatch: json['exactBleMatch'] as bool? ?? true,
      enableLogging: json['enableLogging'] as bool? ?? false,
    );
  }

  /// Converts this [AttendanceConfig] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'bleDeviceNames': bleDeviceNames,
      'locations': locations.map((e) => e.toJson()).toList(),
      'radiusMeters': radiusMeters,
      'bleScanTimeoutSeconds': bleScanTimeout.inSeconds,
      'exactBleMatch': exactBleMatch,
      'enableLogging': enableLogging,
    };
  }

  /// Creates a copy of this [AttendanceConfig] with the specified fields replaced.
  AttendanceConfig copyWith({
    List<String>? bleDeviceNames,
    List<LocationPoint>? locations,
    int? radiusMeters,
    Duration? bleScanTimeout,
    bool? exactBleMatch,
    bool? enableLogging,
  }) {
    return AttendanceConfig(
      bleDeviceNames: bleDeviceNames ?? this.bleDeviceNames,
      locations: locations ?? this.locations,
      radiusMeters: radiusMeters ?? this.radiusMeters,
      bleScanTimeout: bleScanTimeout ?? this.bleScanTimeout,
      exactBleMatch: exactBleMatch ?? this.exactBleMatch,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AttendanceConfig &&
        _listEquals(other.bleDeviceNames, bleDeviceNames) &&
        _listEquals(other.locations, locations) &&
        other.radiusMeters == radiusMeters &&
        other.bleScanTimeout == bleScanTimeout &&
        other.exactBleMatch == exactBleMatch &&
        other.enableLogging == enableLogging;
  }

  @override
  int get hashCode {
    return bleDeviceNames.hashCode ^
        locations.hashCode ^
        radiusMeters.hashCode ^
        bleScanTimeout.hashCode ^
        exactBleMatch.hashCode ^
        enableLogging.hashCode;
  }

  @override
  String toString() {
    return 'AttendanceConfig('
        'bleDeviceNames: $bleDeviceNames, '
        'locations: $locations, '
        'radiusMeters: $radiusMeters, '
        'bleScanTimeout: $bleScanTimeout, '
        'exactBleMatch: $exactBleMatch, '
        'enableLogging: $enableLogging)';
  }

  /// Helper method to compare lists for equality.
  bool _listEquals<T>(List<T>? a, List<T>? b) {
    if (a == null && b == null) return true;
    if (a == null || b == null) return false;
    if (a.length != b.length) return false;
    for (int i = 0; i < a.length; i++) {
      if (a[i] != b[i]) return false;
    }
    return true;
  }
}
