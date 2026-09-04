import Numerics
import Testing
@testable import SwiftGeographic

@Suite
struct `UTMUPS Tests` {

  // MARK: - Standard Zone Determination

  @Test
  func `Standard zone for typical coordinates`() {
    // New York City: zone 18
    #expect(UTMUPS.standardZone(latitude: 40.7128, longitude: -74.006) == 18)
    // London: zone 30
    #expect(UTMUPS.standardZone(latitude: 51.5074, longitude: -0.1278) == 30)
    // Sydney: zone 56
    #expect(UTMUPS.standardZone(latitude: -33.8688, longitude: 151.2093) == 56)
    // Tokyo: zone 54
    #expect(UTMUPS.standardZone(latitude: 35.6762, longitude: 139.6503) == 54)
    // Origin (0, 0): zone 31
    #expect(UTMUPS.standardZone(latitude: 0, longitude: 0) == 31)
  }

  @Test
  func `Standard zone at western edge of zone 1 (longitude -180)`() {
    #expect(UTMUPS.standardZone(latitude: 0, longitude: -180) == 1)
  }

  // MARK: - Norway Exception

  @Test
  func `Norway exception: (60, 5) should be zone 32`() {
    // Normally lon=5 would be zone 31 (3W to 3E -> actually lon 0..6 is zone 31)
    // But Norway exception moves (56-64N, lon >= 3) from zone 31 to zone 32
    #expect(UTMUPS.standardZone(latitude: 60, longitude: 5) == 32)
  }

  @Test
  func `Norway exception does not apply below 56N`() {
    // At latitude 55 (below the Norway exception range), lon=5 is zone 31
    #expect(UTMUPS.standardZone(latitude: 55, longitude: 5) == 31)
  }

  @Test
  func `Norway exception does not apply at or above 64N`() {
    // At latitude 64, the Norway exception for band V no longer applies
    #expect(UTMUPS.standardZone(latitude: 64, longitude: 5) == 31)
  }

  // MARK: - Svalbard Exceptions

  @Test
  func `Svalbard exception: (75, 10) should be zone 33`() {
    #expect(UTMUPS.standardZone(latitude: 75, longitude: 10) == 33)
  }

  @Test
  func `Svalbard exception: (75, 25) should be zone 35`() {
    #expect(UTMUPS.standardZone(latitude: 75, longitude: 25) == 35)
  }

  @Test
  func `Svalbard exception: (75, 35) should be zone 37`() {
    #expect(UTMUPS.standardZone(latitude: 75, longitude: 35) == 37)
  }

  @Test
  func `Svalbard exception: (75, 5) should be zone 31`() {
    #expect(UTMUPS.standardZone(latitude: 75, longitude: 5) == 31)
  }

  @Test
  func `Svalbard exception does not apply below 72N`() {
    #expect(UTMUPS.standardZone(latitude: 71, longitude: 10) != 33)
  }

  // MARK: - UPS for Polar Regions

  @Test
  func `UPS zone 0 for north polar (85N)`() {
    #expect(UTMUPS.standardZone(latitude: 85, longitude: 0) == 0)
  }

  @Test
  func `UPS zone 0 for south polar (-85S)`() {
    #expect(UTMUPS.standardZone(latitude: -85, longitude: 0) == 0)
  }

  @Test
  func `UPS zone 0 at exactly 84N`() {
    #expect(UTMUPS.standardZone(latitude: 84, longitude: 0) == 0)
  }

  @Test
  func `UTM zone for latitude just below 84N`() {
    #expect(UTMUPS.standardZone(latitude: 83.99, longitude: 0) != 0)
  }

  @Test
  func `UPS zone 0 at exactly -80S`() {
    #expect(UTMUPS.standardZone(latitude: -80, longitude: 0) == 0)
  }

  @Test
  func `UTM zone for latitude just above -80`() {
    #expect(UTMUPS.standardZone(latitude: -79.99, longitude: 0) != 0)
  }

  // MARK: - Central Meridian

  @Test
  func `Central meridian for zone 1 is -177`() {
    #expect(UTMUPS.centralMeridian(zone: 1).isApproximatelyEqual(to: -177, absoluteTolerance: 1e-6))
  }

