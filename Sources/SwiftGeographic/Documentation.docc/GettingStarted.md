# Getting Started

Learn how to convert between geographic, UTM, UPS, and MGRS coordinates.

## Overview

SwiftGeographic makes it straightforward to work with the coordinate systems
used in geodesy and military mapping. All conversions are performed on the WGS84
ellipsoid and are accurate to sub-nanometer precision for the full UTM range.

### Creating a Geographic Coordinate

Start by creating a ``GeographicCoordinate`` from decimal degrees. Latitude must
be in the range [-90, 90] and longitude in [-180, 180]. The initializer
validates these ranges and throws if either is out of bounds.

```swift
import SwiftGeographic

let newYork = try GeographicCoordinate(latitude: 40.7128, longitude: -74.0060)
let tokyo = try GeographicCoordinate(latitude: 35.6762, longitude: 139.6503)
```

### Converting to UTM

Access the ``GeographicCoordinate/utm`` property to convert to UTM. The standard
zone is selected automatically, including the Norway and Svalbard exceptions.

```swift
let utm = try newYork.utm
print(utm.zone)        // 18
print(utm.hemisphere)  // .north
print(utm.easting)     // ~583960
print(utm.northing)    // ~4507523
```

Convert back to geographic coordinates at any time:

```swift
let geo = try utm.geographic
```

### Converting to MGRS

Use ``GeographicCoordinate/mgrs(precision:)`` to get an ``MGRSCoordinate``.
The default precision is ``MGRSPrecision/oneMeter`` (5 digits per axis).

```swift
// 1-meter precision (default)
let mgrs = try newYork.mgrs()
print(mgrs.gridReference)  // "18TXL8396007523"
print(mgrs.gridZone)       // "18T"

// Other precisions
let mgrs10m = try newYork.mgrs(precision: .tenMeter)
let mgrs1km = try newYork.mgrs(precision: .oneKilometer)
```

### Parsing an MGRS String

Create an ``MGRSCoordinate`` from any valid MGRS string. The parser accepts
strings at all precision levels.

```swift
let parsed = try MGRSCoordinate(string: "18TXL8396007523")
print(parsed.gridZone)          // "18T"
print(parsed.squareIdentifier)  // "XL"
print(parsed.precision)         // .oneMeter

// Convert to geographic
let geo = try parsed.geographic

// Convert to UTM (non-polar coordinates only)
let utm = try parsed.utm

// Get the MGRS string back
print(parsed.gridReference)     // "18TXL8396007523"
```

### Working with UPS for Polar Regions

Coordinates in the polar regions (above 84N or below 80S) fall outside the UTM
grid. Use ``UPSCoordinate`` for these areas. The ``GeographicCoordinate/ups``
property converts any location to UPS.

```swift
let northPole = try GeographicCoordinate(latitude: 89.0, longitude: 0.0)
let ups = try northPole.ups
print(ups.hemisphere)  // .north
print(ups.easting)     // ~2000000
print(ups.northing)    // ~1889185

// Convert back
let geo = try ups.geographic
```

Polar MGRS coordinates work the same way:

```swift
let polarMGRS = try northPole.mgrs()
print(polarMGRS.isPolar)  // true
```

### Error Handling

All coordinate conversions throw ``SwiftGeographicError`` when inputs are
invalid. Handle errors explicitly to provide useful diagnostics.

```swift
do {
    let coord = try GeographicCoordinate(latitude: 100, longitude: 0)
} catch SwiftGeographicError.invalidLatitude(let lat) {
    print("Latitude \(lat) is out of range")
}

do {
    let mgrs = try MGRSCoordinate(string: "INVALID")
} catch SwiftGeographicError.invalidMGRS(let str) {
    print("Could not parse MGRS string: \(str)")
}
```

The error cases include:

| Error | Cause |
| --- | --- |
| ``SwiftGeographicError/invalidLatitude(_:)`` | Latitude outside [-90, 90] |
| ``SwiftGeographicError/invalidLongitude(_:)`` | Longitude outside [-180, 180] |
| ``SwiftGeographicError/invalidZone(_:)`` | UTM zone outside [1, 60] |
| ``SwiftGeographicError/invalidMGRS(_:)`` | Unparseable MGRS string |
| ``SwiftGeographicError/invalidUPSCoordinate`` | UPS coordinates out of range |
| ``SwiftGeographicError/outOfRange`` | Coordinate outside the domain of the requested conversion |
