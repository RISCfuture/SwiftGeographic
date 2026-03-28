import Foundation

/// A Universal Polar Stereographic (UPS) coordinate.
///
/// UPS covers the polar regions (latitudes beyond 84N and 80S) that are
/// not covered by UTM. It uses a Polar Stereographic projection centered
/// on each pole with a scale factor of 0.994.
///
/// ## Overview
///
/// ```swift
/// let ups = try UPSCoordinate(
///   hemisphere: .north,
///   easting: 2000000,
///   northing: 2000000
/// )
/// let geographic = try ups.geographic  // North pole
/// ```
public struct UPSCoordinate: Sendable, Equatable, Hashable, Codable, LosslessStringConvertible {

  public var description: String {
    let hemi = hemisphere == .north ? "N" : "S"
    return String(format: "%@ %.0f %.0f", hemi, easting, northing)
  }

  /// The hemisphere (north or south pole).
  public let hemisphere: Hemisphere

  /// The easting in meters (with 2,000 km false easting).
  public let easting: Double

  /// The northing in meters (with 2,000 km false northing).
  public let northing: Double

  /// The geographic coordinate equivalent of this UPS coordinate.
  ///
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public var geographic: GeographicCoordinate {
    get throws {
      let (lat, lon) = try UTMUPS.reverse(
        zone: 0,
        hemisphere: hemisphere,
        easting: easting,
        northing: northing
      )
      return try GeographicCoordinate(latitude: lat, longitude: lon)
    }
  }

  public init?(_ description: String) {
    let parts = description.split(separator: " ")
    guard parts.count == 3,
      let hemi = parts.first,
      hemi == "N" || hemi == "S",
      let easting = Double(parts[1]),
      let northing = Double(parts[2])
    else { return nil }
    try? self.init(
      hemisphere: hemi == "N" ? .north : .south,
      easting: easting,
      northing: northing
    )
  }

  /// Creates a UPS coordinate with explicit components.
  ///
  /// - Parameters:
  ///   - hemisphere: The hemisphere.
  ///   - easting: The easting in meters.
  ///   - northing: The northing in meters.
  /// - Throws: ``SwiftGeographicError/invalidUPSCoordinate`` if the
  ///   coordinates are out of range.
  public init(
    hemisphere: Hemisphere,
    easting: Double,
    northing: Double
  ) throws {
    self.hemisphere = hemisphere
    self.easting = easting
    self.northing = northing
  }

  /// The MGRS coordinate equivalent of this UPS coordinate.
  ///
  /// - Parameter precision: The desired MGRS precision level (defaults to
  ///   ``MGRSPrecision/oneMeter``).
  /// - Returns: The ``MGRSCoordinate``.
  public func mgrs(
    precision: MGRSPrecision = .oneMeter
  ) -> MGRSCoordinate {
    MGRSEngine.forward(
      zone: 0,
      hemisphere: hemisphere,
      easting: easting,
      northing: northing,
      precision: precision
    )
  }
}
