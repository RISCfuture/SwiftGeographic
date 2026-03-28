// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "SwiftGeographic",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
    .tvOS(.v16),
    .watchOS(.v9),
    .visionOS(.v1)
  ],
  products: [
    .library(
      name: "SwiftGeographic",
      targets: ["SwiftGeographic"]
    )
  ],
  dependencies: [
    .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.3"),
    .package(url: "https://github.com/apple/swift-numerics", from: "1.0.0")
  ],
  targets: [
    .target(
      name: "SwiftGeographic",
      dependencies: [
        .product(name: "Numerics", package: "swift-numerics")
      ]
    ),
    .testTarget(
      name: "SwiftGeographicTests",
      dependencies: [
        "SwiftGeographic",
        .product(name: "Numerics", package: "swift-numerics")
      ],
      resources: [
        .copy("Resources/TMcoords.dat"),
        .copy("Resources/mgrs_geoconvert_coords.txt"),
        .copy("Resources/mgrs_geoconvert_mgrs.txt"),
        .copy("Resources/geotrans_clean.txt")
      ]
    )
  ],
  swiftLanguageModes: [.v5, .v6]
)
