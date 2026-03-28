import Foundation

/// Errors that can occur during coordinate conversions and MGRS parsing.
public enum SwiftGeographicError: Error, Equatable, Hashable, Sendable,
  CustomStringConvertible, LocalizedError
{

  /// The latitude is outside the valid range [-90, 90].
  case invalidLatitude(_ latitude: Double)

  /// The longitude is outside the valid range [-180, 180].
  case invalidLongitude(_ longitude: Double)

  /// The UTM zone number is outside the valid range [1, 60].
  case invalidZone(_ zone: Int)

  /// The easting value is out of range for the given zone and hemisphere.
  case invalidEasting(_ easting: Double)

  /// The northing value is out of range for the given zone and hemisphere.
  case invalidNorthing(_ northing: Double)

  /// The MGRS string could not be parsed.
  case invalidMGRS(_ mgrs: String)

  /// The MGRS grid letters are inconsistent with the zone or latitude band.
  case inconsistentMGRS(_ mgrs: String)

  /// The UPS coordinates are out of the valid range.
  case invalidUPSCoordinate

  /// A coordinate falls outside the domain of the requested conversion.
  case outOfRange

  public var description: String {
    switch self {
      case .invalidLatitude(let lat):
        "Invalid latitude \(lat): must be in [-90, 90]"
      case .invalidLongitude(let lon):
        "Invalid longitude \(lon): must be in [-180, 180]"
      case .invalidZone(let zone):
        "Invalid UTM zone \(zone): must be in [1, 60] or 0 for UPS"
      case .invalidEasting(let e):
        "Invalid easting \(e)"
      case .invalidNorthing(let n):
        "Invalid northing \(n)"
      case .invalidMGRS(let mgrs):
        "Invalid MGRS string: \"\(mgrs)\""
      case .inconsistentMGRS(let mgrs):
        "Inconsistent MGRS string: \"\(mgrs)\""
      case .invalidUPSCoordinate:
        "Invalid UPS coordinate"
      case .outOfRange:
        "Coordinate out of range for the requested conversion"
    }
  }

  public var errorDescription: String? { description }
}
