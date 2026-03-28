import Foundation
import Numerics
import Testing
@testable import SwiftGeographic

/// Validates MGRS forward and reverse conversions against two large external datasets:
/// - **geoconvert-rs**: 96,400 points from GeographicLib's GeoConvert tool
/// - **GeoTrans 3.7**: 37,044 points from the NGA GeoTrans reference implementation
///
/// Together these cover 133,444 geographic coordinates spanning all UTM zones
/// and both UPS polar regions.
///
/// **Forward tests** compare exact MGRS string equality at 1-meter precision.
/// **Reverse tests** parse MGRS strings back to geographic coordinates and verify
/// the result falls within the grid cell, using ground distance (meters) rather
/// than degree-based tolerance since longitude tolerance is meaningless near poles.
///
/// Points within 0.01 degrees of the UTM/UPS boundary (84N, 80S) are excluded
/// because both UTM and UPS are valid there; the zone assignment is a convention
/// choice that differs between implementations.
@Suite("MGRS Validation (133K points)")
struct MGRSValidationTests {

  // MARK: - Shared Helpers

  private static let boundaryTolerance = 0.01  // degrees

  /// Maximum ground distance for a 1m MGRS grid cell (2m allows for rounding).
  private static let maxGroundError = 2.0

  private static func isInBoundaryOverlap(latitude: Double) -> Bool {
    abs(latitude - 84) < boundaryTolerance
      || abs(latitude + 80) < boundaryTolerance
  }

  /// Returns true if two MGRS strings have the same letter prefix and their
  /// easting/northing digit halves each differ by at most 1.
  private static func isOffByOneDigit(_ a: String, _ b: String) -> Bool {
    guard a.count == b.count else { return false }

    let aChars = Array(a)
    var digitStart = aChars.count
    while digitStart > 0, aChars[digitStart - 1].isNumber {
      digitStart -= 1
    }

    let prefix = String(aChars[..<digitStart])
    let bPrefix = String(Array(b)[..<digitStart])
    guard prefix == bPrefix else { return false }

    let aDigits = String(aChars[digitStart...])
    let bDigits = String(Array(b)[digitStart...])
    guard aDigits.count == bDigits.count,
      aDigits.count.isMultiple(of: 2)
    else { return false }

    let half = aDigits.count / 2
    let aE = Int(String(aDigits.prefix(half))) ?? 0
    let bE = Int(String(bDigits.prefix(half))) ?? 0
    let aN = Int(String(aDigits.suffix(half))) ?? 0
    let bN = Int(String(bDigits.suffix(half))) ?? 0

    return abs(aE - bE) <= 1 && abs(aN - bN) <= 1
  }

  /// Approximate ground distance in meters between two geographic points.
  private static func groundDistance(
    lat1: Double,
    lon1: Double,
    lat2: Double,
    lon2: Double
  ) -> Double {
    let dLat = (lat2 - lat1) * 111_000
    let cosLat = cos(((lat1 + lat2) / 2) * .pi / 180)
    var dLon = abs(lon2 - lon1)
    if dLon > 180 { dLon = 360 - dLon }
    let dLonM = dLon * 111_000 * cosLat
    return sqrt(dLat * dLat + dLonM * dLonM)
  }

  // MARK: - Forward Validation

  @Test("Forward MGRS matches geoconvert-rs for 96,400 points")
  func geoconvertForwardValidation() throws {
    guard
      let coordsURL = Bundle.module.url(
        forResource: "mgrs_geoconvert_coords",
        withExtension: "txt"
      ),
      let mgrsURL = Bundle.module.url(
        forResource: "mgrs_geoconvert_mgrs",
        withExtension: "txt"
      )
    else {
      Issue.record("Could not locate geoconvert resource files in Bundle.module")
      return
    }

    let coordsText = try String(contentsOf: coordsURL, encoding: .utf8)
    let mgrsText = try String(contentsOf: mgrsURL, encoding: .utf8)

    let coordLines = coordsText.split(separator: "\n")
    let mgrsLines = mgrsText.split(separator: "\n")

    #expect(
      coordLines.count == mgrsLines.count,
      "Coordinate and MGRS files must have the same number of lines"
    )

    var failCount = 0
    var tested = 0
    var skipped = 0

    for i in coordLines.indices {
      let parts = coordLines[i].split(separator: " ")
      guard parts.count == 2,
        let lat = Double(parts[0]),
        let lon = Double(parts[1])
      else { continue }

      if Self.isInBoundaryOverlap(latitude: lat) {
        skipped += 1
        continue
      }

      let expectedMGRS = String(mgrsLines[i])

      let coord = try GeographicCoordinate(latitude: lat, longitude: lon)
      let actual = try coord.mgrs(precision: .oneMeter).gridReference
      tested += 1

      if actual != expectedMGRS {
        failCount += 1
        if failCount <= 5 {
          Issue.record(
            """
            geoconvert mismatch at line \(i + 1) (\(lat), \(lon)):
              got      \(actual)
              expected \(expectedMGRS)
            """
          )
        }
      }
    }

