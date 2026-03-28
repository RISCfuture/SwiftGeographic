import ComplexModule
import Foundation

/// A Transverse Mercator projection using Karney's 6th-order Krueger series.
///
/// This struct precomputes the series coefficients for a given ellipsoid
/// and scale factor, then provides forward and reverse projection methods.
/// The implementation achieves sub-nanometer accuracy for the full UTM range.
///
/// ## Usage
///
/// For standard UTM projections, use the pre-configured ``utm`` singleton:
///
/// ```swift
/// let result = TransverseMercator.utm.forward(
///   centralMeridian: -75,
///   latitude: 40.7128,
///   longitude: -74.0060
/// )
/// ```
///
/// For custom ellipsoids or scale factors, create your own instance:
///
/// ```swift
/// let tm = TransverseMercator(
///   semiMajorAxis: 6378137.0,
///   flattening: 1 / 298.257223563,
///   centralScale: 0.9996
/// )
/// ```
public struct TransverseMercator: Sendable {

  /// The standard UTM Transverse Mercator projection using WGS84.
  public static let utm = Self(
    semiMajorAxis: Constants.wgs84A,
    flattening: Constants.wgs84F,
    centralScale: Constants.utmK0
  )

  private static let maxpow = 6

  // Precomputed ellipsoid parameters
  private let a: Double
  private let k0: Double
  private let e2: Double
  private let es: Double
  private let e2m: Double
  private let c: Double
  private let n: Double
  private let b1: Double
  private let a1: Double

  // 6th-order Krueger coefficients (indices 1..6, index 0 unused)
  private let α: [Double]  // forward (7 elements, [0] unused)
  private let β: [Double]  // reverse (7 elements, [0] unused)

  /// Creates a Transverse Mercator projection for the given ellipsoid.
  ///
  /// - Parameters:
  ///   - semiMajorAxis: Equatorial radius in meters.
  ///   - flattening: Ellipsoid flattening (e.g., `1/298.257223563` for
  ///     WGS84).
  ///   - centralScale: Scale factor on the central meridian (e.g., `0.9996`
  ///     for UTM).
  public init(
    semiMajorAxis: Double,
    flattening: Double,
    centralScale: Double
  ) {
    a = semiMajorAxis
    let f = flattening
    k0 = centralScale
    e2 = f * (2 - f)
    es = f < 0 ? -sqrt(-e2) : sqrt(e2)
    e2m = 1 - e2
    c = sqrt(e2m) * exp(MathUtilities.eatanhe(1.0, es: es))
    n = f / (2 - f)

    // b1 polynomial: (n^6 + 4n^4 + 64n^2 + 256) / (256*(1+n))
    let n2 = n * n
    b1 = MathUtilities.polyval([1, 4, 64, 256], n2) / (256 * (1 + n))
    a1 = b1 * semiMajorAxis

    // Alpha coefficients (forward Krueger series)
    // Stored as flat arrays of integer numerator coefficients + denominator,
    // evaluated as alp[l] = n^l * polyval(coeffs, n) / denom
    let αCoeffs: [[Double]] = [
      [31564, -66675, 34440, 47250, -100800, 75600, 151200],
      [-1_983_433, 863232, 748608, -1_161_216, 524160, 1_935_360],
      [670412, 406647, -533952, 184464, 725760],
      [6_601_661, -7_732_800, 2_230_245, 7_257_600],
      [-13_675_556, 3_438_171, 7_983_360],
      [212_378_941, 319_334_400]
    ]

    let βCoeffs: [[Double]] = [
      [384796, -382725, -6720, 932400, -1_612_800, 1_209_600, 2_419_200],
      [-1_118_711, 1_695_744, -1_174_656, 258048, 80640, 3_870_720],
      [22276, -16929, -15984, 12852, 362880],
      [-830251, -158400, 197865, 7_257_600],
      [-435388, 453717, 15_966_720],
      [20_648_693, 638_668_800]
    ]

    // Compute coefficients using Horner evaluation
    var αArr = [Double](repeating: 0, count: Self.maxpow + 1)
    var βArr = [Double](repeating: 0, count: Self.maxpow + 1)
    var d = n
    for l in 1...Self.maxpow {
      let αc = αCoeffs[l - 1]
      let m = αc.count - 2  // polynomial order
      let denom = αc.last!
      αArr[l] = d * MathUtilities.polyval(Array(αc[0...m]), n) / denom

      let βc = βCoeffs[l - 1]
      let mβ = βc.count - 2
      let denomβ = βc.last!
      βArr[l] = d * MathUtilities.polyval(Array(βc[0...mβ]), n) / denomβ

      d *= n
    }
    α = αArr
    β = βArr
  }

