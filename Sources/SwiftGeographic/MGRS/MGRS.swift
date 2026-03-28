import Foundation

/// Internal MGRS encoding/decoding engine.
///
/// Handles the conversion between UTM/UPS coordinates and MGRS strings.
/// The public interface is through ``MGRSCoordinate``.
enum MGRSEngine {

  private static let tile = Constants.tile  // 100,000 m

  // MARK: - Forward (UTM/UPS -> MGRS)

  /// Encodes UTM/UPS coordinates into an ``MGRSCoordinate``.
  ///
  /// - Parameters:
  ///   - zone: UTM zone (1–60) or 0 for UPS.
  ///   - hemisphere: The hemisphere.
  ///   - easting: Easting in meters (including false easting).
  ///   - northing: Northing in meters (including false northing).
  ///   - latitude: Known latitude (used to determine band letter). Pass nil
  ///     to estimate from northing.
  ///   - precision: The desired MGRS precision level.
  /// - Returns: The ``MGRSCoordinate``.
  static func forward(
    zone: Int,
    hemisphere: Hemisphere,
    easting: Double,
    northing: Double,
    latitude: Double? = nil,
    precision: MGRSPrecision
  ) -> MGRSCoordinate {
    if zone == 0 {
      return forwardUPS(
        hemisphere: hemisphere,
        easting: easting,
        northing: northing,
        precision: precision
      )
    }

    return forwardUTM(
      zone: zone,
      hemisphere: hemisphere,
      easting: easting,
      northing: northing,
      latitude: latitude,
      precision: precision
    )
  }

  private static func forwardUTM(
    zone: Int,
    hemisphere: Hemisphere,
    easting: Double,
    northing: Double,
    latitude: Double?,
    precision: MGRSPrecision
  ) -> MGRSCoordinate {
    // Determine latitude band
    let bandLetter: Character
    if let lat = latitude {
      bandLetter = latitudeBandLetter(for: lat)
    } else {
      bandLetter = estimateLatitudeBand(
        northing: northing,
        hemisphere: hemisphere
      )
    }

    // Column index (0-based within the 100 km grid)
    let colIndex = Int(floor(easting / tile)) - 1

    // Row index (0-based, cycled through the 20-letter sequence)
    let rowNorthing = Int(floor(northing / tile))
    let shift = zone.isMultiple(of: 2) ? LetterTables.utmEvenRowShift : 0
    let rowIndex = (rowNorthing + shift) % LetterTables.utmRowPeriod

    // Letters
    let setIndex = (zone - 1) % 3
    let colLetter = LetterTables.utmColumnLetters[setIndex][max(0, min(colIndex, 7))]
    let rowLetter = LetterTables.utmRowLetters[max(0, min(rowIndex, 19))]

    let zoneStr = String(format: "%02d", zone)
    let gridZone = "\(zoneStr)\(bandLetter)"
    let squareIdentifier = "\(colLetter)\(rowLetter)"

    var eastRemainder = easting.truncatingRemainder(dividingBy: tile)
    if eastRemainder < 0 { eastRemainder += tile }
    var northRemainder = northing.truncatingRemainder(dividingBy: tile)
    if northRemainder < 0 { northRemainder += tile }

    return MGRSCoordinate(
      gridZone: gridZone,
      squareIdentifier: squareIdentifier,
      easting: eastRemainder,
      northing: northRemainder,
      precision: precision,
      utmZone: zone,
      hemisphere: hemisphere,
      fullEasting: easting,
      fullNorthing: northing
    )
  }

