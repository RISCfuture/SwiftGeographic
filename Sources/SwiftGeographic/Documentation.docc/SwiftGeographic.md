# ``SwiftGeographic``

@Metadata {
    @DisplayName("SwiftGeographic")
}

Geodetic coordinate conversions between geographic (latitude/longitude), UTM, UPS, and MGRS coordinate systems.

## Overview

SwiftGeographic provides accurate, type-safe conversions between the coordinate
systems used in geodesy, cartography, and military mapping. It implements the
Transverse Mercator projection using Karney's 6th-order Krueger series and the
Polar Stereographic projection following Snyder's formulation, both on the WGS84
ellipsoid.

Start with a ``GeographicCoordinate`` and convert to any supported system:

```swift
let coord = try GeographicCoordinate(latitude: 48.8566, longitude: 2.3522)
let utm = try coord.utm           // UTM zone 31N
let mgrs = try coord.mgrs()       // MGRSCoordinate: "31UDQ483009511"
```

Parse an MGRS grid reference back into geographic coordinates:

```swift
let mgrs = try MGRSCoordinate(string: "31UDQ4830009511")
let geo = try mgrs.geographic
```

The library handles the Norway and Svalbard zone exceptions, automatically
selects UTM or UPS based on latitude, and supports MGRS precision levels from
100 km down to 1 micrometer.

## Topics

### Essentials

- <doc:GettingStarted>
- ``GeographicCoordinate``
- ``SwiftGeographicError``

### Coordinate Systems

- <doc:CoordinateSystems>
- ``UTMCoordinate``
- ``UPSCoordinate``
- ``MGRSCoordinate``

### Map Projections

- <doc:Projections>
- ``TransverseMercator``
- ``PolarStereographic``
- ``ProjectionResult``

### Unified Coordinate Operations

- ``UTMUPS``

### Supporting Types

- ``Hemisphere``
- ``MGRSPrecision``
