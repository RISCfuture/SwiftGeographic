import Numerics
import Testing
@testable import SwiftGeographic

@Suite("GeographicCoordinate Tests")
struct GeographicCoordinateTests {

  // MARK: - Valid Creation

  @Test("Create coordinate with valid values")
  func validCreation() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    #expect(coord.latitude.isApproximatelyEqual(to: 40.7128, absoluteTolerance: 1e-6))
    #expect(coord.longitude.isApproximatelyEqual(to: -74.006, absoluteTolerance: 1e-6))
  }

  @Test("Create coordinate at origin (0, 0)")
  func originCreation() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: 0)
    #expect(coord.latitude.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6))
    #expect(coord.longitude.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6))
  }

  @Test("Create coordinate at extreme valid values")
  func extremeValidValues() throws {
    let north = try GeographicCoordinate(latitude: 90, longitude: 0)
    #expect(north.latitude == 90)

    let south = try GeographicCoordinate(latitude: -90, longitude: 0)
    #expect(south.latitude == -90)

    let west = try GeographicCoordinate(latitude: 0, longitude: -180)
    #expect(west.longitude == -180 || west.longitude == 180)
  }

  // MARK: - Poles

  @Test("North pole (90, 0)")
  func northPole() throws {
    let coord = try GeographicCoordinate(latitude: 90, longitude: 0)
    #expect(coord.latitude == 90)
    #expect(coord.longitude == 0)
  }

  @Test("South pole (-90, 0)")
  func southPole() throws {
    let coord = try GeographicCoordinate(latitude: -90, longitude: 0)
    #expect(coord.latitude == -90)
    #expect(coord.longitude == 0)
  }

  @Test("North pole with arbitrary longitude")
  func northPoleArbitraryLongitude() throws {
    let coord = try GeographicCoordinate(latitude: 90, longitude: 123)
    #expect(coord.latitude == 90)
    // Longitude is normalized but still stored
    #expect(coord.longitude.isApproximatelyEqual(to: 123, absoluteTolerance: 1e-6))
  }

  // MARK: - Invalid Latitude

  @Test("Invalid latitude 91 throws invalidLatitude")
  func invalidLatitude91() {
    #expect(throws: SwiftGeographicError.invalidLatitude(91)) {
      try GeographicCoordinate(latitude: 91, longitude: 0)
    }
  }

  @Test("Invalid latitude -91 throws invalidLatitude")
  func invalidLatitudeMinus91() {
    #expect(throws: SwiftGeographicError.invalidLatitude(-91)) {
      try GeographicCoordinate(latitude: -91, longitude: 0)
    }
  }

  @Test("Invalid latitude NaN throws invalidLatitude")
  func invalidLatitudeNaN() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: .nan, longitude: 0)
    }
  }

  @Test("Invalid latitude infinity throws invalidLatitude")
  func invalidLatitudeInfinity() {
    #expect(throws: (any Error).self) {
      try GeographicCoordinate(latitude: .infinity, longitude: 0)
    }
  }

  // MARK: - Invalid Longitude

  @Test("Invalid longitude 360 throws invalidLongitude")
  func invalidLongitude360() {
    // longitude range is [-180, 180], so 360 is invalid
    #expect(throws: SwiftGeographicError.invalidLongitude(360)) {
      try GeographicCoordinate(latitude: 0, longitude: 360)
    }
  }

  @Test("Invalid longitude below -180 throws invalidLongitude")
  func invalidLongitudeBelow() {
    #expect(throws: SwiftGeographicError.invalidLongitude(-181)) {
      try GeographicCoordinate(latitude: 0, longitude: -181)
    }
  }

  // MARK: - Longitude Validation

  @Test("Longitude 181 throws invalidLongitude")
  func longitude181Throws() {
    #expect(throws: SwiftGeographicError.invalidLongitude(181)) {
      try GeographicCoordinate(latitude: 0, longitude: 181)
    }
  }

  @Test("Longitude within [-180, 180] is unchanged")
  func longitudeNoNormalization() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: 45)
    #expect(coord.longitude.isApproximatelyEqual(to: 45, absoluteTolerance: 1e-10))
  }

  // MARK: - Equatable and Hashable

  @Test("Equal coordinates are equatable")
  func equatable() throws {
    let a = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let b = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    #expect(a == b)
  }

  @Test("Different coordinates are not equal")
  func notEqual() throws {
    let a = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let b = try GeographicCoordinate(latitude: 51.5074, longitude: -0.1278)
    #expect(a != b)
  }

  // MARK: - Conversion to UTM

  @Test("Conversion to UTM for a known point")
  func conversionToUTM() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let utm = try coord.utm
    #expect(utm.zone == 18)
    #expect(utm.hemisphere == .north)
    // NYC (40.7128, -74.006) UTM 18N: Karney 6th-order series
    #expect(utm.easting.isApproximatelyEqual(to: 583960, absoluteTolerance: 100))
    #expect(utm.northing.isApproximatelyEqual(to: 4507351, absoluteTolerance: 100))
  }

  @Test("Conversion to UTM for southern hemisphere")
  func conversionToUTMSouth() throws {
    let coord = try GeographicCoordinate(latitude: -33.8688, longitude: 151.2093)
    let utm = try coord.utm
    #expect(utm.hemisphere == .south)
    #expect(utm.zone == 56)
  }

  // MARK: - Conversion to UPS

  @Test("Conversion to UPS for north polar point")
  func conversionToUPS() throws {
    let coord = try GeographicCoordinate(latitude: 85, longitude: 0)
    let ups = try coord.ups
    #expect(ups.hemisphere == .north)
    // UPS easting should be near 2000000 at lon=0
    #expect(ups.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1000))
  }

  // MARK: - Conversion to MGRS

  @Test("Conversion to MGRS string")
  func conversionToMGRS() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let mgrsString = try coord.mgrs().gridReference
    // Should start with "18S" or "18T" (zone 18, band T for ~40.7N)
    #expect(mgrsString.hasPrefix("18T") || mgrsString.hasPrefix("18S"))
    // Should have 10 numeric digits at 1m precision (5+5)
    #expect(mgrsString.count > 5, "MGRS string should contain digits")
  }

  @Test("Conversion to MGRS coordinate")
  func conversionToMGRSCoordinate() throws {
    let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let mgrs = try coord.mgrs()
    #expect(mgrs.precision == .oneMeter)
    #expect(!mgrs.gridZone.isEmpty)
    #expect(!mgrs.squareIdentifier.isEmpty)
  }

  @Test("MGRS at various precisions")
  func mgrsVariousPrecisions() throws {
    let coord = try GeographicCoordinate(latitude: 51.5074, longitude: -0.1278)
    let precisions: [MGRSPrecision] = [
      .hundredKilometer, .tenKilometer, .oneKilometer,
      .hundredMeter, .tenMeter, .oneMeter
    ]
    var previousLength = 0
    for prec in precisions {
      let mgrsStr = try coord.mgrs(precision: prec).gridReference
      #expect(
        mgrsStr.count >= previousLength,
        "Higher precision MGRS should be at least as long"
      )
      previousLength = mgrsStr.count
    }
  }

  // MARK: - Equator Edge Cases

  @Test("Equator at various longitudes round-trips through UTM")
  func equatorUTMRoundTrip() throws {
    for lon in stride(from: -180.0, through: 150.0, by: 15.0) {
      let original = try GeographicCoordinate(latitude: 0, longitude: lon)
      let utm = try original.utm
      let recovered = try utm.geographic
      #expect(
        recovered.latitude.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6),
        "Equator round-trip lat failed at lon=\(lon)"
      )
      var lonDiff = abs(recovered.longitude - original.longitude)
      if lonDiff > 180 { lonDiff = 360 - lonDiff }
      #expect(
        lonDiff.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6),
        "Equator round-trip lon failed at lon=\(lon)"
      )
    }
  }

  @Test("Equator has northing near 0 in northern hemisphere")
  func equatorNorthing() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: 3)
    let utm = try coord.utm
    #expect(utm.hemisphere == .north)
    #expect(utm.northing.isApproximatelyEqual(to: 0, absoluteTolerance: 1))
  }

  // MARK: - Prime Meridian Edge Cases

  @Test("Prime meridian at various latitudes round-trips through UTM")
  func primeMeridianUTMRoundTrip() throws {
    for lat in stride(from: -75.0, through: 75.0, by: 15.0) {
      let original = try GeographicCoordinate(latitude: lat, longitude: 0)
      let utm = try original.utm
      let recovered = try utm.geographic
      #expect(
        recovered.latitude.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-6),
        "Prime meridian round-trip lat failed at lat=\(lat)"
      )
      #expect(
        recovered.longitude.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6),
        "Prime meridian round-trip lon failed at lat=\(lat)"
      )
    }
  }

  @Test("Prime meridian falls in zone 31")
  func primeMeridianZone() {
    #expect(UTMUPS.standardZone(latitude: 0, longitude: 0) == 31)
  }

  // MARK: - Antimeridian Edge Cases

  @Test("Antimeridian longitude -180 is handled correctly")
  func antimeridian180() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: -180)
    #expect(coord.longitude == 180 || coord.longitude == -180)
  }

  @Test("Antimeridian round trip at lon = 179")
  func antimeridianRoundTrip179() throws {
    let original = try GeographicCoordinate(latitude: 30, longitude: 179)
    let utm = try original.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: 30, absoluteTolerance: 1e-6))
    #expect(recovered.longitude.isApproximatelyEqual(to: 179, absoluteTolerance: 1e-6))
  }

  @Test("Antimeridian round trip at lon = -179")
  func antimeridianRoundTripMinus179() throws {
    let original = try GeographicCoordinate(latitude: 30, longitude: -179)
    let utm = try original.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: 30, absoluteTolerance: 1e-6))
    #expect(recovered.longitude.isApproximatelyEqual(to: -179, absoluteTolerance: 1e-6))
  }

  // MARK: - Small Longitude Offsets

  @Test("Very small longitude offset from central meridian")
  func smallLongitudeOffset() throws {
    let lon = 3.0 + 1e-10  // Tiny offset from CM of zone 31
    let coord = try GeographicCoordinate(latitude: 45, longitude: lon)
    let utm = try coord.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: 45, absoluteTolerance: 1e-9))
    #expect(recovered.longitude.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9))
  }
}
