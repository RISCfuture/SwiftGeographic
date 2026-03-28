import Foundation

/// A Polar Stereographic projection following Snyder's formulation.
///
/// Provides forward and reverse projection between geographic coordinates
/// and the Polar Stereographic plane for polar regions.
///
/// ## Usage
///
/// For standard UPS projections, use the pre-configured ``ups`` singleton:
///
/// ```swift
/// let result = PolarStereographic.ups.forward(
///   isNorth: true,
///   latitude: 85.0,
///   longitude: 10.0
/// )
/// ```
public struct PolarStereographic: Sendable {

  /// The standard UPS Polar Stereographic projection using WGS84.
  public static let ups = Self(
    semiMajorAxis: Constants.wgs84A,
    flattening: Constants.wgs84F,
    centralScale: Constants.upsK0
  )

  private let a: Double
  private let f: Double
  private let k0: Double
  private let e2: Double
  private let es: Double
  private let e2m: Double
  private let c: Double  // conformal radius normalization

  /// Creates a Polar Stereographic projection for the given ellipsoid.
  ///
  /// - Parameters:
  ///   - semiMajorAxis: Equatorial radius in meters.
  ///   - flattening: Ellipsoid flattening.
  ///   - centralScale: Scale factor at the pole.
  public init(
    semiMajorAxis: Double,
    flattening: Double,
    centralScale: Double
  ) {
    a = semiMajorAxis
    f = flattening
    k0 = centralScale
    e2 = f * (2 - f)
    es = f < 0 ? -sqrt(-e2) : sqrt(e2)
    e2m = 1 - e2
    c = sqrt(e2m) * exp(MathUtilities.eatanhe(1.0, es: es))
  }

  /// Projects a geographic coordinate onto the Polar Stereographic plane.
  ///
  /// - Parameters:
  ///   - isNorth: `true` for the north pole, `false` for the south pole.
  ///   - latitude: Latitude in degrees [-90, 90].
  ///   - longitude: Longitude in degrees.
  /// - Returns: A ``ProjectionResult`` with easting (x), northing (y),
  ///   convergence, and scale.
  public func forward(
    isNorth: Bool,
    latitude: Double,
    longitude: Double
  ) -> ProjectionResult {
    let lat = isNorth ? latitude : -latitude

    // Handle exact pole to avoid division by zero
    if lat == 90 {
      let γ = isNorth ? longitude : -longitude
      return ProjectionResult(x: 0, y: 0, convergence: γ, scale: k0)
    }

    let (sinφ, cosφ) = MathUtilities.sincosd(lat)
    let (sinλ, cosλ) = MathUtilities.sincosd(longitude)

    let τ = sinφ / max(cosφ, Double.leastNonzeroMagnitude)
    let τʹ = MathUtilities.taupf(τ, es: es)
    let absτʹ = abs(τʹ)
    let ρ = hypot(1, τʹ) + absτʹ
    let ρInv = 2 * k0 * a / c / ρ

    let x = ρInv * sinλ
    let y = (isNorth ? -ρInv : ρInv) * cosλ

    // Convergence is just the longitude for polar stereographic
    let γ = isNorth ? longitude : -longitude

    // Scale
    let secφ = hypot(1, τ)
    let k: Double
    if cosφ != 0 {
      k = ρInv / a * secφ * sqrt(e2m + e2 / (secφ * secφ))
    } else {
      k = k0
    }

    return ProjectionResult(x: x, y: y, convergence: γ, scale: k)
  }

  /// Computes the geographic coordinate from Polar Stereographic coordinates.
  ///
  /// - Parameters:
  ///   - isNorth: `true` for the north pole, `false` for the south pole.
  ///   - easting: The easting in meters (without false easting).
  ///   - northing: The northing in meters (without false northing).
  /// - Returns: A ``ProjectionResult`` with latitude (x), longitude (y),
  ///   convergence, and scale.
  public func reverse(
    isNorth: Bool,
    easting: Double,
    northing: Double
  ) -> ProjectionResult {
    let ρ = hypot(easting, northing)

    // At the pole (ρ == 0), return the pole directly to avoid overflow
    if ρ == 0 {
      let lat = isNorth ? 90.0 : -90.0
      return ProjectionResult(x: lat, y: 0, convergence: 0, scale: k0)
    }

    let t = ρ * c / (2 * k0 * a)
    let τʹ = (1 / t - t) / 2

    let τ = MathUtilities.tauf(τʹ, es: es)
    let lat = (isNorth ? 1.0 : -1.0) * MathUtilities.atan2d(τ, 1)

    let yAdj = isNorth ? -northing : northing
    let lon = MathUtilities.atan2d(easting, yAdj)

    // Convergence
    let γ = MathUtilities.angNormalize(isNorth ? lon : -lon)

    // Scale
    let secφ = hypot(1, τ)
    let cosφ = 1 / secφ
    let k: Double
    if cosφ != 0 {
      let ρNorm = ρ / a
      k = ρNorm * secφ * sqrt(e2m + e2 * cosφ * cosφ)
    } else {
      k = k0
    }

    return ProjectionResult(x: lat, y: lon, convergence: γ, scale: k)
  }
}
