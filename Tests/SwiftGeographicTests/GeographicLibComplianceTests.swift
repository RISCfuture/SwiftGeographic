import Numerics
import Testing
@testable import SwiftGeographic

/// Validates against known-good test vectors from GeographicLib's CTest suite,
/// NGA standards, and Karney's publications.
///
/// Sources:
/// - GeographicLib tests/CMakeLists.txt (GeoConvert, TransverseMercatorProj)
/// - GeographicLib tests/signtest.cpp (signed-zero edge cases)
/// - NGA.STND.0037_2.0.0_GRIDS (MGRS standard)
@Suite("GeographicLib Compliance Tests")
struct GeographicLibComplianceTests {

  // MARK: - MGRS Forward (Geographic -> MGRS)

  @Test("GeoConvert0: (33.3, 44.4) -> 38SMB4484 at 1km precision")
  func mgrsForward33_44() throws {
    let coord = try GeographicCoordinate(latitude: 33.3, longitude: 44.4)
    let mgrs = try coord.mgrs(precision: .oneKilometer).gridReference
    #expect(mgrs == "38SMB4484")
  }

  @Test("MGRS at multiple precisions for (33.3, 44.4)")
  func mgrsPrecisions() throws {
    let coord = try GeographicCoordinate(latitude: 33.3, longitude: 44.4)

    let mgrs100km = try coord.mgrs(precision: .hundredKilometer).gridReference
    #expect(mgrs100km.hasPrefix("38S"))

    let mgrs10km = try coord.mgrs(precision: .tenKilometer).gridReference
    #expect(mgrs10km.hasPrefix("38SMB"))

    let mgrs1km = try coord.mgrs(precision: .oneKilometer).gridReference
    #expect(mgrs1km == "38SMB4484")

    let mgrs1m = try coord.mgrs(precision: .oneMeter).gridReference
    // 1m precision should have 10 digits after the square ID
    let digits = mgrs1m.dropFirst(5)  // drop "38SMB"
    #expect(digits.count == 10)
  }

  // MARK: - MGRS Reverse (MGRS -> Geographic)

  @Test("GeoConvert1: 38SMB -> approximately (33, 44.5)")
  func mgrsReverse38SMB() throws {
    let mgrs = try MGRSCoordinate(string: "38SMB")
    let geo = try mgrs.geographic
    // 100km precision: center of grid cell
    #expect(geo.latitude.isApproximatelyEqual(to: 33.0, absoluteTolerance: 0.5))
    #expect(geo.longitude.isApproximatelyEqual(to: 44.5, absoluteTolerance: 0.5))
  }

  // MARK: - UTM/UPS Known Points from GeographicLib

  @Test("GeoConvert8: (86, 0) -> UPS north, easting 2000000, northing ~1555731.57")
  func upsNorth86() throws {
    let coord = try GeographicCoordinate(latitude: 86, longitude: 0)
    let ups = try coord.ups
    #expect(ups.hemisphere == .north)
    #expect(ups.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1))
    #expect(ups.northing.isApproximatelyEqual(to: 1_555_731.570643, absoluteTolerance: 0.001))
  }

  // MARK: - TransverseMercator Known Points from GeographicLib CTest

  @Test("TMProj0: (90, 75) with k0=1 -> easting 0, northing 10001965.7293")
  func tmPoleForwardK1() {
    let tm = TransverseMercator(
      semiMajorAxis: Constants.wgs84A,
      flattening: Constants.wgs84F,
      centralScale: 1.0
    )
    let result = tm.forward(centralMeridian: 0, latitude: 90, longitude: 75)
    #expect(result.x.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6))
    #expect(result.y.isApproximatelyEqual(to: 10_001_965.7293, absoluteTolerance: 0.001))
    #expect(result.convergence.isApproximatelyEqual(to: 75, absoluteTolerance: 1e-6))
    #expect(result.scale.isApproximatelyEqual(to: 1.0, absoluteTolerance: 1e-6))
  }

  @Test("TMProj2: reverse (0, 10001965.7293127228) with k0=1 -> (90, 0)")
  func tmPoleReverseK1() {
    let tm = TransverseMercator(
      semiMajorAxis: Constants.wgs84A,
      flattening: Constants.wgs84F,
      centralScale: 1.0
    )
    let result = tm.reverse(
      centralMeridian: 0,
      easting: 0,
      northing: 10_001_965.7293127228
    )
    #expect(result.x.isApproximatelyEqual(to: 90, absoluteTolerance: 1e-6))
  }