  private static func forwardUPS(
    hemisphere: Hemisphere,
    easting: Double,
    northing: Double,
    precision: MGRSPrecision
  ) -> MGRSCoordinate {
    let isNorth = hemisphere == .north
    let isEast = easting >= Constants.upsFalseEastingNorthing

    // Band letter
    let bandLetter: Character
    if isNorth {
      bandLetter = isEast ? "Z" : "Y"
    } else {
      bandLetter = isEast ? "B" : "A"
    }

    // Quadrant index for column letter lookup
    let quadrant: Int
    if isNorth {
      quadrant = isEast ? 3 : 2
    } else {
      quadrant = isEast ? 1 : 0
    }

    // Column and row indices within the 100 km grid
    let cols = LetterTables.upsColumnLetters[quadrant]
    let rows = LetterTables.upsRowLetters[isNorth ? 1 : 0]

    // For UPS, compute column/row from absolute grid position
    let colKm = Int(floor(easting / tile))
    let rowKm = Int(floor(northing / tile))

    // Column offset: east side always starts at tile 20 (upseasting),
    // west side starts at tile 13 (north) or 8 (south).
    let colOffset: Int
    if isEast {
      colOffset = colKm - 20
    } else if isNorth {
      colOffset = colKm - 13
    } else {
      colOffset = colKm - 8
    }
    let colLetter = cols[max(0, min(colOffset, cols.count - 1))]

    // Row offset: north starts at tile 13, south at tile 8.
    let rowOffset = rowKm - (isNorth ? 13 : 8)
    let rowLetter = rows[max(0, min(rowOffset, rows.count - 1))]

    let gridZone = String(bandLetter)
    let squareIdentifier = "\(colLetter)\(rowLetter)"

    var eastRemainder = easting.truncatingRemainder(dividingBy: tile)
    if eastRemainder < 0 { eastRemainder += tile }
    var northRemainder = northing.truncatingRemainder(dividingBy: tile)
    if northRemainder < 0 { northRemainder += tile }

    return MGRSCoordinate(
      gridZone: gridZone,
      squareIdentifier: squareIdentifier,
      easting: eastRemainder,
      northing: northRemainder,
      precision: precision,
      utmZone: 0,
      hemisphere: hemisphere,
      fullEasting: easting,
      fullNorthing: northing
    )
  }

  // MARK: - Reverse (MGRS -> UTM/UPS)

  /// Decodes an MGRS string into UTM/UPS coordinates.
  ///
  /// - Parameter mgrs: An MGRS string (e.g., "18SUJ2337106519").
  /// - Returns: A tuple with zone, hemisphere, easting, northing, and
  ///   precision.
  /// - Throws: ``SwiftGeographicError/invalidMGRS(_:)`` if the string
  ///   cannot be parsed.
  static func reverse(
    _ mgrs: String
  ) throws -> (
    zone: Int, hemisphere: Hemisphere, easting: Double,
    northing: Double, precision: MGRSPrecision
  ) {
    let chars = Array(mgrs.uppercased())
    guard !chars.isEmpty else {
      throw SwiftGeographicError.invalidMGRS(mgrs)
    }

    var index = 0

    // Parse zone number (0–2 digits)
    var zone = 0
    while index < chars.count, chars[index].isNumber {
      zone = zone * 10 + Int(String(chars[index]))!
      index += 1
    }

    guard index < chars.count else {
      throw SwiftGeographicError.invalidMGRS(mgrs)
    }

    // Parse band letter
    let bandChar = chars[index]
    index += 1

    let isUPS = zone == 0 || "ABYZ".contains(bandChar)

    if isUPS {
      return try reverseUPS(
        chars: chars,
        index: index,
        bandChar: bandChar,
        originalMGRS: mgrs
      )
    }

    return try reverseUTM(
      chars: chars,
      index: index,
      zone: zone,
      bandChar: bandChar,
      originalMGRS: mgrs
    )
  }

  private static func reverseUTM(
    chars: [Character],
    index startIndex: Int,
    zone: Int,
    bandChar: Character,
    originalMGRS: String
  ) throws -> (
    zone: Int, hemisphere: Hemisphere, easting: Double,
    northing: Double, precision: MGRSPrecision
  ) {
    guard zone >= 1, zone <= 60 else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    // Determine hemisphere from band letter
    let hemisphere: Hemisphere = bandChar >= "N" ? .north : .south

    guard let bandIndex = LetterTables.latitudeBandIndex(of: bandChar) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    var index = startIndex

    // If we only have the grid zone designator, return a representative point
    if index >= chars.count {
      let lat = -80.0 + Double(bandIndex) * 8 + 4
      let lon = UTMUPS.centralMeridian(zone: zone)
      let result = try UTMUPS.forward(latitude: lat, longitude: lon, zone: zone)
      return (zone, hemisphere, result.easting, result.northing, .hundredKilometer)
    }

    // Parse column letter
    guard index < chars.count else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }
    let colChar = chars[index]
    index += 1

