// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ghlink",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "ghlink", targets: ["ghlink"]),
        .library(name: "GHLinkKit", targets: ["GHLinkKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "ghlink",
            dependencies: [
                "GHLinkKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "GHLinkKit"
        ),
        .testTarget(
            name: "GHLinkKitTests",
            dependencies: ["GHLinkKit"]
        ),
    ]
)
