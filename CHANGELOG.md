# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.2] - 2026-09-14

### Changed

- Raised the minimum versions of the package's dependencies: swift-numerics 1.1.1 (was 1.0.0) and swift-docc-plugin 1.5.0 (was 1.4.3).
- Adopted four further upcoming features across both targets (`ImmutableWeakCaptures`, `MemberImportVisibility`, `ExistentialAny`, and `InternalImportsByDefault`). The tools version stays at 6.0 and both the `.v5` and `.v6` language modes remain available, so this is a build-configuration change with no effect on the public API or runtime behavior.
- Building the test suite now requires Swift 6.2 or newer, because its tests are named with raw identifiers. Building and using the library itself still requires only Swift 6.0.

### Fixed

- The generated documentation for `UTMCoordinate`, `UPSCoordinate`, and `MGRSCoordinate` now lists their `clLocationCoordinate2D` property, which was missing from each type's topic groups.

## [1.0.1] - 2026-06-26

### Changed

- Adopted the Approachable Concurrency upcoming features (`NonisolatedNonsendingByDefault` and `InferIsolatedConformances`). SwiftGeographic is a purely synchronous library, so this is a build-configuration change with no effect on its public API or runtime behavior.

## [1.0.0] - 2026-05-01

### Added

- Initial release of SwiftGeographic
- Accurate geodetic coordinate conversions between geographic (latitude/longitude), UTM, UPS, and MGRS coordinate systems
- High-precision projections
- Swift 6 concurrency support
