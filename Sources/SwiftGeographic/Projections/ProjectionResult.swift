/// The result of a map projection computation.
///
/// Contains either projected coordinates (forward) or geographic coordinates
/// (reverse), along with the meridian convergence angle and scale factor.
public struct ProjectionResult: Sendable, Equatable, Hashable, Codable, CustomStringConvertible {

  public var description: String {
    String(format: "(%.6f, %.6f) scale=%.10f convergence=%.6f", x, y, scale, convergence)
  }

  /// The first coordinate: easting in meters (forward) or latitude in degrees
  /// (reverse).
  public let x: Double

  /// The second coordinate: northing in meters (forward) or longitude in
  /// degrees (reverse).
  public let y: Double

  /// The meridian convergence in degrees.
  public let convergence: Double

  /// The point scale factor (dimensionless).
  public let scale: Double

  /// Creates a projection result.
  ///
  /// - Parameters:
  ///   - x: Easting (forward) or latitude (reverse).
  ///   - y: Northing (forward) or longitude (reverse).
  ///   - convergence: Meridian convergence in degrees.
  ///   - scale: Point scale factor.
  public init(
    x: Double,
    y: Double,
    convergence: Double,
    scale: Double
  ) {
    self.x = x
    self.y = y
    self.convergence = convergence
    self.scale = scale
  }
}