  @Test(
    "TMProj4: (20, 30) on ellipsoid a=6.4e6, f=1/150 -> (3266035.453860, 2518371.552676)"
  )
  func tmNonWGS84Forward() {
    let tm = TransverseMercator(
      semiMajorAxis: 6.4e6,
      flattening: 1.0 / 150,
      centralScale: 0.9996
    )
    let result = tm.forward(centralMeridian: 0, latitude: 20, longitude: 30)
    #expect(result.x.isApproximatelyEqual(to: 3_266_035.453860, absoluteTolerance: 0.001))
    #expect(result.y.isApproximatelyEqual(to: 2_518_371.552676, absoluteTolerance: 0.001))
    #expect(
      result.convergence.isApproximatelyEqual(to: 11.207356502141, absoluteTolerance: 1e-6)
    )
    #expect(result.scale.isApproximatelyEqual(to: 1.134138960741, absoluteTolerance: 1e-6))
  }

  @Test(
    "TMProj6: reverse (3.3e6, 2.5e6) on ellipsoid a=6.4e6, f=1/150 -> (19.8037, 30.2492)"
  )
  func tmNonWGS84Reverse() {
    let tm = TransverseMercator(
      semiMajorAxis: 6.4e6,
      flattening: 1.0 / 150,
      centralScale: 0.9996
    )
    let result = tm.reverse(centralMeridian: 0, easting: 3.3e6, northing: 2.5e6)
    #expect(result.x.isApproximatelyEqual(to: 19.80370996793, absoluteTolerance: 1e-6))
    #expect(result.y.isApproximatelyEqual(to: 30.24919702282, absoluteTolerance: 1e-6))
    #expect(
      result.convergence.isApproximatelyEqual(to: 11.214378172893, absoluteTolerance: 1e-6)
    )
    #expect(result.scale.isApproximatelyEqual(to: 1.137025775759, absoluteTolerance: 1e-6))
  }

  // MARK: - MGRS from UTM Coordinates (GeographicLib GeoConvert16-18)

  @Test("GeoConvert16: UTM 38N (444140.6, 3684706.3) -> MGRS square letters MB")
  func mgrsFromUTMSquareLetters() throws {
    let utm = try UTMCoordinate(
      zone: 38,
      hemisphere: .north,
      easting: 444140.6,
      northing: 3684706.3
    )
    let mgrs = try utm.mgrs(precision: .oneMeter).gridReference
    // Verify zone, band, and square letters are correct
    #expect(mgrs.hasPrefix("38SMB"))
  }

  @Test("GeoConvert17: UTM 38N (500000, 63.811) -> MGRS band N, square NF")
  func mgrsNearEquatorSquareLetters() throws {
    let utm = try UTMCoordinate(
      zone: 38,
      hemisphere: .north,
      easting: 500000,
      northing: 63.811
    )
    let mgrs = try utm.mgrs(precision: .oneMeter).gridReference
    // GeographicLib: 38NNF... (band N, column N, row F)
    #expect(mgrs.hasPrefix("38NNF"))
  }

  // MARK: - UPS MGRS (GeographicLib GeoConvert19-21)

  @Test("UPS south (2746000, 1515000) MGRS starts with B (south-east)")
  func upsMGRS() throws {
    let ups = try UPSCoordinate(
      hemisphere: .south,
      easting: 2_746_000,
      northing: 1_515_000
    )
    let mgrs = ups.mgrs(precision: .oneMeter).gridReference
    #expect(mgrs.hasPrefix("B"), "South-east UPS should start with B, got \(mgrs)")
  }

  // MARK: - Equator Sign Convention (from signtest.cpp)

  @Test("Signed-zero equator: +0.0 lat -> northern hemisphere, band N")
  func signedZeroNorth() throws {
    let result = try UTMUPS.forward(latitude: +0.0, longitude: 3)
    #expect(result.hemisphere == .north)
    #expect(result.zone == 31)
    #expect(result.northing.isApproximatelyEqual(to: 0, absoluteTolerance: 1))
  }

  // MARK: - UTM/UPS Boundary Points

  @Test("Exact boundary: lat=84 is UPS, lat=83.9999 is UTM")
  func utmUpsBoundaryNorth() throws {
    let upsResult = try UTMUPS.forward(latitude: 84, longitude: 15)
    #expect(upsResult.zone == 0)

    let utmResult = try UTMUPS.forward(latitude: 83.9999, longitude: 15)
    #expect(utmResult.zone > 0)
  }

  @Test("Exact boundary: lat=-80 is UPS, lat=-79.9999 is UTM")
  func utmUpsBoundarySouth() throws {
    let upsResult = try UTMUPS.forward(latitude: -80, longitude: 15)
    #expect(upsResult.zone == 0)

    let utmResult = try UTMUPS.forward(latitude: -79.9999, longitude: 15)
    #expect(utmResult.zone > 0)
  }

  // MARK: - Pole Projections

  @Test("North pole UPS is exactly (2000000, 2000000)")
  func northPoleUPS() throws {
    let result = try UTMUPS.forward(latitude: 90, longitude: 0)
    #expect(result.zone == 0)
    #expect(result.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6))
    #expect(result.northing.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6))
  }

  @Test("South pole UPS is exactly (2000000, 2000000)")
  func southPoleUPS() throws {
    let result = try UTMUPS.forward(latitude: -90, longitude: 0)
    #expect(result.zone == 0)
    #expect(result.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6))
    #expect(result.northing.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6))
  }

  @Test("North pole at various longitudes all project to same UPS point")
  func northPoleAllLongitudes() throws {
    let longitudes = [0.0, 45, 90, 135, -45, -90, -135, 179]
    for lon in longitudes {
      let result = try UTMUPS.forward(latitude: 90, longitude: lon)
      #expect(
        result.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6),
        "North pole easting at lon=\(lon)"
      )
      #expect(
        result.northing.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6),
        "North pole northing at lon=\(lon)"
      )
    }
  }

  // MARK: - TM Meridional Arc Length (from GeographicLib)

  @Test("Meridional arc from equator to pole with k0=1 is ~10001965.7293 m")
  func meridionalArcToPole() {
    let tm = TransverseMercator(
      semiMajorAxis: Constants.wgs84A,
      flattening: Constants.wgs84F,
      centralScale: 1.0
    )
    let result = tm.forward(centralMeridian: 0, latitude: 90, longitude: 0)
    // GeographicLib reference value for quarter meridian
    #expect(result.y.isApproximatelyEqual(to: 10_001_965.729312723, absoluteTolerance: 1e-6))
  }

  // MARK: - Norway and Svalbard MGRS Zones

  @Test("Norway exception: Bergen (60.39, 5.32) is in MGRS zone 32V, not 31V")
  func norwayMGRS() throws {
    let coord = try GeographicCoordinate(latitude: 60.39, longitude: 5.32)
    let mgrs = try coord.mgrs(precision: .oneKilometer).gridReference
    #expect(mgrs.hasPrefix("32V"), "Bergen should be in zone 32V, got \(mgrs)")
  }

  @Test("Svalbard exception: Longyearbyen (78.22, 15.65) is in MGRS zone 33X")
  func svalbardMGRS() throws {
    let coord = try GeographicCoordinate(latitude: 78.22, longitude: 15.65)
    let mgrs = try coord.mgrs(precision: .oneKilometer).gridReference
    #expect(mgrs.hasPrefix("33X"), "Longyearbyen should be in zone 33X, got \(mgrs)")
  }

  // MARK: - Well-Known Geographic Locations

  @Test("Washington Monument (38.8895, -77.0353) MGRS reference")
  func washingtonMonument() throws {
    let coord = try GeographicCoordinate(latitude: 38.8895, longitude: -77.0353)
    let mgrs = try coord.mgrs(precision: .oneMeter)
    // Should be in zone 18S, square UJ
    #expect(mgrs.gridReference.hasPrefix("18S"))
    // Round-trip should recover to within 1m precision (~0.00001 degrees)
    let recovered = try mgrs.geographic
    #expect(
      recovered.latitude.isApproximatelyEqual(to: 38.8895, absoluteTolerance: 0.00002)
    )
    #expect(
      recovered.longitude.isApproximatelyEqual(to: -77.0353, absoluteTolerance: 0.00002)
    )
  }

  @Test("Equator/prime meridian (0, 0) MGRS is in zone 31N")
  func originMGRS() throws {
    let coord = try GeographicCoordinate(latitude: 0, longitude: 0)
    let mgrs = try coord.mgrs(precision: .oneKilometer).gridReference
    #expect(mgrs.hasPrefix("31N"), "Origin should be in zone 31N, got \(mgrs)")
  }
}