  /// Projects a geographic coordinate onto the Transverse Mercator plane.
  ///
  /// - Parameters:
  ///   - centralMeridian: The longitude of the central meridian in degrees.
  ///   - latitude: Latitude in degrees [-90, 90].
  ///   - longitude: Longitude in degrees.
  /// - Returns: A ``ProjectionResult`` with easting (x), northing (y),
  ///   convergence, and scale.
  public func forward(
    centralMeridian: Double,
    latitude: Double,
    longitude: Double
  ) -> ProjectionResult {
    let lat = MathUtilities.angRound(latitude)
    var lon = MathUtilities.angDiff(centralMeridian, longitude).difference

    // Enforce parity
    let latSign: Double = lat.sign == .minus ? -1 : 1
    let lonSign: Double = lon.sign == .minus ? -1 : 1
    lon *= lonSign
    let absLat = lat * latSign

    let backside = lon > 90
    let adjLon = backside ? 180 - lon : lon

    let (sinφ, cosφ) = MathUtilities.sincosd(absLat)
    let (sinλ, cosλ) = MathUtilities.sincosd(adjLon)

    var ξʹ: Double, ηʹ: Double
    var γ: Double, k: Double

    if cosφ != 0 {
      let τ = sinφ / cosφ
      let τʹ = MathUtilities.taupf(τ, es: es)

      ξʹ = atan2(τʹ, cosλ)
      ηʹ = asinh(sinλ / hypot(τʹ, cosλ))

      // Gauss-Schreiber convergence and scale
      γ = MathUtilities.atan2d(sinλ * τʹ, cosλ * hypot(1, τʹ))
      k = sqrt(e2m + e2 * cosφ * cosφ) * hypot(1, τ) / hypot(τʹ, cosλ)
    } else {
      ξʹ = .pi / 2
      ηʹ = 0
      γ = adjLon
      k = c
    }

    // Clenshaw summation for Krueger series using complex arithmetic.
    // ζʹ = ξʹ + iηʹ; the series computes ζ = ζʹ + Σ α[j] sin(2jζʹ).
    let s0 = sin(2 * ξʹ), c0 = cos(2 * ξʹ)
    let sh0 = sinh(2 * ηʹ), ch0 = cosh(2 * ηʹ)

    let w = Complex(2 * c0 * ch0, -2 * s0 * sh0)  // 2 cos(2ζʹ)
    var y0 = Complex<Double>.zero, y1 = Complex<Double>.zero
    var z0 = Complex<Double>.zero, z1 = Complex<Double>.zero

    var j = Self.maxpow
    if j & 1 != 0 {
      y0 = Complex(α[j], 0)
      z0 = Complex(2 * Double(j) * α[j], 0)
      j -= 1
    }
    while j > 0 {
      y1 = w * y0 - y1 + Complex(α[j], 0)
      z1 = w * z0 - z1 + Complex(2 * Double(j) * α[j], 0)
      j -= 1
      y0 = w * y1 - y0 + Complex(α[j], 0)
      z0 = w * z1 - z0 + Complex(2 * Double(j) * α[j], 0)
      j -= 1
    }

    let sinζ = Complex(s0 * ch0, c0 * sh0)  // sin(2ζʹ)
    let cosζ = w / 2  // cos(2ζʹ)

    let correction = sinζ * y0
    let ξ = ξʹ + correction.real
    let η = ηʹ + correction.imaginary

    let dz = Complex(1, 0) - z1 + cosζ * z0
    γ -= MathUtilities.atan2d(dz.imaginary, dz.real)
    k *= b1 * dz.length

    var y = a1 * k0 * (backside ? .pi - ξ : ξ) * latSign
    let x = a1 * k0 * η * lonSign

    if backside { γ = 180 - γ }
    γ *= latSign * lonSign
    γ = MathUtilities.angNormalize(γ)
    k *= k0

    return ProjectionResult(x: x, y: y, convergence: γ, scale: k)
  }

