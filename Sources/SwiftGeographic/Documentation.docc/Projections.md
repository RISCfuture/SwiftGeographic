# Projections

Learn about the map projections used by SwiftGeographic and when to use them directly.

## Overview

SwiftGeographic includes two map projection implementations that underpin the
UTM and UPS coordinate systems. In most cases you will not need to use these
projections directly -- the coordinate types (``GeographicCoordinate``,
``UTMCoordinate``, ``UPSCoordinate``) handle projection internally. However,
direct access is available for custom ellipsoids, non-standard scale factors,
or applications that need raw projection output (convergence and scale).

### Transverse Mercator

``TransverseMercator`` implements Karney's 6th-order Krueger series expansion
of the Transverse Mercator projection. This method achieves sub-nanometer
accuracy for the full UTM range and avoids the numerical instability of the
traditional series at high latitudes.

The projection maps a strip of the ellipsoid centered on a given meridian onto
a plane. UTM uses this with a central scale factor of 0.9996 on the WGS84
ellipsoid, available as the ``TransverseMercator/utm`` singleton.

```swift
// Forward: geographic to projected
let result = TransverseMercator.utm.forward(
    centralMeridian: -75.0,
    latitude: 40.7128,
    longitude: -74.0060
)
print(result.x)           // easting in meters (no false easting)
print(result.y)           // northing in meters (no false northing)
print(result.convergence) // meridian convergence in degrees
print(result.scale)       // point scale factor

// Reverse: projected to geographic
let inv = TransverseMercator.utm.reverse(
    centralMeridian: -75.0,
    easting: result.x,
    northing: result.y
)
print(inv.x)  // latitude in degrees
print(inv.y)  // longitude in degrees
```

For a non-standard ellipsoid or scale factor, create your own instance:

```swift
let custom = TransverseMercator(
    semiMajorAxis: 6378388.0,       // International 1924
    flattening: 1 / 297.0,
    centralScale: 0.9996
)
```

### Polar Stereographic

``PolarStereographic`` implements the Polar Stereographic projection following
Snyder's formulation. It projects the region around a pole onto a tangent plane,
providing low distortion at high latitudes where the Transverse Mercator becomes
impractical.

UPS uses this with a central scale factor of 0.994 on the WGS84 ellipsoid,
available as the ``PolarStereographic/ups`` singleton.

```swift
// Forward: geographic to projected
let result = PolarStereographic.ups.forward(
    isNorth: true,
    latitude: 89.0,
    longitude: 45.0
)
print(result.x)  // easting in meters (no false easting)
print(result.y)  // northing in meters (no false northing)

// Reverse: projected to geographic
let inv = PolarStereographic.ups.reverse(
    isNorth: true,
    easting: result.x,
    northing: result.y
)
print(inv.x)  // latitude in degrees
print(inv.y)  // longitude in degrees
```

### Projection Result

Both projections return a ``ProjectionResult`` containing four values:

- **x**: easting (forward) or latitude (reverse)
- **y**: northing (forward) or longitude (reverse)
- **convergence**: the angle between grid north and true north, in degrees
- **scale**: the point scale factor (dimensionless), indicating local
  distortion; a value of 1.0 means no distortion

### When to Use Projections Directly

Use the coordinate types (``GeographicCoordinate``, ``UTMCoordinate``, etc.)
for typical conversions. They handle false easting/northing offsets, zone
selection, and hemisphere conventions automatically.

Use the projection structs directly when you need:

- **Custom ellipsoid parameters**: create a ``TransverseMercator`` or
  ``PolarStereographic`` with non-WGS84 values
- **Convergence and scale**: the coordinate types do not expose these;
  access them through the ``ProjectionResult``
- **Raw projection coordinates**: easting/northing without false offsets,
  useful for custom grid systems

## Topics

### Projection Types

- ``TransverseMercator``
- ``PolarStereographic``

### Result

- ``ProjectionResult``
