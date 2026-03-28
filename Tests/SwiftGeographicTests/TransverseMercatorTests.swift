import Foundation
import Numerics
import Testing
@testable import SwiftGeographic

@Suite("TransverseMercator Projection Tests")
struct TransverseMercatorTests {

  private let tm = TransverseMercator.utm

  // MARK: - Forward Projection

  @Test("Forward projection at equator and central meridian yields (0, 0)")
  func forwardAtOrigin() {
    let result = tm.forward(centralMeridian: 0, latitude: 0, longitude: 0)
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-10))
    #expect(result.y.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-10))
  }

  @Test("Scale at central meridian equals k0 (0.9996)")
  func scaleAtCentralMeridian() {
    let result = tm.forward(centralMeridian: 0, latitude: 0, longitude: 0)
    #expect(result.scale.isApproximatelyEqual(to: 0.9996, absoluteTolerance: 1e-10))
  }

  @Test("Convergence at central meridian is zero")
  func convergenceAtCentralMeridian() {
    let result = tm.forward(centralMeridian: 0, latitude: 45, longitude: 0)
    #expect(result.convergence.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-10))
  }

  @Test("Forward projection of New York City (40.7128, -74.006) with CM -75")
  func forwardNewYorkCity() {
    let result = tm.forward(centralMeridian: -75, latitude: 40.7128, longitude: -74.006)
    #expect(result.x.isApproximatelyEqual(to: 83960, absoluteTolerance: 50))
    #expect(result.y.isApproximatelyEqual(to: 4507351, absoluteTolerance: 50))
  }

  @Test("Forward projection at various latitudes on central meridian")
  func forwardAtVariousLatitudes() {
    let latitudes: [Double] = [0, 30, 60, 80]
    for lat in latitudes {
      let result = tm.forward(centralMeridian: 0, latitude: lat, longitude: 0)
      #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6))
      if lat > 0 {
        #expect(result.y > 0, "Northing should be positive for latitude \(lat)")
      }
      #expect(result.scale.isApproximatelyEqual(to: 0.9996, absoluteTolerance: 1e-6))
    }
  }

  @Test("Forward projection yields increasing northing with latitude")
  func forwardNorthingIncreasesWithLatitude() {
    var previousNorthing = -Double.infinity
    for lat in stride(from: 0.0, through: 80, by: 10) {
      let result = tm.forward(centralMeridian: 0, latitude: lat, longitude: 0)
      #expect(result.y > previousNorthing, "Northing should increase with latitude")
      previousNorthing = result.y
    }
  }

  // MARK: - Forward-Reverse Round Trip

  @Test("Forward-reverse round trip within 1e-9 degrees")
  func forwardReverseRoundTrip() {
    let testPoints: [(lat: Double, lon: Double, cm: Double)] = [
      (0, 0, 0),
      (40.7128, -74.006, -75),
      (51.5074, -0.1278, -3),
      (-33.8688, 151.2093, 153),
      (60, 2, 3),
      (80, 5, 3),
      (30, 30, 33)
    ]
    for point in testPoints {
      let fwd = tm.forward(
        centralMeridian: point.cm,
        latitude: point.lat,
        longitude: point.lon
      )
      let rev = tm.reverse(
        centralMeridian: point.cm,
        easting: fwd.x,
        northing: fwd.y
      )
      #expect(
        rev.x.isApproximatelyEqual(to: point.lat, absoluteTolerance: 1e-9),
        "Round-trip latitude failed for (\(point.lat), \(point.lon))"
      )
      #expect(
        rev.y.isApproximatelyEqual(to: point.lon, absoluteTolerance: 1e-9),
        "Round-trip longitude failed for (\(point.lat), \(point.lon))"
      )
    }
  }

  // MARK: - Reverse Projection

  @Test("Reverse projection at origin yields (0, CM)")
  func reverseAtOrigin() {
    let result = tm.reverse(centralMeridian: 15, easting: 0, northing: 0)
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-10))
    #expect(result.y.isApproximatelyEqual(to: 15, absoluteTolerance: 1e-10))
  }

  @Test("Reverse projection scale matches forward scale")
  func reverseScaleMatchesForward() {
    let fwd = tm.forward(centralMeridian: -75, latitude: 40.7128, longitude: -74.006)
    let rev = tm.reverse(centralMeridian: -75, easting: fwd.x, northing: fwd.y)
    #expect(fwd.scale.isApproximatelyEqual(to: rev.scale, absoluteTolerance: 1e-9))
  }

  @Test("Reverse projection convergence matches forward convergence")
  func reverseConvergenceMatchesForward() {
    let fwd = tm.forward(centralMeridian: -75, latitude: 40.7128, longitude: -74.006)
    let rev = tm.reverse(centralMeridian: -75, easting: fwd.x, northing: fwd.y)
    #expect(fwd.convergence.isApproximatelyEqual(to: rev.convergence, absoluteTolerance: 1e-9))
  }

  @Test("Forward projection at negative latitudes")
  func forwardNegativeLatitude() {
    let result = tm.forward(centralMeridian: 0, latitude: -45, longitude: 0)
    let resultPos = tm.forward(centralMeridian: 0, latitude: 45, longitude: 0)
    #expect(result.x.isApproximatelyEqual(to: resultPos.x, absoluteTolerance: 1e-10))
    #expect(result.y.isApproximatelyEqual(to: -resultPos.y, absoluteTolerance: 1e-10))
  }
}