  /// Computes the geographic coordinate from Transverse Mercator coordinates.
  ///
  /// - Parameters:
  ///   - centralMeridian: The longitude of the central meridian in degrees.
  ///   - easting: The easting in meters (without false easting).
  ///   - northing: The northing in meters (without false northing).
  /// - Returns: A ``ProjectionResult`` with latitude (x), longitude (y),
  ///   convergence, and scale.
  public func reverse(
    centralMeridian: Double,
    easting: Double,
    northing: Double
  ) -> ProjectionResult {
    var ξ = northing / (a1 * k0)
    var η = easting / (a1 * k0)

    // Enforce parity
    let ξSign: Double = ξ.sign == .minus ? -1 : 1
    let ηSign: Double = η.sign == .minus ? -1 : 1
    ξ *= ξSign
    η *= ηSign

    let backside = ξ > .pi / 2
    if backside { ξ = .pi - ξ }

    // Clenshaw summation for reverse Krueger series.
    // ζ = ξ + iη; the series computes ζʹ = ζ - Σ β[j] sin(2jζ).
    let s0 = sin(2 * ξ), c0 = cos(2 * ξ)
    let sh0 = sinh(2 * η), ch0 = cosh(2 * η)

    let w = Complex(2 * c0 * ch0, -2 * s0 * sh0)  // 2 cos(2ζ)
    var y0 = Complex<Double>.zero, y1 = Complex<Double>.zero
    var z0 = Complex<Double>.zero, z1 = Complex<Double>.zero

    var j = Self.maxpow
    if j & 1 != 0 {
      y0 = Complex(-β[j], 0)
      z0 = Complex(-2 * Double(j) * β[j], 0)
      j -= 1
    }
    while j > 0 {
      y1 = w * y0 - y1 - Complex(β[j], 0)
      z1 = w * z0 - z1 - Complex(2 * Double(j) * β[j], 0)
      j -= 1
      y0 = w * y1 - y0 - Complex(β[j], 0)
      z0 = w * z1 - z0 - Complex(2 * Double(j) * β[j], 0)
      j -= 1
    }

    let sinζ = Complex(s0 * ch0, c0 * sh0)  // sin(2ζ)
    let cosζ = w / 2  // cos(2ζ)

    let correction = sinζ * y0
    let ξʹ = ξ + correction.real
    let ηʹ = η + correction.imaginary

    let dz = Complex(1, 0) - z1 + cosζ * z0
    var γ = MathUtilities.atan2d(dz.imaginary, dz.real)
    var k = b1 / dz.length

    // Recover geographic coordinates
    let sinhηʹ = sinh(ηʹ)
    let cosξʹ = max(0, cos(ξʹ))
    let r = hypot(sinhηʹ, cosξʹ)

    var lat: Double
    var lon: Double

    if r != 0 {
      lon = MathUtilities.atan2d(sinhηʹ, cosξʹ)
      let sinξʹ = sin(ξʹ)
      let τ = MathUtilities.tauf(sinξʹ / r, es: es)
      lat = MathUtilities.atan2d(τ, 1)

      // Gauss-Schreiber convergence and scale
      γ += MathUtilities.atan2d(sinξʹ * tanh(ηʹ), cosξʹ)
      k *= sqrt(e2m + e2 / (1 + τ * τ)) * hypot(1, τ) * r
    } else {
      lat = 90
      lon = 0
      k *= c
    }

    lat *= ξSign
    if backside { lon = 180 - lon }
    lon *= ηSign
    lon = MathUtilities.angNormalize(lon + centralMeridian)
    if backside { γ = 180 - γ }
    γ *= ξSign * ηSign
    γ = MathUtilities.angNormalize(γ)
    k *= k0

    return ProjectionResult(x: lat, y: lon, convergence: γ, scale: k)
  }
}
