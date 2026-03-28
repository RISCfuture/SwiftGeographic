import Numerics
import Testing
@testable import SwiftGeographic

/// Hardcoded test vectors from multiple authoritative geodetic sources.
/// Each section cites its source so failing tests can be traced to a
/// specific reference implementation or standard.
///
/// Sources:
/// - NGA.SIG.0012 (UPS specification, Karney, Section 10.2 / 10.3)
/// - NGA mgrs-java (MIT-licensed MGRS reference library)
/// - DMA Technical Manual 8358.2 (UPS forward projection)
/// - Turbo87/utm (Python UTM zone selection library)
/// - chrisveness/geodesy (JavaScript geodesy library, Karney's method)
/// - PyGeodesy (Python geodesy library, Svalbard MGRS zones)
@Suite("Reference Data Tests")
struct ReferenceDataTests {

  // MARK: - 1. NGA.SIG.0012 UPS Forward Vectors (Section 10.2)

  /// Test vectors from NGA's authoritative UPS specification authored by Karney.
  /// WGS84 ellipsoid, UPS projection. Verifies easting/northing via
  /// `UTMUPS.forward` (zone 0) and scale/convergence via
  /// `PolarStereographic.ups.forward`.
  @Test("NGA.SIG.0012 UPS forward projection for north-hemisphere points")
  func ngaUPSForward() throws {
    struct UPSVector {
      let longitude: Double
      let latitude: Double
      let isNorth: Bool
      let expectedEasting: Double
      let expectedNorthing: Double
      let expectedScale: Double
      let expectedConvergence: Double
    }

    let vectors: [UPSVector] = [
      UPSVector(
        longitude: 0,
        latitude: 90,
        isNorth: true,
        expectedEasting: 2_000_000.000000,
        expectedNorthing: 2_000_000.000000,
        expectedScale: 0.994000,
        expectedConvergence: 0
      ),
      UPSVector(
        longitude: -179,
        latitude: 89,
        isNorth: true,
        expectedEasting: 1_998_062.320046,
        expectedNorthing: 2_111_009.610243,
        expectedScale: 0.994076,
        expectedConvergence: -179
      ),
      UPSVector(
        longitude: 0,
        latitude: 86,
        isNorth: true,
        expectedEasting: 2_000_000.000000,
        expectedNorthing: 1_555_731.570643,
        expectedScale: 0.995212,
        expectedConvergence: 0
      ),
      UPSVector(
        longitude: 1,
        latitude: 85,
        isNorth: true,
        expectedEasting: 2_009_694.068153,
        expectedNorthing: 1_444_627.207468,
        expectedScale: 0.995895,
        expectedConvergence: 1
      ),
      UPSVector(
        longitude: 89,
        latitude: 84,
        isNorth: true,
        expectedEasting: 2_666_626.157825,
        expectedNorthing: 1_988_363.997132,
        expectedScale: 0.996730,
        expectedConvergence: 89
      )
    ]

    for v in vectors {
      // Test easting/northing via UTMUPS.forward (zone 0 = UPS)
      let utmResult = try UTMUPS.forward(
        latitude: v.latitude,
        longitude: v.longitude,
        zone: 0
      )
      #expect(
        utmResult.zone == 0,
        "Expected UPS zone 0 for (\(v.latitude), \(v.longitude))"
      )
      #expect(
        utmResult.easting.isApproximatelyEqual(
          to: v.expectedEasting,
          absoluteTolerance: 0.01
        ),
        "Easting mismatch for (\(v.latitude), \(v.longitude)): got \(utmResult.easting), expected \(v.expectedEasting)"
      )
      #expect(
        utmResult.northing.isApproximatelyEqual(
          to: v.expectedNorthing,
          absoluteTolerance: 0.01
        ),
        "Northing mismatch for (\(v.latitude), \(v.longitude)): got \(utmResult.northing), expected \(v.expectedNorthing)"
      )

      // Test scale and convergence via PolarStereographic.ups.forward
      let psResult = PolarStereographic.ups.forward(
        isNorth: v.isNorth,
        latitude: v.latitude,
        longitude: v.longitude
      )
      #expect(
        psResult.scale.isApproximatelyEqual(
          to: v.expectedScale,
          absoluteTolerance: 1e-6
        ),
        "Scale mismatch for (\(v.latitude), \(v.longitude)): got \(psResult.scale), expected \(v.expectedScale)"
      )
      #expect(
        psResult.convergence.isApproximatelyEqual(
          to: v.expectedConvergence,
          absoluteTolerance: 1e-3
        ),
        "Convergence mismatch for (\(v.latitude), \(v.longitude)): got \(psResult.convergence), expected \(v.expectedConvergence)"
      )
    }
  }

  // MARK: - 2. NGA mgrs-java Multi-Precision Tests

  /// Test vectors from NGA's official MGRS library (MIT license).
  /// Svalbard chain: lat 72-78, lon 9-14. Tests MGRS parsing at
  /// precision levels from GZD through 1m.
  @Test("NGA mgrs-java precision chain for Svalbard (33X)")
  func ngaMGRSPrecisionChain() throws {
    struct MGRSPrecisionVector {
      let mgrs: String
      let expectedLatitude: Double
      let expectedLongitude: Double
      let tolerance: Double  // degrees
    }

    // At ~78 degrees latitude, longitude grid cells are significantly wider
    // than at the equator (by a factor of ~1/cos(78) ~ 4.8), so longitude
    // tolerances must be scaled accordingly for each precision level.
    let vectors: [MGRSPrecisionVector] = [
      // 100km precision (center of 100km cell)
      MGRSPrecisionVector(
        mgrs: "33XVG",
        expectedLatitude: 77.445,
        expectedLongitude: 12.86,
        tolerance: 2.5
      ),
      // 10km precision
      MGRSPrecisionVector(
        mgrs: "33XVG74",
        expectedLatitude: 77.832,
        expectedLongitude: 13.933,
        tolerance: 0.25
      ),
      // 1km precision
      MGRSPrecisionVector(
        mgrs: "33XVG7443",
        expectedLatitude: 77.860,
        expectedLongitude: 13.913,
        tolerance: 0.025
      ),
      // 100m precision
      MGRSPrecisionVector(
        mgrs: "33XVG745435",
        expectedLatitude: 77.865,
        expectedLongitude: 13.915,
        tolerance: 0.005
      ),
      // 10m precision
      MGRSPrecisionVector(
        mgrs: "33XVG74594359",
        expectedLatitude: 77.8655,
        expectedLongitude: 13.9173,
        tolerance: 0.001
      ),
      // 1m precision
      MGRSPrecisionVector(
        mgrs: "33XVG7459743593",
        expectedLatitude: 77.86550,
        expectedLongitude: 13.91742,
        tolerance: 0.0001
      )
    ]

    for v in vectors {
      let parsed = try MGRSCoordinate(string: v.mgrs)
      let geo = try parsed.geographic
      #expect(
        geo.latitude.isApproximatelyEqual(
          to: v.expectedLatitude,
          absoluteTolerance: v.tolerance
        ),
        "Latitude mismatch for MGRS \(v.mgrs): got \(geo.latitude), expected \(v.expectedLatitude) +/- \(v.tolerance)"
      )
      #expect(
        geo.longitude.isApproximatelyEqual(
          to: v.expectedLongitude,
          absoluteTolerance: v.tolerance
        ),
        "Longitude mismatch for MGRS \(v.mgrs): got \(geo.longitude), expected \(v.expectedLongitude) +/- \(v.tolerance)"
      )
    }
  }

  /// NGA mgrs-java coordinate-to-MGRS test points.
  @Test("NGA mgrs-java coordinate-to-MGRS forward conversion")
  func ngaMGRSForward() throws {
    struct ForwardVector {
      let latitude: Double
      let longitude: Double
      let expectedMGRS: String
    }

    let vectors: [ForwardVector] = [
      ForwardVector(
        latitude: 63.98863,
        longitude: 29.06757,
        expectedMGRS: "35VPL0115697387"
      ),
      ForwardVector(
        latitude: 12.40,
        longitude: 53.51,
        expectedMGRS: "39PYP7290672069"
      ),
      ForwardVector(
        latitude: 21.309444,
        longitude: -157.916861,
        expectedMGRS: "04QFJ1234056781"
      )
    ]

    for v in vectors {
      let coord = try GeographicCoordinate(
        latitude: v.latitude,
        longitude: v.longitude
      )
      let mgrs = try coord.mgrs(precision: .oneMeter).gridReference
      #expect(
        mgrs == v.expectedMGRS,
        "MGRS mismatch for (\(v.latitude), \(v.longitude)): got \(mgrs), expected \(v.expectedMGRS)"
      )
    }
  }

  // MARK: - 3. Turbo87/utm Zone Selection Tests

  /// Zone selection tests from the Turbo87/utm Python library.
  /// Norway exception: zone 32V covers lat 56-64, lon 3-12.
  @Test("Turbo87/utm Norway zone 32V selection")
  func norwayZoneSelection() {
    // Inside Norway exception (zone 32V)
    #expect(UTMUPS.standardZone(latitude: 56, longitude: 3) == 32)
    #expect(UTMUPS.standardZone(latitude: 56, longitude: 6) == 32)
    #expect(UTMUPS.standardZone(latitude: 56, longitude: 9) == 32)
    #expect(UTMUPS.standardZone(latitude: 56, longitude: 11.999999) == 32)

    // Below Norway range (lat < 56)
    #expect(UTMUPS.standardZone(latitude: 55.999999, longitude: 3) == 31)

    // Above Norway range (lat >= 64)
    #expect(UTMUPS.standardZone(latitude: 64, longitude: 3) == 31)
  }

  /// Zone selection tests from the Turbo87/utm Python library.
  /// Svalbard exceptions: zones 31/33/35/37 for lat 72-84.
  @Test("Turbo87/utm Svalbard zone selection")
  func svalbardZoneSelection() {
    // Zone 31: lon [0, 9)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 0) == 31)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 5.999999) == 31)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 6) == 31)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 8.999999) == 31)

    // Zone 33: lon [9, 21)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 9) == 33)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 20.999999) == 33)

    // Zone 35: lon [21, 33)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 21) == 35)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 32.999999) == 35)

    // Zone 37: lon [33, 42)
    #expect(UTMUPS.standardZone(latitude: 72, longitude: 33) == 37)
  }

  // MARK: - 4. chrisveness/geodesy UTM Known Coordinates

  /// UTM test vectors from the chrisveness/geodesy JavaScript library,
  /// using Karney's method. Tolerance: 1m for easting/northing.
  @Test("chrisveness/geodesy UTM known coordinate points")
  func chrisvenessUTMPoints() throws {
    struct UTMVector {
      let latitude: Double
      let longitude: Double
      let expectedZone: Int
      let expectedHemisphere: Hemisphere
      let expectedEasting: Double
      let expectedNorthing: Double
    }

    let vectors: [UTMVector] = [
      UTMVector(
        latitude: 0,
        longitude: 0,
        expectedZone: 31,
        expectedHemisphere: .north,
        expectedEasting: 166_021.443081,
        expectedNorthing: 0.000000
      ),
      UTMVector(
        latitude: 1,
        longitude: 1,
        expectedZone: 31,
        expectedHemisphere: .north,
        expectedEasting: 277_438.264,
        expectedNorthing: 110_597.973
      ),
      UTMVector(
        latitude: -1,
        longitude: -1,
        expectedZone: 30,
        expectedHemisphere: .south,
        expectedEasting: 722_561.736,
        expectedNorthing: 9_889_402.027
      ),
      UTMVector(
        latitude: 48.8583,
        longitude: 2.2945,
        expectedZone: 31,
        expectedHemisphere: .north,
        expectedEasting: 448_251.898,
        expectedNorthing: 5_411_943.794
      ),
      UTMVector(
        latitude: -33.857,
        longitude: 151.215,
        expectedZone: 56,
        expectedHemisphere: .south,
        expectedEasting: 334_873.199,
        expectedNorthing: 6_252_266.092
      ),
      UTMVector(
        latitude: 38.8977,
        longitude: -77.0365,
        expectedZone: 18,
        expectedHemisphere: .north,
        expectedEasting: 323_394.296,
        expectedNorthing: 4_307_395.634
      ),
      UTMVector(
        latitude: -22.9519,
        longitude: -43.2106,
        expectedZone: 23,
        expectedHemisphere: .south,
        expectedEasting: 683_466.254,
        expectedNorthing: 7_460_687.433
      )
    ]

    for v in vectors {
      let result = try UTMUPS.forward(
        latitude: v.latitude,
        longitude: v.longitude
      )
      #expect(
        result.zone == v.expectedZone,
        "Zone mismatch for (\(v.latitude), \(v.longitude)): got \(result.zone), expected \(v.expectedZone)"
      )
      #expect(
        result.hemisphere == v.expectedHemisphere,
        "Hemisphere mismatch for (\(v.latitude), \(v.longitude)): got \(result.hemisphere), expected \(v.expectedHemisphere)"
      )
      #expect(
        result.easting.isApproximatelyEqual(
          to: v.expectedEasting,
          absoluteTolerance: 1
        ),
        "Easting mismatch for (\(v.latitude), \(v.longitude)): got \(result.easting), expected \(v.expectedEasting)"
      )
      #expect(
        result.northing.isApproximatelyEqual(
          to: v.expectedNorthing,
          absoluteTolerance: 1
        ),
        "Northing mismatch for (\(v.latitude), \(v.longitude)): got \(result.northing), expected \(v.expectedNorthing)"
      )
    }
  }

  // MARK: - 5. NGA.SIG.0012 UPS Forward Full (Section 10.2, points 1-11)

  /// All 11 north-hemisphere UPS forward test vectors from NGA.SIG.0012 Section 10.2.
  /// Uses PolarStereographic.ups.forward directly, adding false easting/northing of 2,000,000.
  @Test("NGA.SIG.0012 UPS forward full (11 north-hemisphere points)")
  func ngaUPSForwardFull() {
    struct UPSVector {
      let longitude: Double
      let latitude: Double
      let isNorth: Bool
      let expectedEasting: Double
      let expectedNorthing: Double
      let expectedScale: Double
      let expectedConvergence: Double
      let skipConvergence: Bool
    }

    let vectors: [UPSVector] = [
      UPSVector(
        longitude: 0,
        latitude: 90,
        isNorth: true,
        expectedEasting: 2_000_000.000000,
        expectedNorthing: 2_000_000.000000,
        expectedScale: 0.994000,
        expectedConvergence: 0,
        skipConvergence: true
      ),
      UPSVector(
        longitude: -179,
        latitude: 89,
        isNorth: true,
        expectedEasting: 1_998_062.320046,
        expectedNorthing: 2_111_009.610243,
        expectedScale: 0.994076,
        expectedConvergence: -179,
        skipConvergence: false
      ),
      UPSVector(
        longitude: -90,
        latitude: 88,
        isNorth: true,
        expectedEasting: 1_777_930.731071,
        expectedNorthing: 2_000_000.000000,
        expectedScale: 0.994303,
        expectedConvergence: -90,
        skipConvergence: false
      ),
      UPSVector(
        longitude: -1,
        latitude: 87,
        isNorth: true,
        expectedEasting: 1_994_185.827038,
        expectedNorthing: 1_666_906.254073,
        expectedScale: 0.994682,
        expectedConvergence: -1,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 0,
        latitude: 86,
        isNorth: true,
        expectedEasting: 2_000_000.000000,
        expectedNorthing: 1_555_731.570643,
        expectedScale: 0.995212,
        expectedConvergence: 0,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 1,
        latitude: 85,
        isNorth: true,
        expectedEasting: 2_009_694.068153,
        expectedNorthing: 1_444_627.207468,
        expectedScale: 0.995895,
        expectedConvergence: 1,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 89,
        latitude: 84,
        isNorth: true,
        expectedEasting: 2_666_626.157825,
        expectedNorthing: 1_988_363.997132,
        expectedScale: 0.996730,
        expectedConvergence: 89,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 90,
        latitude: 83,
        isNorth: true,
        expectedEasting: 2_778_095.750322,
        expectedNorthing: 2_000_000.000000,
        expectedScale: 0.997718,
        expectedConvergence: 90,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 91,
        latitude: 82,
        isNorth: true,
        expectedEasting: 2_889_442.490749,
        expectedNorthing: 2_015_525.276426,
        expectedScale: 0.998860,
        expectedConvergence: 91,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 179,
        latitude: 81,
        isNorth: true,
        expectedEasting: 2_017_473.190606,
        expectedNorthing: 3_001_038.419357,
        expectedScale: 1.000156,
        expectedConvergence: 179,
        skipConvergence: false
      ),
      UPSVector(
        longitude: 180,
        latitude: 80,
        isNorth: true,
        expectedEasting: 2_000_000.000000,
        expectedNorthing: 3_112_951.136955,
        expectedScale: 1.001608,
        expectedConvergence: 180,
        skipConvergence: false
      )
    ]

    let falseEN = 2_000_000.0
    for v in vectors {
      let result = PolarStereographic.ups.forward(
        isNorth: v.isNorth,
        latitude: v.latitude,
        longitude: v.longitude
      )
      let easting = result.x + falseEN
      let northing = result.y + falseEN

      #expect(
        easting.isApproximatelyEqual(
          to: v.expectedEasting,
          absoluteTolerance: 0.01
        ),
        "Easting mismatch for (\(v.latitude), \(v.longitude)): got \(easting), expected \(v.expectedEasting)"
      )
      #expect(
        northing.isApproximatelyEqual(
          to: v.expectedNorthing,
          absoluteTolerance: 0.01
        ),
        "Northing mismatch for (\(v.latitude), \(v.longitude)): got \(northing), expected \(v.expectedNorthing)"
      )
      #expect(
        result.scale.isApproximatelyEqual(
          to: v.expectedScale,
          absoluteTolerance: 1e-6
        ),
        "Scale mismatch for (\(v.latitude), \(v.longitude)): got \(result.scale), expected \(v.expectedScale)"
      )
      if !v.skipConvergence {
        #expect(
          result.convergence.isApproximatelyEqual(
            to: v.expectedConvergence,
            absoluteTolerance: 1e-3
          ),
          "Convergence mismatch for (\(v.latitude), \(v.longitude)): got \(result.convergence), expected \(v.expectedConvergence)"
        )
      }
    }
  }

  // MARK: - 6. NGA.SIG.0012 UPS Reverse South Grid (Section 10.3)

  /// 25 south-pole UPS reverse test vectors from NGA.SIG.0012 Section 10.3.
  /// Uses PolarStereographic.ups.reverse with isNorth=false.
  @Test("NGA.SIG.0012 UPS reverse south-pole 5x5 grid")
  func ngaUPSReverseSouthGrid() {
    struct UPSReverseVector {
      let easting: Double
      let northing: Double
      let expectedLon: Double
      let expectedLat: Double
      let skipLon: Bool
    }

    let vectors: [UPSReverseVector] = [
      UPSReverseVector(
        easting: 0,
        northing: 0,
        expectedLon: -135.0,
        expectedLat: -64.9164123332,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 1_000_000,
        northing: 0,
        expectedLon: -153.4349488229,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 2_000_000,
        northing: 0,
        expectedLon: -180.0,
        expectedLat: -72.1263610163,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 3_000_000,
        northing: 0,
        expectedLon: 153.4349488229,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 4_000_000,
        northing: 0,
        expectedLon: 135.0,
        expectedLat: -64.9164123332,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 0,
        northing: 1_000_000,
        expectedLon: -116.5650511771,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 1_000_000,
        northing: 1_000_000,
        expectedLon: -135.0,
        expectedLat: -77.3120791908,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 2_000_000,
        northing: 1_000_000,
        expectedLon: 180.0,
        expectedLat: -81.0106632645,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 3_000_000,
        northing: 1_000_000,
        expectedLon: 135.0,
        expectedLat: -77.3120791908,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 4_000_000,
        northing: 1_000_000,
        expectedLon: 116.5650511771,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 0,
        northing: 2_000_000,
        expectedLon: -90.0,
        expectedLat: -72.1263610163,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 1_000_000,
        northing: 2_000_000,
        expectedLon: -90.0,
        expectedLat: -81.0106632645,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 2_000_000,
        northing: 2_000_000,
        expectedLon: 0.0,
        expectedLat: -90.0,
        skipLon: true
      ),
      UPSReverseVector(
        easting: 3_000_000,
        northing: 2_000_000,
        expectedLon: 90.0,
        expectedLat: -81.0106632645,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 4_000_000,
        northing: 2_000_000,
        expectedLon: 90.0,
        expectedLat: -72.1263610163,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 0,
        northing: 3_000_000,
        expectedLon: -63.4349488229,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 1_000_000,
        northing: 3_000_000,
        expectedLon: -45.0,
        expectedLat: -77.3120791908,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 2_000_000,
        northing: 3_000_000,
        expectedLon: 0.0,
        expectedLat: -81.0106632645,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 3_000_000,
        northing: 3_000_000,
        expectedLon: 45.0,
        expectedLat: -77.3120791908,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 4_000_000,
        northing: 3_000_000,
        expectedLon: 63.4349488229,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 0,
        northing: 4_000_000,
        expectedLon: -45.0,
        expectedLat: -64.9164123332,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 1_000_000,
        northing: 4_000_000,
        expectedLon: -26.5650511771,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 2_000_000,
        northing: 4_000_000,
        expectedLon: 0.0,
        expectedLat: -72.1263610163,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 3_000_000,
        northing: 4_000_000,
        expectedLon: 26.5650511771,
        expectedLat: -70.0552944014,
        skipLon: false
      ),
      UPSReverseVector(
        easting: 4_000_000,
        northing: 4_000_000,
        expectedLon: 45.0,
        expectedLat: -64.9164123332,
        skipLon: false
      )
    ]

    let falseEN = 2_000_000.0
    for v in vectors {
      let result = PolarStereographic.ups.reverse(
        isNorth: false,
        easting: v.easting - falseEN,
        northing: v.northing - falseEN
      )
      let lat = result.x
      let lon = result.y

      #expect(
        lat.isApproximatelyEqual(
          to: v.expectedLat,
          absoluteTolerance: 1e-6
        ),
        "Lat mismatch for easting=\(v.easting), northing=\(v.northing): got \(lat), expected \(v.expectedLat)"
      )

      if !v.skipLon {
        // Longitude-aware comparison: handle +/-180 wrapping
        var lonDiff = abs(lon - v.expectedLon)
        if lonDiff > 180 {
          lonDiff = 360 - lonDiff
        }
        #expect(
          lonDiff < 1e-6,
          "Lon mismatch for easting=\(v.easting), northing=\(v.northing): got \(lon), expected \(v.expectedLon)"
        )
      }
    }
  }

  // MARK: - 7. DMA TM 8358.2 UPS Forward

  /// Three UPS forward test vectors from DMA Technical Manual 8358.2.
  /// Uses PolarStereographic.ups.forward with false easting/northing of 2,000,000.
  @Test("DMA TM 8358.2 UPS forward projection")
  func dmaUPSForward() {
    struct DMAVector {
      let latitude: Double
      let longitude: Double
      let isNorth: Bool
      let expectedEasting: Double
      let expectedNorthing: Double
      let expectedScale: Double
    }

    let vectors: [DMAVector] = [
      DMAVector(
        latitude: 84.28723389,
        longitude: -132.24799336,
        isNorth: true,
        expectedEasting: 1_530_125.78,
        expectedNorthing: 2_426_773.60,
        expectedScale: 0.99647445
      ),
      DMAVector(
        latitude: 73.0,
        longitude: 44.0,
        isNorth: true,
        expectedEasting: 3_320_416.75,
        expectedNorthing: 632_668.43,
        expectedScale: 1.01619505
      ),
      DMAVector(
        latitude: -87.28733333,
        longitude: 132.24786194,
        isNorth: false,
        expectedEasting: 2_222_979.47,
        expectedNorthing: 1_797_474.90,
        expectedScale: 0.99455723
      )
    ]

    let falseEN = 2_000_000.0
    for v in vectors {
      let result = PolarStereographic.ups.forward(
        isNorth: v.isNorth,
        latitude: v.latitude,
        longitude: v.longitude
      )
      let easting = result.x + falseEN
      let northing = result.y + falseEN

      #expect(
        easting.isApproximatelyEqual(
          to: v.expectedEasting,
          absoluteTolerance: 0.1
        ),
        "Easting mismatch for (\(v.latitude), \(v.longitude)): got \(easting), expected \(v.expectedEasting)"
      )
      #expect(
        northing.isApproximatelyEqual(
          to: v.expectedNorthing,
          absoluteTolerance: 0.1
        ),
        "Northing mismatch for (\(v.latitude), \(v.longitude)): got \(northing), expected \(v.expectedNorthing)"
      )
      #expect(
        result.scale.isApproximatelyEqual(
          to: v.expectedScale,
          absoluteTolerance: 1e-4
        ),
        "Scale mismatch for (\(v.latitude), \(v.longitude)): got \(result.scale), expected \(v.expectedScale)"
      )
    }
  }

  // MARK: - 8. PyGeodesy Svalbard MGRS Zone Tests

  /// Test vectors from PyGeodesy verifying that Svalbard zone exceptions
  /// produce correct MGRS grid zone designators.
  @Test("PyGeodesy Svalbard MGRS zone designators")
  func pyGeodesySvalbardMGRS() throws {
    struct SvalbardVector {
      let latitude: Double
      let longitude: Double
      let expectedZone: Int
      let expectedMGRSPrefix: String
    }

    let vectors: [SvalbardVector] = [
      SvalbardVector(
        latitude: 60.0,
        longitude: 1.0,
        expectedZone: 31,
        expectedMGRSPrefix: "31V"
      ),
      SvalbardVector(
        latitude: 60.0,
        longitude: 3.0,
        expectedZone: 32,
        expectedMGRSPrefix: "32V"
      ),
      SvalbardVector(
        latitude: 60.0,
        longitude: 9.0,
        expectedZone: 32,
        expectedMGRSPrefix: "32V"
      ),
      SvalbardVector(
        latitude: 76.0,
        longitude: 1.0,
        expectedZone: 31,
        expectedMGRSPrefix: "31X"
      ),
      SvalbardVector(
        latitude: 76.0,
        longitude: 13.0,
        expectedZone: 33,
        expectedMGRSPrefix: "33X"
      ),
      SvalbardVector(
        latitude: 76.0,
        longitude: 25.0,
        expectedZone: 35,
        expectedMGRSPrefix: "35X"
      ),
      SvalbardVector(
        latitude: 76.0,
        longitude: 37.0,
        expectedZone: 37,
        expectedMGRSPrefix: "37X"
      )
    ]

    for v in vectors {
      let zone = UTMUPS.standardZone(
        latitude: v.latitude,
        longitude: v.longitude
      )
      #expect(
        zone == v.expectedZone,
        "Zone mismatch for (\(v.latitude), \(v.longitude)): got \(zone), expected \(v.expectedZone)"
      )

      let coord = try GeographicCoordinate(
        latitude: v.latitude,
        longitude: v.longitude
      )
      let mgrs = try coord.mgrs(precision: .oneMeter).gridReference
      #expect(
        mgrs.hasPrefix(v.expectedMGRSPrefix),
        "MGRS prefix mismatch for (\(v.latitude), \(v.longitude)): got \(mgrs), expected prefix \(v.expectedMGRSPrefix)"
      )
    }
  }
}
