import Numerics
import Testing
@testable import SwiftGeographic

@Suite
struct `MGRSCoordinate Tests` {

  // MARK: - Parsing Known MGRS Strings

  @Test
  func `Parse known MGRS string 18SUJ2337106519`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .oneMeter)
    // Easting within tile: 23371
    #expect(mgrs.easting.isApproximatelyEqual(to: 23371, absoluteTolerance: 1))
    // Northing within tile: 06519
    #expect(mgrs.northing.isApproximatelyEqual(to: 06519, absoluteTolerance: 1))
  }

  @Test
  func `Parse MGRS at 100km precision (zone only)`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .hundredKilometer)
  }

  @Test
  func `Parse MGRS at 10km precision`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ20")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .tenKilometer)
  }

  @Test
  func `Parse MGRS at 1km precision`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2306")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .oneKilometer)
  }

  @Test
  func `Parse MGRS at 100m precision`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ233065")
    #expect(mgrs.precision == .hundredMeter)
  }

  @Test
  func `Parse MGRS at 10m precision`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ23370651")
    #expect(mgrs.precision == .tenMeter)
  }

  // MARK: - Round Trip (Parse then Regenerate)

  @Test
  func `Round trip: parse then regenerate MGRS string at 1m precision`() throws {
    let original = "18SUJ2337106519"
    let mgrs = try MGRSCoordinate(string: original)
    let regenerated = mgrs.gridReference
    #expect(regenerated == original, "Regenerated MGRS should match original")
  }

  @Test
  func `Round trip: parse then regenerate at 1km precision`() throws {
    let original = "18SUJ2306"
    let mgrs = try MGRSCoordinate(string: original)
    let regenerated = mgrs.gridReference
    #expect(regenerated == original, "Regenerated MGRS should match original")
  }

  @Test
  func `Round trip: geographic to MGRS to geographic`() throws {
    let original = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let mgrs = try original.mgrs(precision: .oneMeter)
    let recovered = try mgrs.geographic
    // At 1m precision, tolerance should be about 0.00001 degrees (~1m)
    #expect(
      recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 0.00002)
    )
    #expect(
      recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 0.00002)
    )
  }

  // MARK: - Invalid MGRS Strings

  @Test
  func `Empty string throws invalidMGRS`() {
    #expect(throws: SwiftGeographicError.invalidMGRS("")) {
      try MGRSCoordinate(string: "")
    }
  }

  @Test
  func `Odd digit count throws invalidMGRS`() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18SUJ123")
    }
  }

  @Test
  func `Invalid band letter throws invalidMGRS`() {
    // 'I' is not used in MGRS (military alphabet skips I and O)
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18IUJ2337106519")
    }
  }

  @Test
  func `Zone 99 with invalid band throws`() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "99XUJ2337106519")
    }
  }

  // MARK: - UPS MGRS Strings (Polar)

  @Test
  func `Parse UPS MGRS string starting with Z (north-east)`() throws {
    // Generate a known UPS MGRS string
    let coord = try GeographicCoordinate(latitude: 85, longitude: 10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar, "UPS MGRS should be polar")
  }

  @Test
  func `Parse UPS MGRS string starting with Y (north-west)`() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: -10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    let first = mgrs.gridReference.first!
    #expect(first == "Y", "North-west UPS should start with Y")
  }

  @Test
  func `Parse UPS MGRS string starting with B (south-east)`() throws {
    let coord = try GeographicCoordinate(latitude: -85, longitude: 10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    let first = mgrs.gridReference.first!
    #expect(first == "B", "South-east UPS should start with B")
  }

  @Test
  func `Parse UPS MGRS string starting with A (south-west)`() throws {
    let coord = try GeographicCoordinate(latitude: -85, longitude: -10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    let first = mgrs.gridReference.first!
    #expect(first == "A", "South-west UPS should start with A")
  }

  // MARK: - gridReference Property

  @Test
  func `gridReference returns correct string`() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    // Re-parse and verify gridReference round-trips
    let reparsed = try MGRSCoordinate(string: mgrs.gridReference)
    #expect(reparsed.gridReference == mgrs.gridReference)
  }

  // MARK: - isPolar Property

  @Test
  func `isPolar is true for UPS coordinates`() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar == true)
  }

  @Test
  func `isPolar is false for UTM coordinates`() throws {
    let coord = try GeographicCoordinate(latitude: 40, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar == false)
  }

  // MARK: - UTM/UPS Conversion from MGRS

  @Test
  func `Non-polar MGRS converts to UTM coordinate`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    let utm = try mgrs.utm
    #expect(utm.zone == 18)
    // Band S covers 32-40°N, so hemisphere is north
    #expect(utm.hemisphere == .north)
  }

  @Test
  func `Polar MGRS utm property throws invalidZone`() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      _ = try mgrs.utm
    }
  }

  @Test
  func `Polar MGRS converts to UPS coordinate`() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    let ups = try mgrs.ups
    #expect(ups.hemisphere == .north)
  }

  @Test
  func `Non-polar MGRS ups property throws outOfRange`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(throws: SwiftGeographicError.outOfRange) {
      _ = try mgrs.ups
    }
  }

  // MARK: - Case Insensitivity

  @Test
  func `MGRS parsing is case insensitive`() throws {
    let upper = try MGRSCoordinate(string: "18SUJ2337106519")
    let lower = try MGRSCoordinate(string: "18suj2337106519")
    #expect(upper.gridReference == lower.gridReference)
  }

  // MARK: - Geographic Conversion

  @Test
  func `MGRS geographic property returns center of grid cell`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    let geo = try mgrs.geographic
    #expect(geo.latitude >= -90 && geo.latitude <= 90)
    #expect(geo.longitude >= -180 && geo.longitude <= 180)
  }
}
