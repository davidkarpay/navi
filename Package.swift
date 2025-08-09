// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "Navi",
    platforms: [
        .iOS(.v16),
        .watchOS(.v9)
    ],
    products: [
        .library(
            name: "NaviShared",
            targets: ["NaviShared"]
        ),
        .executable(
            name: "NaviPhone",
            targets: ["NaviPhone"]
        ),
        .executable(
            name: "NaviWatch",
            targets: ["NaviWatch"]
        )
    ],
    dependencies: [
        // Add any external dependencies here
    ],
    targets: [
        .target(
            name: "NaviShared",
            path: "shared"
        ),
        .executableTarget(
            name: "NaviPhone",
            dependencies: ["NaviShared"],
            path: "ios/NaviPhone"
        ),
        .executableTarget(
            name: "NaviWatch",
            dependencies: ["NaviShared"],
            path: "watchos/NaviWatch"
        ),
        .testTarget(
            name: "NaviTests",
            dependencies: ["NaviShared"],
            path: "ios/Tests"
        )
    ]
)