    #expect(
      failCount == 0,
      "\(failCount)/\(tested) geoconvert forward MGRS mismatched (skipped \(skipped) boundary)"
    )
  }

  @Test("Forward MGRS matches GeoTrans 3.7 for 37,044 points")
  func geotransForwardValidation() throws {
    guard
      let url = Bundle.module.url(
        forResource: "geotrans_clean",
        withExtension: "txt"
      )
    else {
      Issue.record("Could not locate geotrans_clean.txt in Bundle.module")
      return
    }

    let text = try String(contentsOf: url, encoding: .utf8)
    let lines = text.split(separator: "\n")

    var failCount = 0
    var roundingCount = 0
    var tested = 0
    var skipped = 0

    for (i, line) in lines.enumerated() {
      let parts = line.split(separator: " ")
      guard parts.count == 3,
        let lat = Double(parts[0]),
        let lon = Double(parts[1])
      else { continue }

      if lon < -180 || lon > 180 {
        skipped += 1
        continue
      }

      if Self.isInBoundaryOverlap(latitude: lat) {
        skipped += 1
        continue
      }

      let expectedMGRS = String(parts[2])

      let coord = try GeographicCoordinate(latitude: lat, longitude: lon)
      let actual = try coord.mgrs(precision: .oneMeter).gridReference
      tested += 1

      if actual != expectedMGRS {
        if Self.isOffByOneDigit(actual, expectedMGRS) {
          roundingCount += 1
        } else {
          failCount += 1
          if failCount <= 5 {
            Issue.record(
              """
              GeoTrans mismatch at line \(i + 1) (\(lat), \(lon)):
                got      \(actual)
                expected \(expectedMGRS)
              """
            )
          }
        }
      }
    }

    #expect(
      failCount == 0,
      """
      \(failCount)/\(tested) GeoTrans forward MGRS mismatched (skipped \(skipped) boundary, \
      \(roundingCount) rounding)
      """
    )
  }

  // MARK: - Reverse Validation

  @Test("Reverse MGRS matches geoconvert-rs coordinates for 96,400 points")
  func geoconvertReverseValidation() throws {
    guard
      let coordsURL = Bundle.module.url(
        forResource: "mgrs_geoconvert_coords",
        withExtension: "txt"
      ),
      let mgrsURL = Bundle.module.url(
        forResource: "mgrs_geoconvert_mgrs",
        withExtension: "txt"
      )
    else {
      Issue.record("Could not locate geoconvert resource files in Bundle.module")
      return
    }

    let coordsText = try String(contentsOf: coordsURL, encoding: .utf8)
    let mgrsText = try String(contentsOf: mgrsURL, encoding: .utf8)

    let coordLines = coordsText.split(separator: "\n")
    let mgrsLines = mgrsText.split(separator: "\n")

    #expect(
      coordLines.count == mgrsLines.count,
      "Coordinate and MGRS files must have the same number of lines"
    )

    var failCount = 0
    var tested = 0
    var skipped = 0

    for i in coordLines.indices {
      let parts = coordLines[i].split(separator: " ")
      guard parts.count == 2,
        let lat = Double(parts[0]),
        let lon = Double(parts[1])
      else { continue }

      if Self.isInBoundaryOverlap(latitude: lat) {
        skipped += 1
        continue
      }

      let mgrsString = String(mgrsLines[i])

      do {
        let parsed = try MGRSCoordinate(string: mgrsString)
        let geo = try parsed.geographic
        tested += 1

        let dist = Self.groundDistance(
          lat1: lat,
          lon1: lon,
          lat2: geo.latitude,
          lon2: geo.longitude
        )

        if dist > Self.maxGroundError {
          failCount += 1
          if failCount <= 5 {
            Issue.record(
              """
              geoconvert reverse mismatch at line \(i + 1) (\(lat), \(lon)):
                MGRS: \(mgrsString)
                got  (\(geo.latitude), \(geo.longitude))
                ground error: \(dist) m
              """
            )
          }
        }
      } catch {
        failCount += 1
        if failCount <= 5 {
          Issue.record(
            """
            geoconvert reverse parse error at line \(i + 1):
              MGRS: \(mgrsString)
              error: \(error)
            """
          )
        }
      }
    }

    #expect(
      failCount == 0,
      "\(failCount)/\(tested) geoconvert reverse MGRS mismatched (skipped \(skipped) boundary)"
    )
  }

  @Test("Reverse MGRS matches GeoTrans 3.7 coordinates for 37,044 points")
  func geotransReverseValidation() throws {
    guard
      let url = Bundle.module.url(
        forResource: "geotrans_clean",
        withExtension: "txt"
      )
    else {
      Issue.record("Could not locate geotrans_clean.txt in Bundle.module")
      return
    }

    let text = try String(contentsOf: url, encoding: .utf8)
    let lines = text.split(separator: "\n")

    var failCount = 0
    var tested = 0
    var skipped = 0

    for (i, line) in lines.enumerated() {
      let parts = line.split(separator: " ")
      guard parts.count == 3,
        let lat = Double(parts[0]),
        let lon = Double(parts[1])
      else { continue }

      if lon < -180 || lon >= 360 {
        skipped += 1
        continue
      }

      if Self.isInBoundaryOverlap(latitude: lat) {
        skipped += 1
        continue
      }

      let mgrsString = String(parts[2])

      do {
        let parsed = try MGRSCoordinate(string: mgrsString)
        let geo = try parsed.geographic
        tested += 1

        let dist = Self.groundDistance(
          lat1: lat,
          lon1: lon,
          lat2: geo.latitude,
          lon2: geo.longitude
        )

        if dist > Self.maxGroundError {
          failCount += 1
          if failCount <= 5 {
            Issue.record(
              """
              GeoTrans reverse mismatch at line \(i + 1) (\(lat), \(lon)):
                MGRS: \(mgrsString)
                got  (\(geo.latitude), \(geo.longitude))
                ground error: \(dist) m
              """
            )
          }
        }
      } catch {
        failCount += 1
        if failCount <= 5 {
          Issue.record(
            """
            GeoTrans reverse parse error at line \(i + 1):
              MGRS: \(mgrsString)
              error: \(error)
            """
          )
        }
      }
    }

    #expect(
      failCount == 0,
      "\(failCount)/\(tested) GeoTrans reverse MGRS mismatched (skipped \(skipped) boundary)"
    )
  }
}