// MARK: - TMcoords.dat Validation

/// Validates the Transverse Mercator implementation against Karney's
/// TMcoords.dat reference dataset (287,000 test vectors computed from Lee's
/// exact TM formulas at 80-digit precision).
///
/// Source: C. Karney, "Test data for the transverse Mercator projection"
/// DOI: 10.5281/zenodo.32470 (CC0 license)
///
/// Each line contains: lat lon easting northing convergence scale
/// Projection parameters: WGS84 ellipsoid, CM = 0, k0 = 0.9996
///
/// The 6th-order Krueger series converges within ~3900 km (~35 deg) of the
/// central meridian. Points beyond this range are in the extended domain
/// where only Lee's exact formulation is accurate. We filter test vectors
/// by reference easting to stay within the convergence zone.
@Suite("TMcoords.dat Validation (287K points)")
struct TMCoordsValidationTests {

  private static let tm = TransverseMercator.utm

  /// Maximum easting for the 6th-order Krueger series convergence zone.
  /// Karney states 5 nm accuracy within 3900 km of the CM.
  private static let maxEasting = 3_900_000.0

  /// Parses all 287,000 test vectors from TMcoords.dat.
  private static func loadTestVectors() throws -> [TestVector] {
    guard
      let url = Bundle.module.url(
        forResource: "TMcoords",
        withExtension: "dat"
      )
    else {
      throw SwiftGeographicError.outOfRange
    }
    let contents = try String(contentsOf: url, encoding: .utf8)
    return contents.split(separator: "\n").compactMap { line in
      let parts = line.split(separator: " ")
      guard parts.count == 6,
        let lat = Double(parts[0]),
        let lon = Double(parts[1]),
        let easting = Double(parts[2]),
        let northing = Double(parts[3]),
        let convergence = Double(parts[4]),
        let scale = Double(parts[5])
      else { return nil }
      return TestVector(
        lat: lat,
        lon: lon,
        easting: easting,
        northing: northing,
        convergence: convergence,
        scale: scale
      )
    }
  }

  /// Filters to vectors within the 6th-order convergence zone.
  private static func convergenceZoneVectors(
    from vectors: [TestVector]
  ) -> [TestVector] {
    vectors.filter { abs($0.easting) < maxEasting }
  }

