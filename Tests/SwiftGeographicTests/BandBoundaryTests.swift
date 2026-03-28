import Foundation
import Numerics
import Testing
@testable import SwiftGeographic

/// Tests MGRS latitude band disambiguation at every 8-degree band boundary,
/// both hemispheres. Verifies correct band letter assignment and geographic
/// round-trip accuracy near band edges.
///
/// Band boundaries occur at latitudes: -72, -64, -56, -48, -40, -32, -24, -16,
/// -8, 0, 8, 16, 24, 32, 40, 48, 56, 64, 72 (the X band extends to 84).
@Suite("Band Boundary Tests")
struct BandBoundaryTests {

  /// The latitude band letters C through X (skipping I and O), corresponding
  /// to 8-degree bands from 80S to 84N.
  private static let bandLetters: [Character] = [
    "C", "D", "E", "F", "G", "H", "J", "K", "L", "M",
    "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X"
  ]

  /// Band boundaries at which the letter transitions.
  /// Below boundary[i], the band is bandLetters[i]; at or above, it is bandLetters[i+1].
  private static let boundaries: [Double] = [
    -72, -64, -56, -48, -40, -32, -24, -16, -8, 0,
    8, 16, 24, 32, 40, 48, 56, 64, 72
  ]

  /// Returns the expected band letter for a given latitude.
  private static func expectedBandLetter(for latitude: Double) -> Character {
    // Band C starts at -80, each band is 8 degrees, except X which goes to 84.
    let index = min(
      Int(floor((latitude + 80) / 8)),
      bandLetters.count - 1
    )
    return bandLetters[max(0, index)]
  }

  /// Extracts the band letter (third character) from an MGRS string.
  /// MGRS format: "ZZB..." where ZZ is the two-digit zone and B is the band letter.
  private static func extractBandLetter(from mgrs: String) -> Character? {
    let chars = Array(mgrs)
    // Skip leading zone digits
    var idx = 0
    while idx < chars.count, chars[idx].isNumber {
      idx += 1
    }
    guard idx < chars.count else { return nil }
    return chars[idx]
  }

  // MARK: - Band Boundary Tests (both sides of each boundary)

  @Test("Band letter correct just below and above each 8-degree boundary")
  func bandLetterAtBoundaries() throws {
    let testLongitudes: [Double] = [0, 45, 90, -90]
    let offset = 0.001

    for boundary in Self.boundaries {
      for lon in testLongitudes {
        // Just below boundary
        let latBelow = boundary - offset
        let expectedBelow = Self.expectedBandLetter(for: latBelow)

        let coordBelow = try GeographicCoordinate(
          latitude: latBelow,
          longitude: lon
        )
        let mgrsBelow = try coordBelow.mgrs(precision: .oneMeter).gridReference
        let actualBelow = Self.extractBandLetter(from: mgrsBelow)

        #expect(
          actualBelow == expectedBelow,
          """
          Band letter mismatch below boundary \(boundary) at lon=\(lon):
            lat=\(latBelow), MGRS=\(mgrsBelow),
            got '\(actualBelow ?? "?")', expected '\(expectedBelow)'
          """
        )

        // Just above boundary
        let latAbove = boundary + offset
        let expectedAbove = Self.expectedBandLetter(for: latAbove)

        let coordAbove = try GeographicCoordinate(
          latitude: latAbove,
          longitude: lon
        )
        let mgrsAbove = try coordAbove.mgrs(precision: .oneMeter).gridReference
        let actualAbove = Self.extractBandLetter(from: mgrsAbove)

        #expect(
          actualAbove == expectedAbove,
          """
          Band letter mismatch above boundary \(boundary) at lon=\(lon):
            lat=\(latAbove), MGRS=\(mgrsAbove),
            got '\(actualAbove ?? "?")', expected '\(expectedAbove)'
          """
        )
      }
    }
  }

  @Test("Geographic round-trip recovers near band boundaries")
  func roundTripAtBoundaries() throws {
    let testLongitudes: [Double] = [0, 45, 90, -90]
    let offset = 0.001
    let tolerance = 0.001  // degrees

    for boundary in Self.boundaries {
      for lon in testLongitudes {
        for lat in [boundary - offset, boundary + offset] {
          let coord = try GeographicCoordinate(
            latitude: lat,
            longitude: lon
          )
          let mgrs = try coord.mgrs(precision: .oneMeter)
          let recovered = try mgrs.geographic

          #expect(
            recovered.latitude.isApproximatelyEqual(
              to: lat,
              absoluteTolerance: tolerance
            ),
            """
            Latitude round-trip failed at boundary \(boundary), lon=\(lon):
              original=\(lat), recovered=\(recovered.latitude), MGRS=\(mgrs.gridReference)
            """
          )
          #expect(
            recovered.longitude.isApproximatelyEqual(
              to: lon,
              absoluteTolerance: tolerance
            ),
            """
            Longitude round-trip failed at boundary \(boundary), lon=\(lon):
              original=\(lon), recovered=\(recovered.longitude), MGRS=\(mgrs.gridReference)
            """
          )
        }
      }
    }
  }

  // MARK: - Southern Hemisphere Explicit Tests

  @Test("Band letter correct for southern hemisphere interior points")
  func southernHemisphereBandLetters() throws {
    let southLatitudes: [Double] = [
      -71.999, -63.999, -55.999, -47.999, -39.999,
      -31.999, -23.999, -15.999, -7.999, -0.001
    ]
    let testLongitudes: [Double] = [15, 90, -120]

    for lat in southLatitudes {
      for lon in testLongitudes {
        let expected = Self.expectedBandLetter(for: lat)

        let coord = try GeographicCoordinate(
          latitude: lat,
          longitude: lon
        )
        let mgrsRef = try coord.mgrs(precision: .oneMeter)
        let mgrs = mgrsRef.gridReference
        let actual = Self.extractBandLetter(from: mgrs)

        #expect(
          actual == expected,
          """
          Southern hemisphere band letter mismatch:
            lat=\(lat), lon=\(lon), MGRS=\(mgrs),
            got '\(actual ?? "?")', expected '\(expected)'
          """
        )

        // Also verify round-trip
        let recovered = try mgrsRef.geographic

        #expect(
          recovered.latitude.isApproximatelyEqual(
            to: lat,
            absoluteTolerance: 0.001
          ),
          """
          Southern hemisphere latitude round-trip failed:
            lat=\(lat), lon=\(lon), MGRS=\(mgrs),
            recovered=\(recovered.latitude)
          """
        )
        #expect(
          recovered.longitude.isApproximatelyEqual(
            to: lon,
            absoluteTolerance: 0.001
          ),
          """
          Southern hemisphere longitude round-trip failed:
            lat=\(lat), lon=\(lon), MGRS=\(mgrs),
            recovered=\(recovered.longitude)
          """
        )
      }
    }
  }
}
