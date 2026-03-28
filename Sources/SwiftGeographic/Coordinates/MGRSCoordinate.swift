import Foundation

/// A Military Grid Reference System (MGRS) coordinate.
///
/// MGRS provides a geocoordinate standard used by NATO militaries for
/// locating points on Earth. An MGRS coordinate string consists of a
/// grid zone designator, a 100 km square identification, and a numeric
/// location within the square.
///
/// ## Overview
///
/// Parse an MGRS string:
///
/// ```swift
/// let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
/// let geographic = try mgrs.geographic
/// ```
///
/// Get the MGRS string back:
///
/// ```swift
/// print(mgrs.gridReference)  // "18SUJ2337106519"
/// ```
public struct MGRSCoordinate: Sendable, Equatable, Hashable, Codable, LosslessStringConvertible {

  /// The grid zone designator (e.g., `"18S"` for UTM or `"A"` for UPS).
  public let gridZone: String

  /// The 100 km square identification (two letters, e.g., `"UJ"`).
  public let squareIdentifier: String

  /// The numeric easting within the 100 km square in meters.
  public let easting: Double

  /// The numeric northing within the 100 km square in meters.
  public let northing: Double

  /// The precision level of this coordinate.
  public let precision: MGRSPrecision

  // Internal storage for conversions
  private var utmZone: Int
  private var utmHemisphere: Hemisphere
  private var fullEasting: Double
  private var fullNorthing: Double

  public var description: String {
    gridReference
  }

  /// The full MGRS string representation at this coordinate's precision.
  public var gridReference: String {
    let digits = MGRSEngine.formatDigits(
      easting: fullEasting,
      northing: fullNorthing,
      precision: precision
    )
    return "\(gridZone)\(squareIdentifier)\(digits)"
  }

  /// The geographic coordinate at the center of this MGRS grid cell.
  ///
  /// - Throws: ``SwiftGeographicError`` if the conversion fails.
  public var geographic: GeographicCoordinate {
    get throws {
      // Add half the resolution for center of cell
      let halfRes = precision.resolution / 2
      let (lat, lon) = try UTMUPS.reverse(
        zone: utmZone,
        hemisphere: utmHemisphere,
        easting: fullEasting + halfRes,
        northing: fullNorthing + halfRes
      )
      return try GeographicCoordinate(latitude: lat, longitude: lon)
    }
  }

  /// The UTM coordinate equivalent (for non-polar MGRS).
  ///
  /// - Throws: ``SwiftGeographicError/invalidZone(_:)`` if this is a polar
  ///   (UPS) coordinate.
  public var utm: UTMCoordinate {
    get throws {
      guard utmZone > 0 else {
        throw SwiftGeographicError.invalidZone(0)
      }
      return try UTMCoordinate(
        zone: utmZone,
        hemisphere: utmHemisphere,
        easting: fullEasting,
        northing: fullNorthing
      )
    }
  }

  /// The UPS coordinate equivalent (for polar MGRS).
  ///
  /// - Throws: ``SwiftGeographicError`` if this is not a polar coordinate.
  public var ups: UPSCoordinate {
    get throws {
      guard utmZone == 0 else {
        throw SwiftGeographicError.outOfRange
      }
      return try UPSCoordinate(
        hemisphere: utmHemisphere,
        easting: fullEasting,
        northing: fullNorthing
      )
    }
  }

  /// Whether this is a polar (UPS) coordinate.
  public var isPolar: Bool {
    utmZone == 0
  }

  public init?(_ description: String) {
    try? self.init(string: description)
  }

  /// Creates an MGRS coordinate from its components.
  internal init(
    gridZone: String,
    squareIdentifier: String,
    easting: Double,
    northing: Double,
    precision: MGRSPrecision,
    utmZone: Int,
    hemisphere: Hemisphere,
    fullEasting: Double,
    fullNorthing: Double
  ) {
    self.gridZone = gridZone
    self.squareIdentifier = squareIdentifier
    self.easting = easting
    self.northing = northing
    self.precision = precision
    self.utmZone = utmZone
    self.utmHemisphere = hemisphere
    self.fullEasting = fullEasting
    self.fullNorthing = fullNorthing
  }

  /// Parses an MGRS coordinate string.
  ///
  /// Accepts standard MGRS formats such as `"18SUJ2337106519"` (1 m
  /// precision), `"18SUJ23370651"` (10 m), or `"18SUJ"` (100 km).
  ///
  /// - Parameter string: An MGRS string.
  /// - Throws: ``SwiftGeographicError/invalidMGRS(_:)`` if the string
  ///   cannot be parsed.
  public init(string: String) throws {
    let parsed = try MGRSEngine.reverse(string)
    utmZone = parsed.zone
    utmHemisphere = parsed.hemisphere
    fullEasting = parsed.easting
    fullNorthing = parsed.northing
    precision = parsed.precision

    // Extract grid zone and square identifier from the string
    let upper = string.uppercased()
    let chars = Array(upper)

    var idx = 0
    // Parse zone digits
    while idx < chars.count, chars[idx].isNumber {
      idx += 1
    }

    // Band letter
    if idx < chars.count {
      let zoneStr = String(chars[..<idx])
      let bandLetter = chars[idx]
      idx += 1

      if zoneStr.isEmpty {
        gridZone = String(bandLetter)
      } else {
        gridZone = zoneStr + String(bandLetter)
      }
    } else {
      gridZone = ""
    }

    // Square identifier (next 2 letters)
    if idx + 1 < chars.count, chars[idx].isLetter, chars[idx + 1].isLetter {
      squareIdentifier = String(chars[idx]) + String(chars[idx + 1])
    } else {
      squareIdentifier = ""
    }

    // Easting and northing within the 100 km square
    easting = fullEasting.truncatingRemainder(dividingBy: Constants.tile)
    northing = fullNorthing.truncatingRemainder(dividingBy: Constants.tile)
  }
}
