import Numerics
import Testing
@testable import SwiftGeographic

@Suite("MGRSCoordinate Tests")
struct MGRSCoordinateTests {

  // MARK: - Parsing Known MGRS Strings

  @Test("Parse known MGRS string 18SUJ2337106519")
  func parseKnownMGRS() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .oneMeter)
    // Easting within tile: 23371
    #expect(mgrs.easting.isApproximatelyEqual(to: 23371, absoluteTolerance: 1))
    // Northing within tile: 06519
    #expect(mgrs.northing.isApproximatelyEqual(to: 06519, absoluteTolerance: 1))
  }

  @Test("Parse MGRS at 100km precision (zone only)")
  func parse100kmPrecision() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .hundredKilometer)
  }

  @Test("Parse MGRS at 10km precision")
  func parse10kmPrecision() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ20")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .tenKilometer)
  }

  @Test("Parse MGRS at 1km precision")
  func parse1kmPrecision() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2306")
    #expect(mgrs.gridZone == "18S")
    #expect(mgrs.squareIdentifier == "UJ")
    #expect(mgrs.precision == .oneKilometer)
  }

  @Test("Parse MGRS at 100m precision")
  func parse100mPrecision() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ233065")
    #expect(mgrs.precision == .hundredMeter)
  }

  @Test("Parse MGRS at 10m precision")
  func parse10mPrecision() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ23370651")
    #expect(mgrs.precision == .tenMeter)
  }

  // MARK: - Round Trip (Parse then Regenerate)

  @Test("Round trip: parse then regenerate MGRS string at 1m precision")
  func roundTrip1m() throws {
    let original = "18SUJ2337106519"
    let mgrs = try MGRSCoordinate(string: original)
    let regenerated = mgrs.gridReference
    #expect(regenerated == original, "Regenerated MGRS should match original")
  }

  @Test("Round trip: parse then regenerate at 1km precision")
  func roundTrip1km() throws {
    let original = "18SUJ2306"
    let mgrs = try MGRSCoordinate(string: original)
    let regenerated = mgrs.gridReference
    #expect(regenerated == original, "Regenerated MGRS should match original")
  }

  @Test("Round trip: geographic to MGRS to geographic")
  func geoToMGRSToGeo() throws {
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

  @Test("Empty string throws invalidMGRS")
  func emptyString() {
    #expect(throws: SwiftGeographicError.invalidMGRS("")) {
      try MGRSCoordinate(string: "")
    }
  }

  @Test("Odd digit count throws invalidMGRS")
  func oddDigits() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18SUJ123")
    }
  }

  @Test("Invalid band letter throws invalidMGRS")
  func invalidBandLetter() {
    // 'I' is not used in MGRS (military alphabet skips I and O)
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18IUJ2337106519")
    }
  }

  @Test("Zone 99 with invalid band throws")
  func invalidZone99() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "99XUJ2337106519")
    }
  }

  // MARK: - UPS MGRS Strings (Polar)

  @Test("Parse UPS MGRS string starting with Z (north-east)")
  func parseUPSNorthEast() throws {
    // Generate a known UPS MGRS string
    let coord = try GeographicCoordinate(latitude: 85, longitude: 10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar, "UPS MGRS should be polar")
  }

  @Test("Parse UPS MGRS string starting with Y (north-west)")
  func parseUPSNorthWest() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: -10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    let first = mgrs.gridReference.first!
    #expect(first == "Y", "North-west UPS should start with Y")
  }

  @Test("Parse UPS MGRS string starting with B (south-east)")
  func parseUPSSouthEast() throws {
    let coord = try GeographicCoordinate(latitude: -85, longitude: 10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    let first = mgrs.gridReference.first!
    #expect(first == "B", "South-east UPS should start with B")
  }

  @Test("Parse UPS MGRS string starting with A (south-west)")
  func parseUPSSouthWest() throws {
    let coord = try GeographicCoordinate(latitude: -85, longitude: -10)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    let first = mgrs.gridReference.first!
    #expect(first == "A", "South-west UPS should start with A")
  }

  // MARK: - gridReference Property

  @Test("gridReference returns correct string")
  func gridReferenceProperty() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    // Re-parse and verify gridReference round-trips
    let reparsed = try MGRSCoordinate(string: mgrs.gridReference)
    #expect(reparsed.gridReference == mgrs.gridReference)
  }

  // MARK: - isPolar Property

  @Test("isPolar is true for UPS coordinates")
  func isPolarTrue() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar == true)
  }

  @Test("isPolar is false for UTM coordinates")
  func isPolarFalse() throws {
    let coord = try GeographicCoordinate(latitude: 40, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar == false)
  }

  // MARK: - UTM/UPS Conversion from MGRS

  @Test("Non-polar MGRS converts to UTM coordinate")
  func mgrsToUTM() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    let utm = try mgrs.utm
    #expect(utm.zone == 18)
    // Band S covers 32-40°N, so hemisphere is north
    #expect(utm.hemisphere == .north)
  }

  @Test("Polar MGRS utm property throws invalidZone")
  func polarMGRSToUTMThrows() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      _ = try mgrs.utm
    }
  }

  @Test("Polar MGRS converts to UPS coordinate")
  func polarMGRSToUPS() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    let ups = try mgrs.ups
    #expect(ups.hemisphere == .north)
  }

  @Test("Non-polar MGRS ups property throws outOfRange")
  func nonPolarMGRSToUPSThrows() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(throws: SwiftGeographicError.outOfRange) {
      _ = try mgrs.ups
    }
  }

  // MARK: - Case Insensitivity

  @Test("MGRS parsing is case insensitive")
  func caseInsensitive() throws {
    let upper = try MGRSCoordinate(string: "18SUJ2337106519")
    let lower = try MGRSCoordinate(string: "18suj2337106519")
    #expect(upper.gridReference == lower.gridReference)
  }

  // MARK: - Geographic Conversion

  @Test("MGRS geographic property returns center of grid cell")
  func mgrsGeographic() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    let geo = try mgrs.geographic
    #expect(geo.latitude >= -90 && geo.latitude <= 90)
    #expect(geo.longitude >= -180 && geo.longitude <= 180)
  }
}