    // Parse row letter
    guard index < chars.count else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }
    let rowChar = chars[index]
    index += 1

    // Decode column
    let setIndex = (zone - 1) % 3
    let colSet = LetterTables.utmColumnLetters[setIndex]
    guard let colIndex = colSet.firstIndex(of: colChar) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    // Decode row
    guard let rawRowIndex = LetterTables.utmRowIndex(of: rowChar) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    // Parse remaining digits (must be even count)
    let remainingDigits = String(chars[index...])
    guard remainingDigits.count.isMultiple(of: 2),
      remainingDigits.allSatisfy(\.isNumber)
    else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    let prec = remainingDigits.count / 2
    guard let precision = MGRSPrecision(rawValue: prec) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    let eastDigits: Double
    let northDigits: Double

    if prec > 0 {
      let half = remainingDigits.count / 2
      let eastStr = String(remainingDigits.prefix(half))
      let northStr = String(remainingDigits.suffix(half))
      eastDigits = Double(eastStr)! * pow(10, Double(5 - prec))
      northDigits = Double(northStr)! * pow(10, Double(5 - prec))
    } else {
      eastDigits = 0
      northDigits = 0
    }

    // Compute easting
    let easting = (Double(colIndex) + 1) * tile + eastDigits

    // Compute northing: disambiguate the 2,000 km row cycle
    let shift = zone.isMultiple(of: 2) ? LetterTables.utmEvenRowShift : 0
    let adjustedRow =
      (rawRowIndex - shift + LetterTables.utmRowPeriod)
      % LetterTables.utmRowPeriod

    let baseNorthing = Double(adjustedRow) * tile + northDigits

    // Find the correct northing by matching the latitude band
    let bandCenterLat = -80.0 + Double(bandIndex) * 8 + 4
    let bandCenterNorthing = estimateNorthingForLatitude(bandCenterLat)

    // The row repeats every 2,000 km. Find the offset that puts
    // baseNorthing closest to the band center.
    let period = Double(LetterTables.utmRowPeriod) * tile  // 2,000,000 m
    var northing = baseNorthing
    let offset = ((bandCenterNorthing - baseNorthing) / period).rounded() * period
    northing += offset

    // Adjust for southern hemisphere
    if hemisphere == .south {
      // Northing is measured from equator for band calculations
      // but stored with false northing of 10,000,000
    }

    return (zone, hemisphere, easting, northing, precision)
  }

  private static func reverseUPS(
    chars: [Character],
    index startIndex: Int,
    bandChar: Character,
    originalMGRS: String
  ) throws -> (
    zone: Int, hemisphere: Hemisphere, easting: Double,
    northing: Double, precision: MGRSPrecision
  ) {
    let isNorth = bandChar == "Y" || bandChar == "Z"
    let hemisphere: Hemisphere = isNorth ? .north : .south
    let isEast = bandChar == "B" || bandChar == "Z"

    var index = startIndex

    guard index < chars.count else {
      // Zone designation only
      let lat: Double = isNorth ? 87 : -87
      let result = try UTMUPS.forward(latitude: lat, longitude: 0)
      return (0, hemisphere, result.easting, result.northing, .hundredKilometer)
    }

    // Parse column letter
    let colChar = chars[index]
    index += 1

    guard index < chars.count else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    // Parse row letter
    let rowChar = chars[index]
    index += 1

    // Decode column
    let quadrant: Int
    if isNorth {
      quadrant = isEast ? 3 : 2
    } else {
      quadrant = isEast ? 1 : 0
    }

    let cols = LetterTables.upsColumnLetters[quadrant]
    guard let colOffset = cols.firstIndex(of: colChar) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    // Decode row
    let rows = LetterTables.upsRowLetters[isNorth ? 1 : 0]
    guard let rowOffset = rows.firstIndex(of: rowChar) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    // Parse digits
    let remainingDigits = String(chars[index...])
    guard remainingDigits.count.isMultiple(of: 2),
      remainingDigits.allSatisfy(\.isNumber)
    else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    let prec = remainingDigits.count / 2
    guard let precision = MGRSPrecision(rawValue: prec) else {
      throw SwiftGeographicError.invalidMGRS(originalMGRS)
    }

    let eastDigits: Double
    let northDigits: Double
    if prec > 0 {
      let half = remainingDigits.count / 2
      let eastStr = String(remainingDigits.prefix(half))
      let northStr = String(remainingDigits.suffix(half))
      eastDigits = Double(eastStr)! * pow(10, Double(5 - prec))
      northDigits = Double(northStr)! * pow(10, Double(5 - prec))
    } else {
      eastDigits = 0
      northDigits = 0
    }

    // Reconstruct easting/northing.
    // East side always uses base 20 (upseasting), west uses 13 (north) or 8 (south).
    let colBase: Int
    if isEast {
      colBase = 20
    } else if isNorth {
      colBase = 13
    } else {
      colBase = 8
    }
    let easting = Double(colBase + colOffset) * tile + eastDigits

    let rowBase: Int = isNorth ? 13 : 8
    let northing = Double(rowBase + rowOffset) * tile + northDigits

    return (0, hemisphere, easting, northing, precision)
  }

  // MARK: - Helpers

  /// Returns the latitude band letter for a given latitude.
  static func latitudeBandLetter(for latitude: Double) -> Character {
    let index = min(
      Int(floor((latitude + 80) / 8)),
      LetterTables.latitudeBandLetters.count - 1
    )
    return LetterTables.latitudeBandLetters[max(0, index)]
  }

  /// Estimates the latitude band from northing and hemisphere.
  private static func estimateLatitudeBand(
    northing: Double,
    hemisphere: Hemisphere
  ) -> Character {
    // Approximate latitude from northing
    let n =
      hemisphere == .south
      ? northing - Constants.utmFalseNorthingSouth : northing
    let latApprox = n / 111_000  // ~111 km per degree of latitude
    return latitudeBandLetter(for: latApprox)
  }

  /// Estimates the northing at a given latitude (approximate, for
  /// disambiguation).
  private static func estimateNorthingForLatitude(_ latitude: Double) -> Double {
    // Use a simple approximation: northing ≈ latitude * 111,000 m/degree
    // This is good enough for the 2,000 km disambiguation
    if latitude >= 0 {
      return latitude * 111_000
    }

    return latitude * 111_000 + Constants.utmFalseNorthingSouth
  }

  /// Formats the easting/northing digits at the given precision.
  static func formatDigits(
    easting: Double,
    northing: Double,
    precision: MGRSPrecision
  ) -> String {
    let prec = precision.rawValue
    guard prec > 0 else { return "" }

    // Clamp remainders to [0, tile) to avoid negative values from
    // floating-point truncation at sub-meter precisions.
    var eastRemainder = easting.truncatingRemainder(dividingBy: tile)
    if eastRemainder < 0 { eastRemainder += tile }
    var northRemainder = northing.truncatingRemainder(dividingBy: tile)
    if northRemainder < 0 { northRemainder += tile }

    let divisor = pow(10, Double(5 - prec))
    let maxDigit = Int(pow(10, Double(prec))) - 1
    let eastDigit = min(Int(floor(eastRemainder / divisor)), maxDigit)
    let northDigit = min(Int(floor(northRemainder / divisor)), maxDigit)

    let format = "%0\(prec)ld"
    let eastStr = String(format: format, eastDigit)
    let northStr = String(format: format, northDigit)

    return eastStr + northStr
  }
}
