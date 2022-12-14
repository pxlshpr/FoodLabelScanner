// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "FoodLabelScanner",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "FoodLabelScanner",
            targets: ["FoodLabelScanner"]),
    ],
    dependencies: [
        .package(url: "https://github.com/pxlshpr/SwiftSugar", from: "0.0.86"),
        .package(url: "https://github.com/pxlshpr/VisionSugar", from: "0.0.77"),
        .package(url: "https://github.com/pxlshpr/PrepDataTypes", from: "0.0.244"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "FoodLabelScanner",
            dependencies: [
                .product(name: "SwiftSugar", package: "swiftsugar"),
                .product(name: "VisionSugar", package: "visionsugar"),
                .product(name: "PrepDataTypes", package: "prepdatatypes"),
            ]
        ),
        .testTarget(
            name: "FoodLabelScannerTests",
            dependencies: ["FoodLabelScanner"],
            resources: [
//                .process("SampleImages"),
                .copy("Test Cases"),
            ]
        ),
    ]
)
