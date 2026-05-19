/// WGS84 ellipsoid and projection constants.
enum Constants {

  /// WGS84 equatorial radius in meters.
  static let wgs84A: Double = 6_378_137.0

  /// WGS84 flattening.
  static let wgs84F: Double = 1.0 / 298.257_223_563

  /// UTM central scale factor.
  static let utmK0: Double = 0.9996

  /// UPS central scale factor.
  static let upsK0: Double = 0.994

  /// UTM false easting in meters.
  static let utmFalseEasting: Double = 500_000.0

  /// UTM false northing for the southern hemisphere in meters.
  static let utmFalseNorthingSouth: Double = 10_000_000.0

  /// UPS false easting and northing in meters.
  static let upsFalseEastingNorthing: Double = 2_000_000.0

  /// 100 km tile size used in MGRS.
  static let tile: Double = 100_000.0
}
