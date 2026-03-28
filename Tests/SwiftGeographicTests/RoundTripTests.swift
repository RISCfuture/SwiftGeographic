import Numerics
import Testing
@testable import SwiftGeographic

@Suite("Round Trip Tests")
struct RoundTripTests {

  // MARK: - Geographic -> UTM -> Geographic

  @Test("Geographic to UTM to Geographic at grid of points within UTM range")
  func geoUTMGeoGrid() throws {
    // UTM covers -80 to 84 latitude; skip -180 (antimeridian round-trips to 180)
    for lat in stride(from: -75.0, through: 75.0, by: 15.0) {
      for lon in stride(from: -150.0, through: 150.0, by: 30.0) {
        let original = try GeographicCoordinate(latitude: lat, longitude: lon)
        let utm = try original.utm
        let recovered = try utm.geographic
        #expect(
          recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 1e-6),
          "Latitude round-trip failed at (\(lat), \(lon))"
        )
        #expect(
          recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 1e-6),
          "Longitude round-trip failed at (\(lat), \(lon))"
        )
      }
    }
  }

  @Test("Geographic to UTM to Geographic near equator")
  func geoUTMGeoEquator() throws {
    for lon in stride(from: -170.0, through: 170.0, by: 10.0) {
      let original = try GeographicCoordinate(latitude: 0, longitude: lon)
      let utm = try original.utm
      let recovered = try utm.geographic
      #expect(
        recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 1e-6),
        "Equator round-trip failed at lon=\(lon)"
      )
      #expect(
        recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 1e-6),
        "Equator round-trip failed at lon=\(lon)"
      )
    }
  }

  // MARK: - Geographic -> MGRS -> Geographic

  @Test("Geographic to MGRS to Geographic at 1m precision")
  func geoMGRSGeo1m() throws {
    let testPoints: [(lat: Double, lon: Double)] = [
      (0, 0), (40.7128, -74.006), (51.5074, -0.1278),
      (-33.8688, 151.2093), (60, 5), (30, -90),
      (-45, 170), (75, 25), (10, 100)
    ]
    for point in testPoints {
      let original = try GeographicCoordinate(latitude: point.lat, longitude: point.lon)
      let mgrs = try original.mgrs(precision: .oneMeter)
      let recovered = try mgrs.geographic
      // 1m precision means ~0.00001 degrees tolerance
      #expect(
        recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 0.00002),
        "MGRS 1m round-trip latitude failed at (\(point.lat), \(point.lon))"
      )
      #expect(
        recovered.longitude.isApproximatelyEqual(
          to: original.longitude,
          absoluteTolerance: 0.00002
        ),
        "MGRS 1m round-trip longitude failed at (\(point.lat), \(point.lon))"
      )
    }
  }

  @Test("Geographic to MGRS to Geographic at 10m precision")
  func geoMGRSGeo10m() throws {
    let testPoints: [(lat: Double, lon: Double)] = [
      (0, 0), (40.7128, -74.006), (-33.8688, 151.2093)
    ]
    for point in testPoints {
      let original = try GeographicCoordinate(latitude: point.lat, longitude: point.lon)
      let mgrs = try original.mgrs(precision: .tenMeter)
      let recovered = try mgrs.geographic
      // 10m precision means ~0.0001 degrees tolerance
      #expect(
        recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 0.0002),
        "MGRS 10m round-trip latitude failed at (\(point.lat), \(point.lon))"
      )
      #expect(
        recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 0.0002),
        "MGRS 10m round-trip longitude failed at (\(point.lat), \(point.lon))"
      )
    }
  }

  @Test("Geographic to MGRS to Geographic at 100m precision")
  func geoMGRSGeo100m() throws {
    let original = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
    let mgrs = try original.mgrs(precision: .hundredMeter)
    let recovered = try mgrs.geographic
    // 100m precision means ~0.001 degrees tolerance
    #expect(
      recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 0.002)
    )
    #expect(
      recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 0.002)
    )
  }

  // MARK: - TM Forward -> Reverse at Grid of Points

  @Test("TransverseMercator forward-reverse round trip at a grid of points")
  func tmForwardReverseGrid() {
    let tm = TransverseMercator.utm
    let centralMeridians: [Double] = [-177, -75, -3, 3, 75, 177]
    let latitudes: [Double] = [-80, -60, -30, 0, 30, 60, 80]

    for cm in centralMeridians {
      for lat in latitudes {
        // Use a longitude near the central meridian (within 3 degrees)
        let lon = cm + 1.5
        let normLon = lon > 180 ? lon - 360 : (lon < -180 ? lon + 360 : lon)

        let fwd = tm.forward(centralMeridian: cm, latitude: lat, longitude: normLon)
        let rev = tm.reverse(centralMeridian: cm, easting: fwd.x, northing: fwd.y)

        #expect(
          rev.x.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9),
          "TM round-trip lat failed at CM=\(cm), lat=\(lat)"
        )
        #expect(
          rev.y.isApproximatelyEqual(to: normLon, absoluteTolerance: 1e-9),
          "TM round-trip lon failed at CM=\(cm), lon=\(normLon)"
        )
      }
    }
  }

  // MARK: - PS Forward -> Reverse at Polar Points

  @Test("PolarStereographic forward-reverse round trip at polar points")
  func psForwardReverseGrid() {
    let ps = PolarStereographic.ups

    // North pole points
    let northLatitudes: [Double] = [85, 87, 88, 89, 89.5]
    let longitudes: [Double] = [-179, -90, -45, 0, 45, 90, 135, 179]

    for lat in northLatitudes {
      for lon in longitudes {
        let fwd = ps.forward(isNorth: true, latitude: lat, longitude: lon)
        let rev = ps.reverse(isNorth: true, easting: fwd.x, northing: fwd.y)
        #expect(
          rev.x.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9),
          "PS north round-trip lat failed at (\(lat), \(lon))"
        )
        #expect(
          rev.y.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9),
          "PS north round-trip lon failed at (\(lat), \(lon))"
        )
      }
    }

    // South pole points
    let southLatitudes: [Double] = [-85, -87, -88, -89, -89.5]
    for lat in southLatitudes {
      for lon in longitudes {
        let fwd = ps.forward(isNorth: false, latitude: lat, longitude: lon)
        let rev = ps.reverse(isNorth: false, easting: fwd.x, northing: fwd.y)
        #expect(
          rev.x.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9),
          "PS south round-trip lat failed at (\(lat), \(lon))"
        )
        #expect(
          rev.y.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-9),
          "PS south round-trip lon failed at (\(lat), \(lon))"
        )
      }
    }
  }

  // MARK: - Full UTMUPS Forward-Reverse Grid

  @Test("UTMUPS forward-reverse round trip at a wide grid of points")
  func utmupsForwardReverseGrid() throws {
    for lat in stride(from: -75.0, through: 75.0, by: 15.0) {
      for lon in stride(from: -180.0, through: 150.0, by: 30.0) {
        let result = try UTMUPS.forward(latitude: lat, longitude: lon)
        let (recoveredLat, recoveredLon) = try UTMUPS.reverse(
          zone: result.zone,
          hemisphere: result.hemisphere,
          easting: result.easting,
          northing: result.northing
        )
        #expect(
          recoveredLat.isApproximatelyEqual(to: lat, absoluteTolerance: 1e-9),
          "UTMUPS round-trip lat failed at (\(lat), \(lon))"
        )
        // Use longitude-aware comparison (-180 and 180 are equivalent)
        var lonDiff = abs(recoveredLon - lon)
        if lonDiff > 180 { lonDiff = 360 - lonDiff }
        #expect(
          lonDiff.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-9),
          "UTMUPS round-trip lon failed at (\(lat), \(lon))"
        )
      }
    }
  }

  // MARK: - MGRS String Stability

  @Test("MGRS string is stable across encode-decode-encode cycle")
  func mgrsStringStability() throws {
    let testPoints: [(lat: Double, lon: Double)] = [
      (40.7128, -74.006), (51.5074, -0.1278), (35.6762, 139.6503)
    ]
    for point in testPoints {
      let geo = try GeographicCoordinate(latitude: point.lat, longitude: point.lon)
      let mgrs1 = try geo.mgrs(precision: .oneMeter).gridReference
      let parsed = try MGRSCoordinate(string: mgrs1)
      let mgrs2 = parsed.gridReference
      #expect(mgrs1 == mgrs2, "MGRS should be stable: \(mgrs1) vs \(mgrs2)")
    }
  }
}
