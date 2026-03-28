#if canImport(CoreLocation)
  import CoreLocation
  import Numerics
  import Testing
  @testable import SwiftGeographic

  @Suite("CoreLocation Extension Tests")
  struct CoreLocationTests {

    @Test("GeographicCoordinate to CLLocationCoordinate2D")
    func geoToCL() throws {
      let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.006)
      let cl = coord.clLocationCoordinate2D
      #expect(
        cl.latitude.isApproximatelyEqual(to: 40.7128, absoluteTolerance: 1e-10)
      )
      #expect(
        cl.longitude.isApproximatelyEqual(to: -74.006, absoluteTolerance: 1e-10)
      )
    }

    @Test("CLLocationCoordinate2D to GeographicCoordinate")
    func clToGeo() throws {
      let cl = CLLocationCoordinate2D(latitude: 48.8566, longitude: 2.3522)
      let coord = try GeographicCoordinate(cl)
      #expect(
        coord.latitude.isApproximatelyEqual(to: 48.8566, absoluteTolerance: 1e-10)
      )
      #expect(
        coord.longitude.isApproximatelyEqual(to: 2.3522, absoluteTolerance: 1e-10)
      )
    }

    @Test("UTMCoordinate to CLLocationCoordinate2D")
    func utmToCL() throws {
      let utm = try UTMCoordinate(
        zone: 18,
        hemisphere: .north,
        easting: 583960,
        northing: 4507523
      )
      let cl = try utm.clLocationCoordinate2D
      #expect(cl.latitude.isApproximatelyEqual(to: 40.71, absoluteTolerance: 0.02))
      #expect(cl.longitude.isApproximatelyEqual(to: -74.01, absoluteTolerance: 0.02))
    }

    @Test("MGRSCoordinate to CLLocationCoordinate2D")
    func mgrsToCL() throws {
      let mgrs = try MGRSCoordinate(string: "33XVG7459743593")
      let cl = try mgrs.clLocationCoordinate2D
      #expect(cl.latitude > 77 && cl.latitude < 79)
    }
  }
#endif
