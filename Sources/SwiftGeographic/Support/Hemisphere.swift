/// The hemisphere of a coordinate relative to the equator.
public enum Hemisphere: String, Sendable, Equatable, Hashable, Codable, CaseIterable,
  CustomStringConvertible
{

  /// The northern hemisphere (latitude >= 0).
  case north

  /// The southern hemisphere (latitude < 0).
  case south

  public var description: String {
    switch self {
      case .north: "north"
      case .south: "south"
    }
  }
}
