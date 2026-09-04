import Foundation
import Numerics
import Testing
@testable import SwiftGeographic

/// Compares longitudes accounting for wrapping (e.g. -180 and 180 are equivalent).
private func expectLongitudeEqual(
  _ a: Double,
  _ b: Double,
  tolerance: Double = 1e-9,
  _ comment: Comment? = nil,
  sourceLocation: SourceLocation = #_sourceLocation
) {
  var diff = abs(a - b)
  if diff > 180 { diff = 360 - diff }
  #expect(
    diff < tolerance,
    comment ?? "Expected longitude \(a) ≈ \(b) (tolerance \(tolerance))",
    sourceLocation: sourceLocation
  )
}

@Suite
struct `PolarStereographic Projection Tests` {

  private let ps = PolarStereographic.ups

  // MARK: - Forward Near Poles

  @Test
  func `Near north pole (89.9999) projects very close to (0, 0)`() {
    let result = ps.forward(isNorth: true, latitude: 89.9999, longitude: 0)
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 15))
    #expect(result.y.isApproximatelyEqual(to: 0, absoluteTolerance: 15))
  }

  @Test
  func `Near south pole (-89.9999) projects very close to (0, 0)`() {
    let result = ps.forward(isNorth: false, latitude: -89.9999, longitude: 0)
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 15))
    #expect(result.y.isApproximatelyEqual(to: 0, absoluteTolerance: 15))
  }

  @Test
  func `Scale at near-pole equals approximately k0 (0.994)`() {
    let result = ps.forward(isNorth: true, latitude: 89.9999, longitude: 0)
    #expect(result.scale.isApproximatelyEqual(to: 0.994, absoluteTolerance: 1e-3))
  }

  // MARK: - Forward at Polar Latitudes

  @Test
  func `Various longitudes at 85N produce same distance from pole`() {
    let longitudes: [Double] = [0, 45, 90, 135, -45, -90, -135]
    var distances: [Double] = []
    for lon in longitudes {
      let result = ps.forward(isNorth: true, latitude: 85, longitude: lon)
      let distance = sqrt(result.x * result.x + result.y * result.y)
      distances.append(distance)
    }
    // All distances from the pole should be equal (axial symmetry)
    for i in 1..<distances.count {
      #expect(
        distances[i].isApproximatelyEqual(to: distances[0], absoluteTolerance: 1e-3),
        "Distance at longitude \(longitudes[i]) should match distance at longitude 0"
      )
    }
  }

  @Test
  func `Forward at 85N, longitude 0 has negative y (north convention)`() {
    let result = ps.forward(isNorth: true, latitude: 85, longitude: 0)
    // At longitude 0, x should be ~0
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-3))
    // y should be negative for north pole projection at lon=0
    #expect(result.y < 0, "y should be negative for north pole at lon=0")
  }

  @Test
  func `Forward at 85S, longitude 0 has positive y (south convention)`() {
    let result = ps.forward(isNorth: false, latitude: -85, longitude: 0)
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-3))
    #expect(result.y > 0, "y should be positive for south pole at lon=0")
  }

  // MARK: - Forward-Reverse Round Trip

  @Test
  func `Forward-reverse round trip at north polar latitudes`() {
    let testPoints: [(lat: Double, lon: Double)] = [
      (89, 0),
      (85, 0),
      (85, 45),
      (85, 90),
      (85, -90),
      (87, 30),
      (88, -60)
    ]
    for point in testPoints {
      let fwd = ps.forward(isNorth: true, latitude: point.lat, longitude: point.lon)
      let rev = ps.reverse(isNorth: true, easting: fwd.x, northing: fwd.y)
      #expect(
        rev.x.isApproximatelyEqual(to: point.lat, absoluteTolerance: 1e-9),
        "Round-trip latitude failed for (\(point.lat), \(point.lon))"
      )
      expectLongitudeEqual(
        rev.y,
        point.lon,
        tolerance: 1e-9,
        "Round-trip longitude failed for (\(point.lat), \(point.lon))"
      )
    }
  }

  @Test
  func `Forward-reverse round trip at south polar latitudes`() {
    let testPoints: [(lat: Double, lon: Double)] = [
      (-89, 0),
      (-85, 0),
      (-85, 45),
      (-85, 90),
      (-85, -90),
      (-87, 30),
      (-88, -60)
    ]
    for point in testPoints {
      let fwd = ps.forward(isNorth: false, latitude: point.lat, longitude: point.lon)
      let rev = ps.reverse(isNorth: false, easting: fwd.x, northing: fwd.y)
      #expect(
        rev.x.isApproximatelyEqual(to: point.lat, absoluteTolerance: 1e-9),
        "Round-trip latitude failed for (\(point.lat), \(point.lon))"
      )
      expectLongitudeEqual(
        rev.y,
        point.lon,
        tolerance: 1e-9,
        "Round-trip longitude failed for (\(point.lat), \(point.lon))"
      )
    }
  }

  // MARK: - Reverse at Origin

  @Test
  func `Reverse at origin yields north pole`() {
    let result = ps.reverse(isNorth: true, easting: 0, northing: 0)
    #expect(result.x.isApproximatelyEqual(to: 90, absoluteTolerance: 1e-9))
  }

  @Test
  func `Reverse at origin yields south pole`() {
    let result = ps.reverse(isNorth: false, easting: 0, northing: 0)
    #expect(result.x.isApproximatelyEqual(to: -90, absoluteTolerance: 1e-9))
  }

  // MARK: - Scale and Convergence

  @Test
  func `Convergence at north polar latitudes equals the longitude`() {
    let longitudes: [Double] = [0, 30, 90, -45]
    for lon in longitudes {
      let result = ps.forward(isNorth: true, latitude: 85, longitude: lon)
      #expect(
        result.convergence.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-6),
        "Convergence should equal longitude for north polar"
      )
    }
  }

  @Test
  func `Convergence at south polar latitudes equals negated longitude`() {
    let longitudes: [Double] = [0, 30, 90, -45]
    for lon in longitudes {
      let result = ps.forward(isNorth: false, latitude: -85, longitude: lon)
      #expect(
        result.convergence.isApproximatelyEqual(to: -lon, absoluteTolerance: 1e-6),
        "Convergence should equal -longitude for south polar"
      )
    }
  }

  // MARK: - Distance from Pole Increases with Colatitude

  @Test
  func `Distance from pole increases as latitude moves away from pole`() {
    var previousDistance = 0.0
    for lat in [89.0, 88.0, 87.0, 86.0, 85.0] {
      let result = ps.forward(isNorth: true, latitude: lat, longitude: 0)
      let distance = sqrt(result.x * result.x + result.y * result.y)
      #expect(distance > previousDistance, "Distance should increase as latitude decreases")
      previousDistance = distance
    }
  }
}
