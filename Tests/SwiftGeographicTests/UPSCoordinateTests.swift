import Numerics
import Testing
@testable import SwiftGeographic

@Suite
struct `UPSCoordinate Tests` {

  // MARK: - Valid Creation

  @Test
  func `Create UPS coordinate with valid values`() throws {
    let ups = try UPSCoordinate(hemisphere: .north, easting: 2_000_000, northing: 2_000_000)
    #expect(ups.hemisphere == .north)
    #expect(ups.easting.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6))
    #expect(ups.northing.isApproximatelyEqual(to: 2_000_000, absoluteTolerance: 1e-6))
  }

  @Test
  func `Create UPS coordinate for south pole`() throws {
    let ups = try UPSCoordinate(hemisphere: .south, easting: 2_000_000, northing: 2_000_000)
    #expect(ups.hemisphere == .south)
  }

  // MARK: - North Pole Conversion

  @Test
  func `North pole UPS (2000000, 2000000) converts to approximately (90, 0)`() throws {
    let ups = try UPSCoordinate(hemisphere: .north, easting: 2_000_000, northing: 2_000_000)
    let geo = try ups.geographic
    #expect(geo.latitude.isApproximatelyEqual(to: 90, absoluteTolerance: 1e-6))
  }

  @Test
  func `South pole UPS (2000000, 2000000) converts to approximately (-90, 0)`() throws {
    let ups = try UPSCoordinate(hemisphere: .south, easting: 2_000_000, northing: 2_000_000)
    let geo = try ups.geographic
    #expect(geo.latitude.isApproximatelyEqual(to: -90, absoluteTolerance: 1e-6))
  }

  // MARK: - Conversion to Geographic

  @Test
  func `UPS to geographic round trip for north polar point`() throws {
    let original = try GeographicCoordinate(latitude: 85, longitude: 30)
    let ups = try original.ups
    let recovered = try ups.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 1e-6))
    #expect(
      recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 1e-6)
    )
  }

  @Test
  func `UPS to geographic round trip for south polar point`() throws {
    let original = try GeographicCoordinate(latitude: -85, longitude: -60)
    let ups = try original.ups
    let recovered = try ups.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 1e-6))
    #expect(
      recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 1e-6)
    )
  }

  @Test
  func `UPS to geographic for high-latitude north point`() throws {
    let original = try GeographicCoordinate(latitude: 89, longitude: 0)
    let ups = try original.ups
    #expect(ups.hemisphere == .north)
    let recovered = try ups.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: 89, absoluteTolerance: 1e-6))
    #expect(recovered.longitude.isApproximatelyEqual(to: 0, absoluteTolerance: 1e-6))
  }

  @Test
  func `UPS to geographic for high-latitude south point`() throws {
    let original = try GeographicCoordinate(latitude: -89, longitude: 120)
    let ups = try original.ups
    #expect(ups.hemisphere == .south)
    let recovered = try ups.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: -89, absoluteTolerance: 1e-6))
    #expect(recovered.longitude.isApproximatelyEqual(to: 120, absoluteTolerance: 1e-6))
  }

  // MARK: - MGRS Conversion

  @Test
  func `UPS to MGRS string starts with polar band letter`() throws {
    let ups = try UPSCoordinate(hemisphere: .north, easting: 2_000_000, northing: 2_000_000)
    let mgrsStr = ups.mgrs().gridReference
    // UPS MGRS should start with Y or Z for north
    let first = mgrsStr.first!
    #expect(first == "Y" || first == "Z", "North UPS MGRS should start with Y or Z")
  }

  @Test
  func `South UPS to MGRS string starts with A or B`() throws {
    let ups = try UPSCoordinate(hemisphere: .south, easting: 2_000_000, northing: 2_000_000)
    let mgrsStr = ups.mgrs().gridReference
    let first = mgrsStr.first!
    #expect(first == "A" || first == "B", "South UPS MGRS should start with A or B")
  }

  // MARK: - Various Longitudes

  @Test
  func `UPS coordinates at various longitudes around north pole`() throws {
    let longitudes: [Double] = [0, 45, 90, 135, 180, -45, -90, -135]
    for lon in longitudes {
      let original = try GeographicCoordinate(latitude: 87, longitude: lon)
      let ups = try original.ups
      let recovered = try ups.geographic
      #expect(
        recovered.latitude.isApproximatelyEqual(to: 87, absoluteTolerance: 1e-6),
        "Latitude mismatch at lon=\(lon)"
      )
      #expect(
        recovered.longitude.isApproximatelyEqual(to: lon, absoluteTolerance: 1e-6),
        "Longitude mismatch at lon=\(lon)"
      )
    }
  }

  // MARK: - Equatable

  @Test
  func `Equal UPS coordinates are equatable`() throws {
    let a = try UPSCoordinate(hemisphere: .north, easting: 2_000_000, northing: 2_000_000)
    let b = try UPSCoordinate(hemisphere: .north, easting: 2_000_000, northing: 2_000_000)
    #expect(a == b)
  }

  @Test
  func `Different UPS coordinates are not equal`() throws {
    let a = try UPSCoordinate(hemisphere: .north, easting: 2_000_000, northing: 2_000_000)
    let b = try UPSCoordinate(hemisphere: .south, easting: 2_000_000, northing: 2_000_000)
    #expect(a != b)
  }

  // MARK: - Exact Pole Points

  @Test
  func `Exact north pole UTM conversion still works`() throws {
    let coord = try GeographicCoordinate(latitude: 90, longitude: 0)
    let utm = try coord.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: 90, absoluteTolerance: 0.01))
  }

  @Test
  func `Exact south pole UTM conversion still works`() throws {
    let coord = try GeographicCoordinate(latitude: -90, longitude: 0)
    let utm = try coord.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: -90, absoluteTolerance: 0.01))
  }
}
