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
        )
    ],
    dependencies: [],
    targets: [
        .target(
            name: "NaviShared",
            path: "src/shared/swift"
        )
    ]
)
