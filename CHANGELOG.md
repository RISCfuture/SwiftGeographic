# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.1] - 2026-06-26

### Changed

- Adopted the Approachable Concurrency upcoming features (`NonisolatedNonsendingByDefault` and `InferIsolatedConformances`). SwiftGeographic is a purely synchronous library, so this is a build-configuration change with no effect on its public API or runtime behavior.

## [1.0.0] - 2026-05-01

### Added

- Initial release of SwiftGeographic
- Accurate geodetic coordinate conversions between geographic (latitude/longitude), UTM, UPS, and MGRS coordinate systems
- High-precision projections
- Swift 6 concurrency support
