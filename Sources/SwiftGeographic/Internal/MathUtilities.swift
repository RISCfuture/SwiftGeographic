import Foundation

/// Internal math utilities ported from GeographicLib.
///
/// These functions provide the numerical foundation for the Transverse
/// Mercator and Polar Stereographic projections.
enum MathUtilities {

  // MARK: - Angle Utilities

  /// Normalizes an angle to the range [-180, 180].
  static func angNormalize(_ x: Double) -> Double {
    var y = x.remainder(dividingBy: 360)
    if y == -180 { y = 180 }
    return y
  }

  /// Rounds tiny angle values near zero to zero, preserving exactness at
  /// cardinal angles.
  static func angRound(_ x: Double) -> Double {
    let z = 1.0 / 16.0
    var y = abs(x)
    y = y < z ? z - (z - y) : y
    return x < 0 ? -y : y
  }

  /// Computes the exact difference `y - x` reduced to [-180, 180].
  ///
  /// Uses error-free transformation to minimize roundoff.
  static func angDiff(
    _ x: Double,
    _ y: Double
  ) -> (difference: Double, residual: Double) {
    let (d, t) = sum(
      angNormalize(-x),
      angNormalize(y)
    )
    let dNorm = angNormalize(d)
    let result = dNorm == 180 && t > 0 ? -180.0 : dNorm
    return (result, t - (result - d))
  }

  /// Computes sine and cosine with argument in degrees, exact at multiples
  /// of 90.
  static func sincosd(_ x: Double) -> (sin: Double, cos: Double) {
    let q = Int((x / 90).rounded())
    let r = x - Double(q) * 90
    let θ = r * .pi / 180
    var sinx = sin(θ)
    var cosx = cos(θ)

    switch ((q % 4) + 4) % 4 {
      case 0: break
      case 1:
        let tmp = sinx
        sinx = cosx
        cosx = -tmp
      case 2:
        sinx = -sinx
        cosx = -cosx
      case 3:
        let tmp = sinx
        sinx = -cosx
        cosx = tmp
      default: break
    }

    // Ensure exact zeros at multiples of 90
    if sinx == 0 { sinx = .zero }
    if cosx == 0 { cosx = .zero }
    return (sinx, cosx)
  }

  /// Computes `atan2(y, x)` in degrees.
  static func atan2d(_ y: Double, _ x: Double) -> Double {
    atan2(y, x) * 180 / .pi
  }

  // MARK: - Error-Free Arithmetic

  /// Error-free summation: returns `(s, t)` where `s + t = u + v` exactly.
  ///
  /// Uses Knuth's two-sum algorithm.
  static func sum(_ u: Double, _ v: Double) -> (Double, Double) {
    let s = u + v
    let up = s - v
    let vpp = s - up
    let t = (u - up) + (v - vpp)
    return (s, t)
  }

  /// Evaluates a polynomial using Horner's method.
  ///
  /// - Parameters:
  ///   - coefficients: Coefficients in descending power order
  ///     `[c_n, c_{n-1}, ..., c_0]`.
  ///   - x: The evaluation point.
  /// - Returns: The polynomial value.
  static func polyval(_ coefficients: [Double], _ x: Double) -> Double {
    var result = 0.0
    for c in coefficients {
      result = result * x + c
    }
    return result
  }

  // MARK: - Conformal Latitude

  /// Computes `es * atanh(es * x)` accurately.
  ///
  /// This is the fundamental building block for conformal latitude
  /// conversions.
  static func eatanhe(_ x: Double, es: Double) -> Double {
    es * atanh(es * x)
  }

  /// Converts geographic tangent `tan(φ)` to conformal tangent `tan(χ)`.
  ///
  /// - Parameters:
  ///   - τ: Tangent of geographic latitude, `tan(φ)`.
  ///   - es: Signed first eccentricity.
  /// - Returns: Tangent of conformal latitude, `tan(χ)`.
  static func taupf(_ τ: Double, es: Double) -> Double {
    let τ1 = hypot(1, τ)
    let σ = sinh(eatanhe(τ / τ1, es: es))
    return hypot(1, σ) * τ - σ * τ1
  }

  /// Converts conformal tangent `tan(χ)` back to geographic tangent `tan(φ)`
  /// via Newton's method.
  ///
  /// Converges in 1–2 iterations for double precision.
  ///
  /// - Parameters:
  ///   - τʹ: Tangent of conformal latitude, `tan(χ)`.
  ///   - es: Signed first eccentricity.
  /// - Returns: Tangent of geographic latitude, `tan(φ)`.
  static func tauf(_ τʹ: Double, es: Double) -> Double {
    let e2m = 1 - es * es
    let tolerance = Double.ulpOfOne.squareRoot() / 10

    // Starting guess
    var τ =
      abs(τʹ) > 70
      ? τʹ * exp(eatanhe(1.0, es: es))
      : τʹ / e2m

    for _ in 0..<5 {
      let τa = taupf(τ, es: es)
      let δτʹ = τʹ - τa
      let δτ =
        δτʹ * (1 + e2m * τ * τ)
        / (e2m * hypot(1, τ) * hypot(1, τa))
      τ += δτ
      if abs(δτ) < tolerance * max(1, abs(τ)) {
        break
      }
    }
    return τ
  }
}
