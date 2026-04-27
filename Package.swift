// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "gitlink",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "gitlink", targets: ["gitlink"]),
        .library(name: "GitLinkKit", targets: ["GitLinkKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
    ],
    targets: [
        .executableTarget(
            name: "gitlink",
            dependencies: [
                "GitLinkKit",
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "GitLinkKit"
        ),
        .testTarget(
            name: "GitLinkKitTests",
            dependencies: ["GitLinkKit"]
        ),
    ]
)
