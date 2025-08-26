/// Represents a geographical location point with latitude and longitude coordinates.
class LocationPoint {
  /// The latitude coordinate in degrees.
  final double latitude;
  
  /// The longitude coordinate in degrees.
  final double longitude;

  /// Creates a new [LocationPoint] with the specified [latitude] and [longitude].
  const LocationPoint(this.latitude, this.longitude);

  /// Creates a [LocationPoint] from a JSON map.
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      json['latitude'] as double,
      json['longitude'] as double,
    );
  }

  /// Converts this [LocationPoint] to a JSON map.
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
    };
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is LocationPoint &&
        other.latitude == latitude &&
        other.longitude == longitude;
  }

  @override
  int get hashCode => latitude.hashCode ^ longitude.hashCode;

  @override
  String toString() => 'LocationPoint(latitude: $latitude, longitude: $longitude)';
}
