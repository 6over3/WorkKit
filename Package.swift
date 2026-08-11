// swift-tools-version: 6.1
import PackageDescription

let package = Package(
  name: "WorkKit",
  platforms: [
    .macOS(.v13),
    .iOS(.v16),
  ],
  products: [
    .library(
      name: "WorkKit",
      targets: ["WorkKit"]
    ),
    .executable(
      name: "iwx",
      targets: ["iwx"]
    ),
    .executable(
      name: "proto-dump",
      targets: ["proto-dump"]
    ),
  ],
  dependencies: [
    .package(url: "https://github.com/apple/swift-argument-parser", from: "1.3.0"),
    .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.31.1"),
    .package(url: "https://github.com/apple/swift-log", from: "1.6.4"),
    .package(url: "https://github.com/weichsel/ZIPFoundation.git", from: "0.9.20"),
    .package(url: "https://github.com/apple/swift-collections.git", from: "1.3.0"),

  ],
  targets: [
    // WorkKit library
    .target(
      name: "WorkKit",
      dependencies: [
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
        .product(name: "ZIPFoundation", package: "ZIPFoundation"),
        .product(name: "Collections", package: "swift-collections"),
      ]
    ),

    // Executable targets
    .executableTarget(
      name: "iwx",
      dependencies: [
        "WorkKit",
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),
    .executableTarget(
      name: "proto-dump",
      dependencies: [
        "WorkKit",
        .product(name: "SwiftProtobuf", package: "swift-protobuf"),
        .product(name: "Logging", package: "swift-log"),
        .product(name: "ArgumentParser", package: "swift-argument-parser"),
      ]
    ),

    // Test targets
    .testTarget(
      name: "WorkKitTests",
      dependencies: ["WorkKit"]
    ),
  ]
)
