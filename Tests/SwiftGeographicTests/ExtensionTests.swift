import Foundation
import Numerics
import Testing
@testable import SwiftGeographic

// MARK: - String Conformance Tests

@Suite("String Conformance Tests")
struct StringConformanceTests {

  @Test("GeographicCoordinate description format")
  func geoDescription() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    #expect(coord.description.contains("40.712800N"))
    #expect(coord.description.contains("74.006000W"))
  }

  @Test("GeographicCoordinate description for southern/eastern point")
  func geoDescriptionSE() throws {
    let coord = try GeographicCoordinate(latitude: -33.8688, longitude: 151.2093)
    #expect(coord.description.contains("S"))
    #expect(coord.description.contains("E"))
  }

  @Test("UTMCoordinate description format")
  func utmDescription() throws {
    let utm = try UTMCoordinate(
      zone: 18,
      hemisphere: .north,
      easting: 583960,
      northing: 4507523
    )
    #expect(utm.description.hasPrefix("18N"))
    #expect(utm.description.contains("583960"))
  }

  @Test("UPSCoordinate description format")
  func upsDescription() throws {
    let ups = try UPSCoordinate(
      hemisphere: .north,
      easting: 2_000_000,
      northing: 2_000_000
    )
    #expect(ups.description.hasPrefix("N"))
    #expect(ups.description.contains("2000000"))
  }

  @Test("MGRSCoordinate description is gridReference")
  func mgrsDescription() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(mgrs.description == mgrs.gridReference)
  }

  @Test("MGRSCoordinate LosslessStringConvertible round-trip")
  func mgrsLosslessStringConvertible() throws {
    let original = try MGRSCoordinate(string: "33XVG7459743593")
    let fromDesc = MGRSCoordinate(original.description)
    #expect(fromDesc != nil)
    #expect(fromDesc?.gridReference == original.gridReference)
  }

  @Test("MGRSCoordinate LosslessStringConvertible returns nil for invalid")
  func mgrsLosslessInvalid() {
    let result = MGRSCoordinate("not-valid-mgrs!!!")
    #expect(result == nil)
  }

  @Test("Hemisphere description")
  func hemisphereDescription() {
    #expect(Hemisphere.north.description == "north")
    #expect(Hemisphere.south.description == "south")
  }

  @Test("MGRSPrecision description")
  func precisionDescription() {
    #expect(MGRSPrecision.oneMeter.description == "1 m")
    #expect(MGRSPrecision.oneKilometer.description == "1 km")
    #expect(MGRSPrecision.hundredKilometer.description == "100 km")
    #expect(MGRSPrecision.oneMillimeter.description == "1 mm")
  }

  @Test("SwiftGeographicError description")
  func errorDescription() {
    let error = SwiftGeographicError.invalidLatitude(91)
    #expect(error.description.contains("91"))
    #expect(error.description.contains("latitude"))
  }

  @Test("SwiftGeographicError localizedDescription")
  func errorLocalized() {
    let error = SwiftGeographicError.invalidMGRS("bad")
    #expect(error.localizedDescription.contains("bad"))
  }

  @Test("ProjectionResult description")
  func projectionResultDescription() {
    let result = ProjectionResult(x: 100, y: 200, convergence: 1.5, scale: 0.9996)
    #expect(result.description.contains("100"))
    #expect(result.description.contains("0.9996"))
  }
}

// MARK: - Protocol Conformance Tests

@Suite("Protocol Conformance Tests")
struct ProtocolConformanceTests {

  @Test("MGRSPrecision is Comparable")
  func precisionComparable() {
    #expect(MGRSPrecision.hundredKilometer < MGRSPrecision.oneMeter)
    #expect(MGRSPrecision.oneMeter < MGRSPrecision.oneMillimeter)
    #expect(MGRSPrecision.oneMillimeter < MGRSPrecision.oneMicrometer)
  }

  @Test("MGRSPrecision sort order")
  func precisionSort() {
    let shuffled: [MGRSPrecision] = [.oneMeter, .hundredKilometer, .oneMillimeter]
    let sorted = shuffled.sorted()
    #expect(sorted == [.hundredKilometer, .oneMeter, .oneMillimeter])
  }

  @Test("ProjectionResult is Hashable")
  func projectionResultHashable() {
    let a = ProjectionResult(x: 1, y: 2, convergence: 3, scale: 4)
    let b = ProjectionResult(x: 1, y: 2, convergence: 3, scale: 4)
    #expect(a.hashValue == b.hashValue)

    var set = Set<ProjectionResult>()
    set.insert(a)
    set.insert(b)
    #expect(set.count == 1)
  }

  @Test("ProjectionResult is Codable")
  func projectionResultCodable() throws {
    let original = ProjectionResult(x: 100, y: 200, convergence: 1.5, scale: 0.9996)
    let data = try JSONEncoder().encode(original)
    let decoded = try JSONDecoder().decode(ProjectionResult.self, from: data)
    #expect(decoded == original)
  }

  @Test("SwiftGeographicError is Hashable")
  func errorHashable() {
    let a = SwiftGeographicError.invalidLatitude(91)
    let b = SwiftGeographicError.invalidLatitude(91)
    let c = SwiftGeographicError.invalidLatitude(92)
    #expect(a.hashValue == b.hashValue)

    var set = Set<SwiftGeographicError>()
    set.insert(a)
    set.insert(b)
    set.insert(c)
    #expect(set.count == 2)
  }
}
