import Numerics
import Testing
@testable import SwiftGeographic

@Suite("Error Tests")
struct ErrorTests {

  // MARK: - Invalid Latitude

  @Test("Latitude 91 throws invalidLatitude")
  func latitude91() {
    #expect(throws: SwiftGeographicError.invalidLatitude(91)) {
      try GeographicCoordinate(latitude: 91, longitude: 0)
    }
  }

  @Test("Latitude -91 throws invalidLatitude")
  func latitudeMinus91() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-91)) {
      try GeographicCoordinate(latitude: -91, longitude: 0)
    }
  }

  @Test("Latitude NaN throws an error")
  func latitudeNaN() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: .nan, longitude: 0)
    }
  }

  @Test("Latitude infinity throws an error")
  func latitudeInfinity() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: .infinity, longitude: 0)
    }
  }

  @Test("Latitude negative infinity throws an error")
  func latitudeNegativeInfinity() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: -.infinity, longitude: 0)
    }
  }

  @Test("Latitude 100 throws invalidLatitude")
  func latitude100() {
    #expect(throws: SwiftGeographicError.invalidLatitude(100)) {
      try GeographicCoordinate(latitude: 100, longitude: 0)
    }
  }

  @Test("Latitude -100 throws invalidLatitude")
  func latitudeMinus100() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-100)) {
      try GeographicCoordinate(latitude: -100, longitude: 0)
    }
  }

  // MARK: - Invalid Longitude

  @Test("Longitude 360 throws invalidLongitude")
  func longitude360() {
    #expect(throws: SwiftGeographicError.invalidLongitude(360)) {
      try GeographicCoordinate(latitude: 0, longitude: 360)
    }
  }

  @Test("Longitude -181 throws invalidLongitude")
  func longitudeMinus181() {
    #expect(throws: SwiftGeographicError.invalidLongitude(-181)) {
      try GeographicCoordinate(latitude: 0, longitude: -181)
    }
  }

  @Test("Longitude 500 throws invalidLongitude")
  func longitude500() {
    #expect(throws: SwiftGeographicError.invalidLongitude(500)) {
      try GeographicCoordinate(latitude: 0, longitude: 500)
    }
  }

  @Test("Longitude -200 throws invalidLongitude")
  func longitudeMinus200() {
    #expect(throws: SwiftGeographicError.invalidLongitude(-200)) {
      try GeographicCoordinate(latitude: 0, longitude: -200)
    }
  }

  // MARK: - Valid Longitude Boundary Values

  @Test("Longitude 180 is valid")
  func longitude180valid() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: 180)
    #expect(coord.longitude == 180)
  }

  @Test("Longitude -180 is valid")
  func longitudeMinus180valid() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: -180)
    #expect(coord.longitude == -180)
  }

  // MARK: - Invalid UTM Zone

  @Test("UTM zone 0 throws invalidZone")
  func utmZone0() {
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      try UTMCoordinate(zone: 0, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test("UTM zone 61 throws invalidZone")
  func utmZone61() {
    #expect(throws: SwiftGeographicError.invalidZone(61)) {
      try UTMCoordinate(zone: 61, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test("UTM zone -1 throws invalidZone")
  func utmZoneMinus1() {
    #expect(throws: SwiftGeographicError.invalidZone(-1)) {
      try UTMCoordinate(zone: -1, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test("UTM zone 100 throws invalidZone")
  func utmZone100() {
    #expect(throws: SwiftGeographicError.invalidZone(100)) {
      try UTMCoordinate(zone: 100, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  // MARK: - Invalid MGRS Strings

  @Test("Empty MGRS string throws invalidMGRS")
  func emptyMGRS() {
    #expect(throws: SwiftGeographicError.invalidMGRS("")) {
      try MGRSCoordinate(string: "")
    }
  }

  @Test("MGRS string with odd digit count throws")
  func oddDigitMGRS() {
    // "18SUJ123" has 3 digits after the letters (odd)
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18SUJ123")
    }
  }

  @Test("MGRS string with non-alphanumeric characters throws")
  func nonAlphanumericMGRS() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18S@J2337106519")
    }
  }

  @Test("MGRS string with zone 99 and invalid band throws")
  func zone99MGRS() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "99XUJ2337106519")
    }
  }

  @Test("MGRS string with only zone number and no letters throws")
  func zoneOnlyMGRS() {
    // Just a number with no band letter
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18")
    }
  }

  // MARK: - Invalid Zone in MGRS utm Property

  @Test("MGRS.utm throws for UPS (polar) coordinate")
  func mgrsUtmThrowsForUPS() throws {
    // Create a polar MGRS coordinate
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      _ = try mgrs.utm
    }
  }

  @Test("MGRS.ups throws for non-polar (UTM) coordinate")
  func mgrsUpsThrowsForUTM() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(!mgrs.isPolar)
    #expect(throws: SwiftGeographicError.outOfRange) {
      _ = try mgrs.ups
    }
  }

  // MARK: - UTMUPS Forward Error Cases

  @Test("UTMUPS.forward with latitude 91 throws invalidLatitude")
  func utmupsForwardLat91() {
    #expect(throws: SwiftGeographicError.invalidLatitude(91)) {
      try UTMUPS.forward(latitude: 91, longitude: 0)
    }
  }

  @Test("UTMUPS.forward with latitude -91 throws invalidLatitude")
  func utmupsForwardLatMinus91() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-91)) {
      try UTMUPS.forward(latitude: -91, longitude: 0)
    }
  }

  // MARK: - UTMUPS Reverse Error Cases

  @Test("UTMUPS.reverse with zone 61 throws invalidZone")
  func utmupsReverseZone61() {
    #expect(throws: SwiftGeographicError.invalidZone(61)) {
      try UTMUPS.reverse(zone: 61, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test("UTMUPS.reverse with zone -1 throws invalidZone")
  func utmupsReverseZoneMinus1() {
    #expect(throws: SwiftGeographicError.invalidZone(-1)) {
      try UTMUPS.reverse(zone: -1, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  // MARK: - Error Equatability

  @Test("SwiftGeographicError conforms to Equatable")
  func errorEquatable() {
    let a = SwiftGeographicError.invalidLatitude(91)
    let b = SwiftGeographicError.invalidLatitude(91)
    #expect(a == b)

    let c = SwiftGeographicError.invalidLatitude(92)
    #expect(a != c)

    let d = SwiftGeographicError.invalidZone(0)
    let e = SwiftGeographicError.invalidZone(0)
    #expect(d == e)

    let f = SwiftGeographicError.invalidMGRS("abc")
    let g = SwiftGeographicError.invalidMGRS("abc")
    #expect(f == g)

    let h = SwiftGeographicError.outOfRange
    let i = SwiftGeographicError.outOfRange
    #expect(h == i)

    let j = SwiftGeographicError.invalidUPSCoordinate
    let k = SwiftGeographicError.invalidUPSCoordinate
    #expect(j == k)
  }

  // MARK: - Error is Error Protocol

  @Test("SwiftGeographicError conforms to Error")
  func errorConformsToError() {
    let error: any Error = SwiftGeographicError.invalidLatitude(91)
    #expect(error is SwiftGeographicError)
  }

  @Test("SwiftGeographicError conforms to Sendable")
  func errorConformsToSendable() {
    let error: any Sendable = SwiftGeographicError.invalidLatitude(91)
    #expect(error is SwiftGeographicError)
  }
}
