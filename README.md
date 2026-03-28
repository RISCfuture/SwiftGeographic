# SwiftGeographic

[![CI](https://github.com/riscfuture/SwiftGeographic/actions/workflows/ci.yml/badge.svg)](https://github.com/riscfuture/SwiftGeographic/actions/workflows/ci.yml)
[![Documentation](https://github.com/riscfuture/SwiftGeographic/actions/workflows/documentation.yml/badge.svg)](https://riscfuture.github.io/SwiftGeographic/)
[![Swift 6.0+](https://img.shields.io/badge/Swift-6.0+-orange.svg)](https://swift.org)
[![Platforms](https://img.shields.io/badge/Platforms-macOS%20|%20iOS%20|%20tvOS%20|%20watchOS%20|%20visionOS%20|%20Linux-blue.svg)](https://swift.org)

Accurate geodetic coordinate conversions between geographic (latitude/longitude),
UTM, UPS, and MGRS coordinate systems for Swift.

## Features

- **High-precision projections**: Transverse Mercator via Karney's 6th-order
  Krueger series (sub-nanometer accuracy) and Polar Stereographic via Snyder's
  formulation
- **Full coordinate system support**: Convert between geographic, UTM, UPS, and
  MGRS coordinates on the WGS84 ellipsoid
- **MGRS at any precision**: 12 precision levels from 100 km down to
  1 micrometer
- **Zone exceptions handled**: Norway (zone 32V) and Svalbard
  (31X/33X/35X/37X) exceptions are applied automatically
- **Polar coverage**: UPS seamlessly covers latitudes above 84N and below 80S
- **Swift 6 concurrency**: All types are `Sendable`
- **Type safety**: Strongly typed coordinate structs with validation on creation
- **No dependencies**: Pure Swift implementation with zero external dependencies

## Requirements

- Swift 6.0+
- macOS 13+, iOS 16+, tvOS 16+, watchOS 9+, or visionOS 1+

## Installation

### Swift Package Manager

Add SwiftGeographic to your `Package.swift`:

```swift
dependencies: [
    .package(url: "https://github.com/riscfuture/SwiftGeographic.git", from: "1.0.0")
]
```

Then add the dependency to your target:

```swift
.target(
    name: "YourTarget",
    dependencies: ["SwiftGeographic"]
)
```

Or in Xcode: File > Add Package Dependencies > Enter the repository URL.

## Quick Start

### Geographic to UTM

```swift
import SwiftGeographic

let coord = try GeographicCoordinate(latitude: 40.7128, longitude: -74.0060)
let utm = try coord.utm

print(utm.zone)       // 18
print(utm.hemisphere)  // .north
print(utm.easting)     // ~583960
print(utm.northing)    // ~4507523
```

### Geographic to MGRS

```swift
let mgrs = try coord.mgrs()                         // 1-meter precision
let mgrs10m = try coord.mgrs(precision: .tenMeter)  // 10-meter precision
```

### Parsing MGRS

```swift
let parsed = try MGRSCoordinate(string: "18TXL8396007523")
let geo = try parsed.geographic
print(geo.latitude)   // ~40.7128
print(geo.longitude)  // ~-74.0060
```

### Polar Regions (UPS)

```swift
let pole = try GeographicCoordinate(latitude: 89.0, longitude: 0.0)
let ups = try pole.ups
let mgrs = try pole.mgrs()
```

### Round-Tripping

```swift
let original = try GeographicCoordinate(latitude: 48.8566, longitude: 2.3522)
let utm = try original.utm
let restored = try utm.geographic
// restored is within nanometers of original
```

## Running Tests

```bash
swift test
```

## Building Documentation

Generate documentation locally with:

```bash
swift package generate-documentation --target SwiftGeographic
```

Preview it in a browser:

```bash
swift package --disable-sandbox preview-documentation --target SwiftGeographic
```

## Documentation

Full documentation is available at
[riscfuture.github.io/SwiftGeographic](https://riscfuture.github.io/SwiftGeographic/).

## License

SwiftGeographic is released under the MIT License. See
[LICENSE.md](LICENSE.md) for details.
