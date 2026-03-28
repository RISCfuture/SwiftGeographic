import Foundation
import Numerics
import Testing
@testable import SwiftGeographic

@Suite("Measurement Tests")
struct MeasurementTests {

  @Test("GeographicCoordinate angle measurements")
  func geoMeasurements() throws {
    let coord = try GeographicCoordinate(latitude: 48.8566, longitude: 2.3522)
    #expect(
      coord.latitudeAngle.value.isApproximatelyEqual(to: 48.8566, absoluteTolerance: 1e-10)
    )
    #expect(coord.latitudeAngle.unit == .degrees)
    #expect(
      coord.longitudeAngle.value.isApproximatelyEqual(to: 2.3522, absoluteTolerance: 1e-10)
    )
    #expect(coord.longitudeAngle.unit == .degrees)

    // Can convert to radians
    let latRad = coord.latitudeAngle.converted(to: .radians)
    #expect(latRad.value.isApproximatelyEqual(to: 0.85277, absoluteTolerance: 0.001))
  }

  @Test("UTMCoordinate distance measurements")
  func utmMeasurements() throws {
    let utm = try UTMCoordinate(
      zone: 18,
      hemisphere: .north,
      easting: 583960,
      northing: 4507523
    )
    #expect(utm.eastingDistance.value.isApproximatelyEqual(to: 583960, absoluteTolerance: 1e-6))
    #expect(utm.eastingDistance.unit == .meters)

    // Can convert to kilometers
    let eastingKm = utm.eastingDistance.converted(to: .kilometers)
    #expect(eastingKm.value.isApproximatelyEqual(to: 583.960, absoluteTolerance: 0.001))
  }

  @Test("MGRSPrecision resolution measurement")
  func precisionMeasurement() {
    let prec = MGRSPrecision.oneMeter
    #expect(prec.resolutionDistance.value.isApproximatelyEqual(to: 1, absoluteTolerance: 1e-10))
    #expect(prec.resolutionDistance.unit == .meters)

    let km = MGRSPrecision.oneKilometer.resolutionDistance.converted(to: .kilometers)
    #expect(km.value.isApproximatelyEqual(to: 1, absoluteTolerance: 1e-10))
  }
}
