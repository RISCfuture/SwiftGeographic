import Foundation

/// A geographic coordinate expressed as latitude and longitude in degrees.
///
/// This is the fundamental geographic coordinate type. Use it as the starting
/// point for conversions to UTM, UPS, and MGRS coordinate systems.
///
/// ## Overview
///
/// Create a geographic coordinate from decimal degrees:
///
/// ```swift
/// let coordinate = try GeographicCoordinate(latitude: 40.7128, longitude: -74.0060)
/// ```
///
/// Convert to other coordinate systems:
///
/// ```swift
/// let utm = try coordinate.utm
/// let mgrs = try coordinate.mgrs()
/// ```
public struct GeographicCoordinate: Sendable, Equatable, Hashable, Codable, CustomStringConvertible
{

  public var description: String {
    let latDir = latitude >= 0 ? "N" : "S"
    let lonDir = longitude >= 0 ? "E" : "W"
    return String(
      format: "%.6f%@, %.6f%@",
      abs(latitude),
      latDir,
      abs(longitude),
      lonDir
    )
  }

  /// Latitude in degrees, from -90 (south pole) to +90 (north pole).
  public let latitude: Double

  /// Longitude in degrees, normalized to [-180, 180].
  public let longitude: Double

  /// The UTM coordinate equivalent of this geographic coordinate.
  ///
  /// Uses the standard UTM zone for the location, including the Norway
  /// and Svalbard exceptions. Coordinates in the polar regions
  /// (latitude >= 84 or < -80) will use UPS zone 0.
  ///
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public var utm: UTMCoordinate {
    get throws {
      let result = try UTMUPS.forward(
        latitude: latitude,
        longitude: longitude
      )
      if result.zone == 0 {
        // Polar region — still return a UTM-like coordinate via forced zone
        let zone = UTMUPS.standardZone(
          latitude: latitude >= 0 ? 83.99 : -79.99,
          longitude: longitude
        )
        let forced = try UTMUPS.forward(
          latitude: latitude,
          longitude: longitude,
          zone: zone
        )
        return try UTMCoordinate(
          zone: forced.zone,
          hemisphere: forced.hemisphere,
          easting: forced.easting,
          northing: forced.northing
        )
      }
      return try UTMCoordinate(
        zone: result.zone,
        hemisphere: result.hemisphere,
        easting: result.easting,
        northing: result.northing
      )
    }
  }

  /// The UPS coordinate equivalent of this geographic coordinate.
  ///
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public var ups: UPSCoordinate {
    get throws {
      let result = try UTMUPS.forward(
        latitude: latitude,
        longitude: longitude,
        zone: 0
      )
      return try UPSCoordinate(
        hemisphere: result.hemisphere,
        easting: result.easting,
        northing: result.northing
      )
    }
  }

  /// Creates a geographic coordinate from latitude and longitude in degrees.
  ///
  /// - Parameters:
  ///   - latitude: Latitude in degrees [-90, 90].
  ///   - longitude: Longitude in degrees [-180, 180].
  /// - Throws: ``SwiftGeographicError/invalidLatitude(_:)`` if the latitude
  ///   is outside [-90, 90], or
  ///   ``SwiftGeographicError/invalidLongitude(_:)`` if the longitude is
  ///   outside [-180, 180].
  public init(latitude: Double, longitude: Double) throws {
    guard latitude >= -90, latitude <= 90 else {
      throw SwiftGeographicError.invalidLatitude(latitude)
    }
    guard longitude >= -180, longitude <= 180 else {
      throw SwiftGeographicError.invalidLongitude(longitude)
    }
    self.latitude = latitude
    self.longitude = longitude
  }

  /// The MGRS coordinate equivalent of this geographic coordinate.
  ///
  /// - Parameter precision: The desired MGRS precision level (defaults to
  ///   ``MGRSPrecision/oneMeter``).
  /// - Returns: The ``MGRSCoordinate``.
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public func mgrs(
    precision: MGRSPrecision = .oneMeter
  ) throws -> MGRSCoordinate {
    let result = try UTMUPS.forward(
      latitude: latitude,
      longitude: longitude
    )
    return MGRSEngine.forward(
      zone: result.zone,
      hemisphere: result.hemisphere,
      easting: result.easting,
      northing: result.northing,
      latitude: latitude,
      precision: precision
    )
  }
}
