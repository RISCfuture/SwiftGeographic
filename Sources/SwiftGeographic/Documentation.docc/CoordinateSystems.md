# Coordinate Systems

Understand the UTM, UPS, and MGRS coordinate systems and how they relate.

## Overview

SwiftGeographic supports four coordinate systems, each suited to different use
cases. All conversions use the WGS84 ellipsoid.

### Universal Transverse Mercator (UTM)

UTM divides the Earth between 80S and 84N latitude into 60 zones, each 6 degrees
of longitude wide. Each zone uses a Transverse Mercator projection with a scale
factor of 0.9996 on its central meridian. Positions are given in meters as
easting and northing.

A ``UTMCoordinate`` contains four components:

- **Zone** (1--60): identifies the 6-degree longitude band
- **Hemisphere** (``Hemisphere/north`` or ``Hemisphere/south``): determines
  whether the false northing offset is applied
- **Easting**: meters east of the zone's central meridian, with a 500 km false
  easting so that all values are positive
- **Northing**: meters north of the equator; in the southern hemisphere, a
  10,000 km false northing is added

The central meridian for any zone is computed as `6 * zone - 183` degrees.
Access it via ``UTMCoordinate/centralMeridian``.

#### Norway and Svalbard Exceptions

Two regions deviate from the standard 6-degree zone scheme:

- **Norway (56--64N):** Zone 31 is narrowed and zone 32 is widened so that
  all of southwestern Norway falls within a single zone. Longitudes at or east
  of 3E in this latitude band use zone 32 instead of 31.

- **Svalbard (72--84N):** Zones 32, 34, and 36 are eliminated. Instead,
  zones 31, 33, 35, and 37 are widened to cover the Svalbard archipelago,
  avoiding narrow zones at high latitudes.

The ``UTMUPS/standardZone(latitude:longitude:)`` method implements these
exceptions automatically.

### Universal Polar Stereographic (UPS)

UPS covers the polar regions that UTM does not: latitudes at or above 84N and
below 80S. It uses a Polar Stereographic projection centered on each pole with a
scale factor of 0.994. A ``UPSCoordinate`` contains:

- **Hemisphere**: which pole the projection is centered on
- **Easting** and **northing**: meters from the pole, each with a 2,000 km
  false easting/northing

In the ``UTMUPS`` enum, UPS is represented as zone 0.

### Military Grid Reference System (MGRS)

MGRS is an alphanumeric encoding of UTM/UPS coordinates used by NATO. An MGRS
string such as `18SUJ2337106519` breaks down as:

| Component | Example | Meaning |
| --- | --- | --- |
| Grid zone designator | `18S` | UTM zone 18, latitude band S |
| 100 km square ID | `UJ` | Two-letter code identifying a 100 km square |
| Easting digits | `23371` | Meters east within the square |
| Northing digits | `06519` | Meters north within the square |

For polar regions, the grid zone designator is a single letter (A/B for the
south pole, Y/Z for the north pole) with no zone number.

Access these components via ``MGRSCoordinate/gridZone``,
``MGRSCoordinate/squareIdentifier``, ``MGRSCoordinate/easting``, and
``MGRSCoordinate/northing``. Check ``MGRSCoordinate/isPolar`` to determine
whether a coordinate falls in a UPS region.

#### Precision Levels

The ``MGRSPrecision`` enum controls how many digits appear in the easting and
northing, which determines the ground resolution of the reference:

| Precision | Digits per axis | Resolution |
| --- | --- | --- |
| ``MGRSPrecision/hundredKilometer`` | 0 | 100 km |
| ``MGRSPrecision/tenKilometer`` | 1 | 10 km |
| ``MGRSPrecision/oneKilometer`` | 2 | 1 km |
| ``MGRSPrecision/hundredMeter`` | 3 | 100 m |
| ``MGRSPrecision/tenMeter`` | 4 | 10 m |
| ``MGRSPrecision/oneMeter`` | 5 | 1 m |
| ``MGRSPrecision/hundredMillimeter`` | 6 | 100 mm |
| ``MGRSPrecision/tenMillimeter`` | 7 | 10 mm |
| ``MGRSPrecision/oneMillimeter`` | 8 | 1 mm |
| ``MGRSPrecision/hundredMicrometer`` | 9 | 100 um |
| ``MGRSPrecision/tenMicrometer`` | 10 | 10 um |
| ``MGRSPrecision/oneMicrometer`` | 11 | 1 um |

For most practical applications, ``MGRSPrecision/oneMeter`` (the default) is
appropriate. Use ``MGRSPrecision/resolution`` to query the ground resolution in
meters for any precision level.

## Topics

### Coordinate Types

- ``UTMCoordinate``
- ``UPSCoordinate``
- ``MGRSCoordinate``
- ``GeographicCoordinate``

### Supporting Types

- ``Hemisphere``
- ``MGRSPrecision``

### Unified Operations

- ``UTMUPS``
