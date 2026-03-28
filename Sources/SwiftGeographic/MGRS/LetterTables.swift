/// MGRS letter encoding/decoding tables.
///
/// Contains the UTM column letters (3 sets of 8), UTM row letters
/// (20-letter cycle), UPS column and row letters, latitude band letters,
/// and UPS band letters. Letters I and O are never used (military
/// alphabet convention).
enum LetterTables {

  /// UTM column letters per set, indexed by `(zone - 1) % 3`.
  ///
  /// Each set has 8 letters corresponding to 100 km columns 1–8.
  static let utmColumnLetters: [[Character]] = [
    ["A", "B", "C", "D", "E", "F", "G", "H"],
    ["J", "K", "L", "M", "N", "P", "Q", "R"],
    ["S", "T", "U", "V", "W", "X", "Y", "Z"]
  ]

  /// UTM row letters: 20-letter cycle A–V (skipping I and O).
  static let utmRowLetters: [Character] = [
    "A", "B", "C", "D", "E", "F", "G", "H", "J", "K",
    "L", "M", "N", "P", "Q", "R", "S", "T", "U", "V"
  ]

  /// Latitude band letters C–X (skipping I and O), covering 80S to 84N.
  ///
  /// Each band spans 8 degrees of latitude, except X which spans 12.
  static let latitudeBandLetters: [Character] = [
    "C", "D", "E", "F", "G", "H", "J", "K", "L", "M",
    "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X"
  ]

  /// UPS column letters for each quadrant.
  ///
  /// Indexed as: [0] = south-west, [1] = south-east,
  /// [2] = north-west, [3] = north-east.
  static let upsColumnLetters: [[Character]] = [
    ["J", "K", "L", "P", "Q", "R", "S", "T", "U", "X", "Y", "Z"],
    ["A", "B", "C", "F", "G", "H", "J", "K", "L", "P", "Q", "R"],
    ["R", "S", "T", "U", "X", "Y", "Z"],
    ["A", "B", "C", "F", "G", "H", "J"]
  ]

  /// UPS row letters for each hemisphere.
  ///
  /// Indexed as: [0] = south (24 letters), [1] = north (14 letters).
  static let upsRowLetters: [[Character]] = [
    [
      "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M",
      "N", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z"
    ],
    [
      "A", "B", "C", "D", "E", "F", "G", "H", "J", "K", "L", "M",
      "N", "P"
    ]
  ]

  /// UPS band letters.
  ///
  /// A and B are south, Y and Z are north. The distinction between the two
  /// letters in each pair is east vs. west of the prime meridian.
  static let upsBandLetters: [Character] = ["A", "B", "Y", "Z"]

  /// The minimum northing for each latitude band (in units of 100 km).
  ///
  /// Indexed by band index (0 = band C, 19 = band X). Band X spans 12
  /// degrees so its maximum northing is larger.
  static let latitudeBandNorthings: [Double] = [
    11_00_000, 20_00_000, 28_00_000, 37_00_000, 46_00_000,
    55_00_000, 64_00_000, 73_00_000, 82_00_000, 91_00_000,
    0, 8_00_000, 17_00_000, 26_00_000, 35_00_000,
    44_00_000, 53_00_000, 62_00_000, 71_00_000, 80_00_000
  ]

  /// Row letter period: 20 letters = 2,000 km of northing.
  static let utmRowPeriod = 20

  /// Even zones shift row letters by 5.
  static let utmEvenRowShift = 5

  /// Returns the index of a character in the row letter array, or nil.
  static func utmRowIndex(of letter: Character) -> Int? {
    utmRowLetters.firstIndex(of: letter)
  }

  /// Returns the index of a character in the latitude band array, or nil.
  static func latitudeBandIndex(of letter: Character) -> Int? {
    latitudeBandLetters.firstIndex(of: letter)
  }
}
