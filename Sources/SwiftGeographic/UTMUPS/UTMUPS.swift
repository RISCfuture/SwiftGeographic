import Foundation

/// Unified UTM/UPS coordinate operations.
///
/// Provides zone determination (including Norway and Svalbard exceptions)
/// and conversion between geographic coordinates and the combined UTM/UPS
/// system. UTM covers zones 1–60 (latitudes 80S to 84N) while UPS
/// (zone 0) covers the polar regions.
public enum UTMUPS {

  /// Determines the standard UTM zone for a geographic coordinate.
  ///
  /// Returns zones 1–60 for UTM or 0 for UPS (polar regions). Implements
  /// the Norway (zone 32V) and Svalbard (31X/33X/35X/37X) exceptions.
  ///
  /// - Parameters:
  ///   - latitude: Latitude in degrees.
  ///   - longitude: Longitude in degrees.
  /// - Returns: The zone number (1–60 for UTM, 0 for UPS).
  public static func standardZone(
    latitude: Double,
    longitude: Double
  ) -> Int {
    if latitude >= 84 || latitude <= -80 {
      return 0  // UPS
    }

    var lon = MathUtilities.angNormalize(longitude)
    if lon == 180 { lon = -180 }
    let ilon = Int(floor(lon))

    // Standard 6-degree zone
    var zone = (ilon + 186) / 6

    // Norway exception: band V (56–64N), zones 31/32
    if latitude >= 56 && latitude < 64 && zone == 31 && lon >= 3 {
      zone = 32
    }

    // Svalbard exception: band X (72–84N)
    if latitude >= 72 && latitude < 84 {
      if lon >= 0 && lon < 9 {
        zone = 31
      } else if lon >= 9 && lon < 21 {
        zone = 33
      } else if lon >= 21 && lon < 33 {
        zone = 35
      } else if lon >= 33 && lon < 42 {
        zone = 37
      }
    }

    return zone
  }

  /// The central meridian longitude for a UTM zone.
  ///
  /// - Parameter zone: The UTM zone number (1–60).
  /// - Returns: The central meridian in degrees.
  public static func centralMeridian(zone: Int) -> Double {
    6.0 * Double(zone) - 183.0
  }

  /// Converts a geographic coordinate to UTM or UPS coordinates.
  ///
  /// - Parameters:
  ///   - latitude: Latitude in degrees [-90, 90].
  ///   - longitude: Longitude in degrees.
  ///   - zone: Force a specific zone (nil for automatic zone selection).
  /// - Returns: A tuple with the zone, hemisphere, easting, and northing.
  /// - Throws: ``SwiftGeographicError`` if the coordinate is invalid.
  public static func forward(
    latitude: Double,
    longitude: Double,
    zone: Int? = nil
  ) throws -> (zone: Int, hemisphere: Hemisphere, easting: Double, northing: Double) {
    guard latitude >= -90, latitude <= 90 else {
      throw SwiftGeographicError.invalidLatitude(latitude)
    }

    let z = zone ?? standardZone(latitude: latitude, longitude: longitude)
    let hemisphere: Hemisphere = latitude >= 0 ? .north : .south

    if z == 0 {
      // UPS
      let isNorth = latitude >= 0
      let result = PolarStereographic.ups.forward(
        isNorth: isNorth,
        latitude: latitude,
        longitude: longitude
      )
      let easting = result.x + Constants.upsFalseEastingNorthing
      let northing = result.y + Constants.upsFalseEastingNorthing
      return (0, hemisphere, easting, northing)
    }

    // UTM
    let lon0 = centralMeridian(zone: z)
    let result = TransverseMercator.utm.forward(
      centralMeridian: lon0,
      latitude: latitude,
      longitude: longitude
    )
    let easting = result.x + Constants.utmFalseEasting
    var northing = result.y
    if hemisphere == .south {
      northing += Constants.utmFalseNorthingSouth
    }
    return (z, hemisphere, easting, northing)
  }

  /// Converts UTM or UPS coordinates back to a geographic coordinate.
  ///
  /// - Parameters:
  ///   - zone: The zone number (1–60 for UTM, 0 for UPS).
  ///   - hemisphere: The hemisphere.
  ///   - easting: The easting in meters (including false easting).
  ///   - northing: The northing in meters (including false northing).
  /// - Returns: The geographic coordinate.
  /// - Throws: ``SwiftGeographicError`` if the coordinates are invalid.
  public static func reverse(
    zone: Int,
    hemisphere: Hemisphere,
    easting: Double,
    northing: Double
  ) throws -> (latitude: Double, longitude: Double) {
    if zone == 0 {
      // UPS
      let isNorth = hemisphere == .north
      let x = easting - Constants.upsFalseEastingNorthing
      let y = northing - Constants.upsFalseEastingNorthing
      let result = PolarStereographic.ups.reverse(
        isNorth: isNorth,
        easting: x,
        northing: y
      )
      return (result.x, result.y)
    }

    // UTM
    guard zone >= 1, zone <= 60 else {
      throw SwiftGeographicError.invalidZone(zone)
    }
    let lon0 = centralMeridian(zone: zone)
    let x = easting - Constants.utmFalseEasting
    var y = northing
    if hemisphere == .south {
      y -= Constants.utmFalseNorthingSouth
    }
    let result = TransverseMercator.utm.reverse(
      centralMeridian: lon0,
      easting: x,
      northing: y
    )
    return (result.x, result.y)
  }
}