  @Test("Forward projection within convergence zone matches reference within 15 nm")
  func forwardValidation() throws {
    let all = try Self.loadTestVectors()
    #expect(all.count == 287_000, "Expected 287000 test vectors")

    let vectors = Self.convergenceZoneVectors(from: all)

    let tolerance = 15e-9
    var maxEastingError = 0.0
    var maxNorthingError = 0.0
    var failCount = 0
    var tested = 0

    for v in vectors {
      let result = Self.tm.forward(
        centralMeridian: 0,
        latitude: v.lat,
        longitude: v.lon
      )
      let eastingError = abs(result.x - v.easting)
      let northingError = abs(result.y - v.northing)
      maxEastingError = max(maxEastingError, eastingError)
      maxNorthingError = max(maxNorthingError, northingError)
      tested += 1

      if eastingError > tolerance || northingError > tolerance {
        failCount += 1
        if failCount <= 5 {
          Issue.record(
            """
            Forward mismatch at (\(v.lat), \(v.lon)):
              easting:  got \(result.x), expected \(v.easting), error \(eastingError) m
              northing: got \(result.y), expected \(v.northing), error \(northingError) m
            """
          )
        }
      }
    }

    #expect(
      failCount == 0,
      """
      \(failCount)/\(tested) forward projections exceeded 15 nm.
      Max easting error: \(maxEastingError) m, max northing error: \(maxNorthingError) m
      """
    )
  }

  @Test("Reverse projection within convergence zone matches reference within 1e-9 deg")
  func reverseValidation() throws {
    let all = try Self.loadTestVectors()
    let vectors = Self.convergenceZoneVectors(from: all)

    let tolerance = 1e-9
    var maxLatError = 0.0
    var maxLonError = 0.0
    var failCount = 0
    var tested = 0

    for v in vectors {
      let result = Self.tm.reverse(
        centralMeridian: 0,
        easting: v.easting,
        northing: v.northing
      )
      let latError = abs(result.x - v.lat)
      let cosLat = cos(abs(v.lat) * .pi / 180)
      let lonError = abs(result.y - v.lon) * max(cosLat, 1e-12)
      maxLatError = max(maxLatError, latError)
      maxLonError = max(maxLonError, lonError)
      tested += 1

      if latError > tolerance || lonError > tolerance {
        failCount += 1
        if failCount <= 5 {
          Issue.record(
            """
            Reverse mismatch at easting=\(v.easting), northing=\(v.northing):
              lat: got \(result.x), expected \(v.lat), error \(latError) deg
              lon: got \(result.y), expected \(v.lon), error \(lonError) deg
            """
          )
        }
      }
    }

    #expect(
      failCount == 0,
      """
      \(failCount)/\(tested) reverse projections exceeded 1e-9 deg.
      Max lat error: \(maxLatError) deg, max lon error: \(maxLonError) deg
      """
    )
  }

  @Test("Scale within convergence zone matches reference within 1e-12 relative error")
  func scaleValidation() throws {
    let all = try Self.loadTestVectors()
    let vectors = Self.convergenceZoneVectors(from: all)

    let tolerance = 1e-12
    var maxRelError = 0.0
    var failCount = 0
    var tested = 0

    for v in vectors {
      let result = Self.tm.forward(
        centralMeridian: 0,
        latitude: v.lat,
        longitude: v.lon
      )
      let relError = abs(result.scale - v.scale) / v.scale
      maxRelError = max(maxRelError, relError)
      tested += 1

      if relError > tolerance {
        failCount += 1
      }
    }

    #expect(
      failCount == 0,
      """
      \(failCount)/\(tested) scale values exceeded 1e-12 relative tolerance.
      Max relative error: \(maxRelError)
      """
    )
  }

  @Test("Convergence within convergence zone matches reference within 1e-9 deg")
  func convergenceValidation() throws {
    let all = try Self.loadTestVectors()
    let vectors = Self.convergenceZoneVectors(from: all)

    let tolerance = 1e-9
    var maxError = 0.0
    var failCount = 0
    var tested = 0

    for v in vectors {
      let result = Self.tm.forward(
        centralMeridian: 0,
        latitude: v.lat,
        longitude: v.lon
      )
      let error = abs(result.convergence - v.convergence)
      maxError = max(maxError, error)
      tested += 1

      if error > tolerance {
        failCount += 1
      }
    }

    #expect(
      failCount == 0,
      """
      \(failCount)/\(tested) convergence values exceeded 1e-9 deg.
      Max error: \(maxError) deg
      """
    )
  }

  private struct TestVector {
    let lat: Double
    let lon: Double
    let easting: Double
    let northing: Double
    let convergence: Double
    let scale: Double
  }
}
