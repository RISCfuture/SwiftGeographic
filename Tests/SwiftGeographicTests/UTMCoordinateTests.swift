import Numerics
import Testing
@testable import SwiftGeographic

@Suite
struct `UTMCoordinate Tests` {

  // MARK: - Valid Creation

  @Test
  func `Create UTM coordinate with valid values`() throws {
    let utm = try UTMCoordinate(
      zone: 18,
      hemisphere: .north,
      easting: 583960,
      northing: 4507523
    )
    #expect(utm.zone == 18)
    #expect(utm.hemisphere == .north)
    #expect(utm.easting.isApproximatelyEqual(to: 583960, absoluteTolerance: 1e-6))
    #expect(utm.northing.isApproximatelyEqual(to: 4507523, absoluteTolerance: 1e-6))
  }

  @Test
  func `Create UTM coordinate at zone boundaries`() throws {
    let zone1 = try UTMCoordinate(zone: 1, hemisphere: .north, easting: 500000, northing: 0)
    #expect(zone1.zone == 1)

    let zone60 = try UTMCoordinate(zone: 60, hemisphere: .south, easting: 500000, northing: 5000000)
    #expect(zone60.zone == 60)
  }

  // MARK: - Invalid Zone

  @Test
  func `Zone 0 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(0)) {
      try UTMCoordinate(zone: 0, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test
  func `Zone 61 throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(61)) {
      try UTMCoordinate(zone: 61, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  @Test
  func `Negative zone throws invalidZone`() {
    #expect(throws: SwiftGeographicError.invalidZone(-1)) {
      try UTMCoordinate(zone: -1, hemisphere: .north, easting: 500000, northing: 0)
    }
  }

  // MARK: - Known Point: Statue of Liberty

  @Test
  func `Statue of Liberty UTM coordinates approximately 18N 580736 4504695`() throws {
    // Statue of Liberty: 40.6892, -74.0445
    let geo = try GeographicCoordinate(latitude: 40.6892, longitude: -74.0445)
    let utm = try geo.utm
    #expect(utm.zone == 18)
    #expect(utm.hemisphere == .north)
    #expect(utm.easting.isApproximatelyEqual(to: 580736, absoluteTolerance: 200))
    #expect(utm.northing.isApproximatelyEqual(to: 4504695, absoluteTolerance: 200))
  }

  // MARK: - Conversion Back to Geographic

  @Test
  func `UTM to geographic round trip`() throws {
    let utm = try UTMCoordinate(
      zone: 18,
      hemisphere: .north,
      easting: 583960,
      northing: 4507523
    )
    let geo = try utm.geographic
    // Should be near New York City
    #expect(geo.latitude.isApproximatelyEqual(to: 40.71, absoluteTolerance: 0.02))
    #expect(geo.longitude.isApproximatelyEqual(to: -74.01, absoluteTolerance: 0.02))
  }

  @Test
  func `Geographic to UTM to geographic round trip preserves coordinates`() throws {
    let original = try GeographicCoordinate(latitude: 48.8566, longitude: 2.3522)
    let utm = try original.utm
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 1e-6))
    #expect(
      recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 1e-6)
    )
  }

  @Test
  func `Southern hemisphere UTM to geographic`() throws {
    let original = try GeographicCoordinate(latitude: -33.8688, longitude: 151.2093)
    let utm = try original.utm
    #expect(utm.hemisphere == .south)
    let recovered = try utm.geographic
    #expect(recovered.latitude.isApproximatelyEqual(to: original.latitude, absoluteTolerance: 1e-6))
    #expect(
      recovered.longitude.isApproximatelyEqual(to: original.longitude, absoluteTolerance: 1e-6)
    )
  }

  // MARK: - Central Meridian Property

  @Test
  func `Central meridian for zone 18 is -75`() throws {
    let utm = try UTMCoordinate(zone: 18, hemisphere: .north, easting: 500000, northing: 0)
    #expect(utm.centralMeridian.isApproximatelyEqual(to: -75, absoluteTolerance: 1e-6))
  }

  @Test
  func `Central meridian for zone 31 is 3`() throws {
    let utm = try UTMCoordinate(zone: 31, hemisphere: .north, easting: 500000, northing: 0)
    #expect(utm.centralMeridian.isApproximatelyEqual(to: 3, absoluteTolerance: 1e-6))
  }

  @Test
  func `Central meridian for zone 1 is -177`() throws {
    let utm = try UTMCoordinate(zone: 1, hemisphere: .north, easting: 500000, northing: 0)
    #expect(utm.centralMeridian.isApproximatelyEqual(to: -177, absoluteTolerance: 1e-6))
  }

  // MARK: - MGRS Conversion

  @Test
  func `UTM to MGRS string`() throws {
    let utm = try UTMCoordinate(
      zone: 18,
      hemisphere: .north,
      easting: 583960,
      northing: 4507523
    )
    let mgrsString = try utm.mgrs().gridReference
    #expect(mgrsString.hasPrefix("18"))
    #expect(mgrsString.count > 5)
  }

  @Test
  func `UTM to MGRS at different precisions`() throws {
    let utm = try UTMCoordinate(
      zone: 18,
      hemisphere: .north,
      easting: 583960,
      northing: 4507523
    )
    let mgrs1m = try utm.mgrs(precision: .oneMeter).gridReference
    let mgrs1km = try utm.mgrs(precision: .oneKilometer).gridReference
    #expect(mgrs1m.count > mgrs1km.count)
  }

  // MARK: - Equatable and Hashable

  @Test
  func `Equal UTM coordinates are equatable`() throws {
    let a = try UTMCoordinate(zone: 18, hemisphere: .north, easting: 583960, northing: 4507523)
    let b = try UTMCoordinate(zone: 18, hemisphere: .north, easting: 583960, northing: 4507523)
    #expect(a == b)
  }

  @Test
  func `Different UTM coordinates are not equal`() throws {
    let a = try UTMCoordinate(zone: 18, hemisphere: .north, easting: 583960, northing: 4507523)
    let b = try UTMCoordinate(zone: 18, hemisphere: .north, easting: 500000, northing: 4507523)
    #expect(a != b)
  }
}
