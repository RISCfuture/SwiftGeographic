/// The precision level of an MGRS coordinate string.
///
/// Each level corresponds to a ground resolution, from 100 km (level 0)
/// down to 1 micrometer (level 11). The most common precision for practical
/// use is ``oneMeter`` (5 digits per axis).
public enum MGRSPrecision: Int, Sendable, Equatable, Hashable, Codable, Comparable,
  CaseIterable, CustomStringConvertible
{

  /// 100 km resolution (grid zone and square only, no digits).
  case hundredKilometer = 0

  /// 10 km resolution (1 digit per axis).
  case tenKilometer = 1

  /// 1 km resolution (2 digits per axis).
  case oneKilometer = 2

  /// 100 m resolution (3 digits per axis).
  case hundredMeter = 3

  /// 10 m resolution (4 digits per axis).
  case tenMeter = 4

  /// 1 m resolution (5 digits per axis).
  case oneMeter = 5

  /// 100 mm resolution (6 digits per axis).
  case hundredMillimeter = 6

  /// 10 mm resolution (7 digits per axis).
  case tenMillimeter = 7

  /// 1 mm resolution (8 digits per axis).
  case oneMillimeter = 8

  /// 100 micrometer resolution (9 digits per axis).
  case hundredMicrometer = 9

  /// 10 micrometer resolution (10 digits per axis).
  case tenMicrometer = 10

  /// 1 micrometer resolution (11 digits per axis).
  case oneMicrometer = 11

  public var description: String {
    switch self {
      case .hundredKilometer: "100 km"
      case .tenKilometer: "10 km"
      case .oneKilometer: "1 km"
      case .hundredMeter: "100 m"
      case .tenMeter: "10 m"
      case .oneMeter: "1 m"
      case .hundredMillimeter: "100 mm"
      case .tenMillimeter: "10 mm"
      case .oneMillimeter: "1 mm"
      case .hundredMicrometer: "100 \u{00B5}m"
      case .tenMicrometer: "10 \u{00B5}m"
      case .oneMicrometer: "1 \u{00B5}m"
    }
  }

  /// The ground resolution in meters for this precision level.
  public var resolution: Double {
    switch self {
      case .hundredKilometer: 100_000
      case .tenKilometer: 10_000
      case .oneKilometer: 1_000
      case .hundredMeter: 100
      case .tenMeter: 10
      case .oneMeter: 1
      case .hundredMillimeter: 0.1
      case .tenMillimeter: 0.01
      case .oneMillimeter: 0.001
      case .hundredMicrometer: 0.000_1
      case .tenMicrometer: 0.000_01
      case .oneMicrometer: 0.000_001
    }
  }

  /// Compares by resolution level. A lower raw value means coarser resolution,
  /// so `.hundredKilometer < .oneMeter` (100 km is less precise than 1 m).
  public static func < (lhs: Self, rhs: Self) -> Bool {
    lhs.rawValue < rhs.rawValue
  }
}
