import Foundation

/// WGS84 ellipsoid and projection constants.
enum Constants {

  /// WGS84 equatorial radius in meters.
  static let wgs84A: Double = 6_378_137.0

  /// WGS84 flattening.
  static let wgs84F: Double = 1.0 / 298.257_223_563

  /// WGS84 first eccentricity squared: f*(2-f).
  static let wgs84E2: Double = wgs84F * (2 - wgs84F)

  /// WGS84 signed first eccentricity: sqrt(e2).
  static let wgs84Es: Double = sqrt(wgs84E2)

  /// WGS84 complement of eccentricity squared: 1-e2.
  static let wgs84E2m: Double = 1 - wgs84E2

  /// WGS84 third flattening: f/(2-f).
  static let wgs84N: Double = wgs84F / (2 - wgs84F)

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
