import Numerics
import Testing
@testable import SwiftGeographic

@Suite
struct `Error Tests` {

  // MARK: - Invalid Latitude

  @Test
  func `Latitude 91 throws invalidLatitude`() {
    #expect(throws: SwiftGeographicError.invalidLatitude(91)) {
      try GeographicCoordinate(latitude: 91, longitude: 0)
    }
  }

  @Test
  func `Latitude -91 throws invalidLatitude`() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-91)) {
      try GeographicCoordinate(latitude: -91, longitude: 0)
    }
  }

  @Test
  func `Latitude NaN throws an error`() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: .nan, longitude: 0)
    }
  }

  @Test
  func `Latitude infinity throws an error`() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: .infinity, longitude: 0)
    }
  }

  @Test
  func `Latitude negative infinity throws an error`() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: -.infinity, longitude: 0)
    }
  }

  @Test
  func `Latitude 100 throws invalidLatitude`() {
    #expect(throws: SwiftGeographicError.invalidLatitude(100)) {
      try GeographicCoordinate(latitude: 100, longitude: 0)
    }
  }

  @Test
  func `Latitude -100 throws invalidLatitude`() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-100)) {
      try GeographicCoordinate(latitude: -100, longitude: 0)
    }
  }

  // MARK: - Invalid Longitude

  @Test
  func `Longitude 360 throws invalidLongitude`() {
    #expect(throws: SwiftGeographicError.invalidLongitude(360)) {
      try GeographicCoordinate(latitude: 0, longitude: 360)
    }
  }

  @Test
  func `Longitude -181 throws invalidLongitude`() {
    #expect(throws: SwiftGeographicError.invalidLongitude(-181)) {
      try GeographicCoordinate(latitude: 0, longitude: -181)
    }
  }

  @Test
  func `Longitude 500 throws invalidLongitude`() {
    #expect(throws: SwiftGeographicError.invalidLongitude(500)) {
      try GeographicCoordinate(latitude: 0, longitude: 500)
    }
  }

  @Test
  func `Longitude -200 throws invalidLongitude`() {
    #expect(throws: SwiftGeographicError.invalidLongitude(-200)) {
      try GeographicCoordinate(latitude: 0, longitude: -200)
    }
  }

  // MARK: - Valid Longitude Boundary Values

  @Test
  func `Longitude 180 is valid`() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: 180)
    #expect(coord.longitude == 180)
  }

  @Test
  func `Longitude -180 is valid`() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: -180)
    #expect(coord.longitude == -180)
  }

  // MARK: - Invalid UTM Zone

  @Test
  func `UTM zone 0 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      try UTMCoordinate(zone: 0, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test
  func `UTM zone 61 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(61)) {
      try UTMCoordinate(zone: 61, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test
  func `UTM zone -1 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(-1)) {
      try UTMCoordinate(zone: -1, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test
  func `UTM zone 100 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(100)) {
      try UTMCoordinate(zone: 100, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  // MARK: - Invalid MGRS Strings

  @Test
  func `Empty MGRS string throws invalidMGRS`() {
    #expect(throws: SwiftGeographicError.invalidMGRS("")) {
      try MGRSCoordinate(string: "")
    }
  }

  @Test
  func `MGRS string with odd digit count throws`() {
    // "18SUJ123" has 3 digits after the letters (odd)
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18SUJ123")
    }
  }

  @Test
  func `MGRS string with non-alphanumeric characters throws`() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18S@J2337106519")
    }
  }

  @Test
  func `MGRS string with zone 99 and invalid band throws`() {
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "99XUJ2337106519")
    }
  }

  @Test
  func `MGRS string with only zone number and no letters throws`() {
    // Just a number with no band letter
    #expect(throws: (any Error).self) {
      try MGRSCoordinate(string: "18")
    }
  }

  // MARK: - Invalid Zone in MGRS utm Property

  @Test
  func `MGRS.utm throws for UPS (polar) coordinate`() throws {
    // Create a polar MGRS coordinate
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    #expect(mgrs.isPolar)
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      _ = try mgrs.utm
    }
  }

  @Test
  func `MGRS.ups throws for non-polar (UTM) coordinate`() throws {
    let mgrs = try MGRSCoordinate(string: "18SUJ2337106519")
    #expect(!mgrs.isPolar)
    #expect(throws: SwiftGeographicError.outOfRange) {
      _ = try mgrs.ups
    }
  }

  // MARK: - UTMUPS Forward Error Cases

  @Test
  func `UTMUPS.forward with latitude 91 throws invalidLatitude`() {
    #expect(throws: SwiftGeographicError.invalidLatitude(91)) {
      try UTMUPS.forward(latitude: 91, longitude: 0)
    }
  }

  @Test
  func `UTMUPS.forward with latitude -91 throws invalidLatitude`() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-91)) {
      try UTMUPS.forward(latitude: -91, longitude: 0)
    }
  }

  // MARK: - UTMUPS Reverse Error Cases

  @Test
  func `UTMUPS.reverse with zone 61 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(61)) {
      try UTMUPS.reverse(zone: 61, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test
  func `UTMUPS.reverse with zone -1 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(-1)) {
      try UTMUPS.reverse(zone: -1, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  // MARK: - Error Equatability

  @Test
  func `SwiftGeographicError conforms to Equatable`() {
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

  @Test
  func `SwiftGeographicError conforms to Error`() {
    let error: any Error = SwiftGeographicError.invalidLatitude(91)
    #expect(error is SwiftGeographicError)
  }

  @Test
  func `SwiftGeographicError conforms to Sendable`() {
    let error: any Sendable = SwiftGeographicError.invalidLatitude(91)
    #expect(error is SwiftGeographicError)
  }
}
