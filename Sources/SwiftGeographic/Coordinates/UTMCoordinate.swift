import Foundation

/// A Universal Transverse Mercator (UTM) coordinate.
///
/// UTM divides the Earth into 60 zones, each 6 degrees of longitude wide,
/// covering latitudes from 80S to 84N. Each zone is projected using the
/// Transverse Mercator projection with a scale factor of 0.9996 on the
/// central meridian.
///
/// ## Overview
///
/// ```swift
/// let utm = try UTMCoordinate(
///   zone: 18,
///   hemisphere: .north,
///   easting: 583960,
///   northing: 4507523
/// )
/// let geographic = try utm.geographic
/// ```
public struct UTMCoordinate: Sendable, Equatable, Hashable, Codable, LosslessStringConvertible {

  public var description: String {
    let hemi = hemisphere == .north ? "N" : "S"
    return String(format: "%d%@ %.0f %.0f", zone, hemi, easting, northing)
  }

  /// The UTM zone number (1–60).
  public let zone: Int

  /// The hemisphere (north or south of the equator).
  public let hemisphere: Hemisphere

  /// The easting in meters from the zone's central meridian (with 500 km
  /// false easting).
  public let easting: Double

  /// The northing in meters from the equator (with 10,000 km false northing
  /// in the southern hemisphere).
  public let northing: Double

  /// The geographic coordinate equivalent of this UTM coordinate.
  ///
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public var geographic: GeographicCoordinate {
    get throws {
      let (lat, lon) = try UTMUPS.reverse(
        zone: zone,
        hemisphere: hemisphere,
        easting: easting,
        northing: northing
      )
      return try GeographicCoordinate(latitude: lat, longitude: lon)
    }
  }

  /// The central meridian longitude for this zone, in degrees.
  public var centralMeridian: Double {
    UTMUPS.centralMeridian(zone: zone)
  }

  public init?(_ description: String) {
    let parts = description.split(separator: " ")
    guard parts.count == 3,
      let last = parts[0].last,
      last == "N" || last == "S",
      let zone = Int(parts[0].dropLast()),
      let easting = Double(parts[1]),
      let northing = Double(parts[2])
    else { return nil }
    try? self.init(
      zone: zone,
      hemisphere: last == "N" ? .north : .south,
      easting: easting,
      northing: northing
    )
  }

  /// Creates a UTM coordinate with explicit components.
  ///
  /// - Parameters:
  ///   - zone: The UTM zone number (1–60).
  ///   - hemisphere: The hemisphere.
  ///   - easting: The easting in meters.
  ///   - northing: The northing in meters.
  /// - Throws: ``SwiftGeographicError/invalidZone(_:)`` if the zone is
  ///   outside [1, 60].
  public init(
    zone: Int,
    hemisphere: Hemisphere,
    easting: Double,
    northing: Double
  ) throws {
    guard zone >= 1, zone <= 60 else {
      throw SwiftGeographicError.invalidZone(zone)
    }
    self.zone = zone
    self.hemisphere = hemisphere
    self.easting = easting
    self.northing = northing
  }

  /// The MGRS coordinate equivalent of this UTM coordinate.
  ///
  /// - Parameter precision: The desired MGRS precision level (defaults to
  ///   ``MGRSPrecision/oneMeter``).
  /// - Returns: The ``MGRSCoordinate``.
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public func mgrs(
    precision: MGRSPrecision = .oneMeter
  ) throws -> MGRSCoordinate {
    // Get latitude for band determination
    let (lat, _) = try UTMUPS.reverse(
      zone: zone,
      hemisphere: hemisphere,
      easting: easting,
      northing: northing
    )
    return MGRSEngine.forward(
      zone: zone,
      hemisphere: hemisphere,
      easting: easting,
      northing: northing,
      latitude: lat,
      precision: precision
    )
  }
}