  @Test
  func `Central meridian for zone 30 is -3`() {
    #expect(UTMUPS.centralMeridian(zone: 30).isApproximatelyEqual(to: -3, absoluteTolerance: 1e-6))
  }

  @Test
  func `Central meridian for zone 31 is 3`() {
    #expect(UTMUPS.centralMeridian(zone: 31).isApproximatelyEqual(to: 3, absoluteTolerance: 1e-6))
  }

  @Test
  func `Central meridian for zone 60 is 177`() {
    #expect(UTMUPS.centralMeridian(zone: 60).isApproximatelyEqual(to: 177, absoluteTolerance: 1e-6))
  }

  // MARK: - Forward/Reverse Round Trip

  @Test
  func `Forward-reverse round trip for UTM coordinates`() throws {
    let testPoints: [(lat: Double, lon: Double)] = [
      (0, 0),
      (40.7128, -74.006),
      (51.5074, -0.1278),
      (-33.8688, 151.2093),
      (60, 5),
      (75, 25),
      (-45, 170),
      (30, -90)
    ]
    for point in testPoints {
      let result = try UTMUPS.forward(latitude: point.lat, longitude: point.lon)
      let (lat, lon) = try UTMUPS.reverse(
        zone: result.zone,
        hemisphere: result.hemisphere,
        easting: result.easting,
        northing: result.northing
      )
      #expect(
        lat.isApproximatelyEqual(to: point.lat, absoluteTolerance: 1e-9),
        "Round-trip latitude failed for (\(point.lat), \(point.lon))"
      )
      #expect(
        lon.isApproximatelyEqual(to: point.lon, absoluteTolerance: 1e-9),
        "Round-trip longitude failed for (\(point.lat), \(point.lon))"
      )
    }
  }

  @Test
  func `Forward-reverse round trip for UPS coordinates`() throws {
    let testPoints: [(lat: Double, lon: Double)] = [
      (85, 0),
      (85, 45),
      (85, -90),
      (89, 100),
      (-85, 0),
      (-85, 45),
      (-85, -90),
      (-89, 100)
    ]
    for point in testPoints {
      let result = try UTMUPS.forward(latitude: point.lat, longitude: point.lon)
      #expect(result.zone == 0, "Polar point should use UPS zone 0")
      let (lat, lon) = try UTMUPS.reverse(
        zone: result.zone,
        hemisphere: result.hemisphere,
        easting: result.easting,
        northing: result.northing
      )
      #expect(
        lat.isApproximatelyEqual(to: point.lat, absoluteTolerance: 1e-9),
        "Round-trip latitude failed for (\(point.lat), \(point.lon))"
      )
      #expect(
        lon.isApproximatelyEqual(to: point.lon, absoluteTolerance: 1e-9),
        "Round-trip longitude failed for (\(point.lat), \(point.lon))"
      )
    }
  }

  // MARK: - Forward Projection Results

  @Test
  func `Forward UTM includes false easting of 500000`() throws {
    let result = try UTMUPS.forward(latitude: 0, longitude: 3)
    // At the central meridian of zone 31 (lon=3), easting should be 500000
    #expect(result.easting.isApproximatelyEqual(to: 500000, absoluteTolerance: 1))
  }

  @Test
  func `Forward UPS includes false easting/northing of 2000000`() throws {
    let result = try UTMUPS.forward(latitude: 90, longitude: 0)
    // North pole should have easting=2000000, northing=2000000
    #expect(result.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1))
    #expect(result.northing.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1))
  }

  @Test
  func `Forward with forced zone overrides automatic zone`() throws {
    // Force zone 32 for a point normally in zone 31
    let result = try UTMUPS.forward(latitude: 0, longitude: 3, zone: 32)
    #expect(result.zone == 32)
  }

  // MARK: - Error Cases

  @Test
  func `Forward with invalid latitude throws`() throws {
    #expect(throws: SwiftGeographicError.invalidLatitude(91)) {
      try UTMUPS.forward(latitude: 91, longitude: 0)
    }
    #expect(throws: SwiftGeographicError.invalidLatitude(-91)) {
      try UTMUPS.forward(latitude: -91, longitude: 0)
    }
  }

  @Test
  func `Reverse with invalid zone throws`() throws {
    #expect(throws: SwiftGeographicError.invalidZone(61)) {
      try UTMUPS.reverse(zone: 61, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  // MARK: - Zone Boundary Edge Cases

  @Test
  func `Points near zone boundary between zones 30 and 31`() throws {
    let west = try GeographicCoordinate(latitude: 45, longitude: -0.1)
    let utmWest = try west.utm
    #expect(utmWest.zone == 30)

    let east = try GeographicCoordinate(latitude: 45, longitude: 0.1)
    let utmEast = try east.utm
    #expect(utmEast.zone == 31)
  }

  @Test
  func `Points near zone boundary between zones 1 and 60`() throws {
    let west = try GeographicCoordinate(latitude: 45, longitude: -179)
    let utmWest = try west.utm
    #expect(utmWest.zone == 1)

    let east = try GeographicCoordinate(latitude: 45, longitude: 179)
    let utmEast = try east.utm
    #expect(utmEast.zone == 60)
  }

  // MARK: - Band Boundary Edge Cases

  @Test
  func `Latitude band boundaries produce valid UTM conversions`() throws {
    let bandBoundaryLatitudes: [Double] = [
      -80, -72, -64, -56, -48, -40, -32, -24, -16, -8,
      0, 8, 16, 24, 32, 40, 48, 56, 64, 72
    ]
    for lat in bandBoundaryLatitudes {
      let testLat = lat == -80 ? -79.99 : lat
      let coord = try GeographicCoordinate(latitude: testLat, longitude: 15)
      let utm = try coord.utm
      let recovered = try utm.geographic
      #expect(
        recovered.latitude.isApproximatelyEqual(to: testLat, absoluteTolerance: 1e-6),
        "Band boundary round-trip failed at lat=\(testLat)"
      )
    }
  }

  @Test
  func `Upper UTM limit at latitude 83.99`() throws {
    let coord = try GeographicCoordinate(latitude: 83.99, longitude: 15)
    let utm = try coord.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: 83.99, absoluteTolerance: 1e-4))
  }

  @Test
  func `Lower UTM limit at latitude -79.99`() throws {
    let coord = try GeographicCoordinate(latitude: -79.99, longitude: 15)
    let utm = try coord.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: -79.99, absoluteTolerance: 1e-4))
  }

  // MARK: - Norway/Svalbard Boundary Edge Cases

  @Test
  func `Norway exception boundary: lat=56, lon=3 (start of exception range)`() {
    #expect(UTMUPS.standardZone(latitude: 56, longitude: 3) == 32)
  }

  @Test
  func `Norway exception boundary: lat=55.99, lon=3 (just below)`() {
    #expect(UTMUPS.standardZone(latitude: 55.99, longitude: 3) == 31)
  }

  @Test
  func `Norway exception boundary: lat=63.99, lon=3 (just inside)`() {
    #expect(UTMUPS.standardZone(latitude: 63.99, longitude: 3) == 32)
  }

  @Test
  func `Svalbard boundary: lat=72, lon=9 (start of zone 33 exception)`() {
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 9) == 33)
  }

  @Test
  func `Svalbard boundary: lat=71.99, lon=9 (just below)`() {
    let zone = UTMUPS.standardZone(latitude: 71.99, longitude: 9)
    #expect(zone != 33, "Below 72N should not use Svalbard exception")
  }

  @Test
  func `Svalbard boundary: lon=21 is zone 35, lon=20 is zone 33`() {
    #expect(UTMUPS.standardZone(latitude: 75, longitude: 21) == 35)
    #expect(UTMUPS.standardZone(latitude: 75, longitude: 20) == 33)
  }

  // MARK: - UTM/UPS Transition Edge Cases

  @Test
  func `Transition from UTM to UPS at north boundary`() throws {
    let utmResult = try UTMUPS.forward(latitude: 83.99, longitude: 15)
    #expect(utmResult.zone > 0, "83.99N should be UTM")

    let upsResult = try UTMUPS.forward(latitude: 84, longitude: 15)
    #expect(upsResult.zone == 0, "84N should be UPS")
  }

  @Test
  func `Transition from UTM to UPS at south boundary`() throws {
    let utmResult = try UTMUPS.forward(latitude: -79.99, longitude: 15)
    #expect(utmResult.zone > 0, "-79.99 should be UTM")

    let upsResult = try UTMUPS.forward(latitude: -80, longitude: 15)
    #expect(upsResult.zone == 0, "-80 should be UPS")
  }
}
