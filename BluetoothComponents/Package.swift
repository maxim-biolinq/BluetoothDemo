// swift-tools-version: 5.9
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "BluetoothComponents",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "BluetoothComponents",
            targets: ["BluetoothComponents"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-protobuf.git", from: "1.21.0")
    ],
    targets: [
        .target(
            name: "BluetoothComponents",
            dependencies: [
                .product(name: "SwiftProtobuf", package: "swift-protobuf")
            ],
            exclude: ["docs"]),
        .testTarget(
            name: "BluetoothComponentsTests",
            dependencies: ["BluetoothComponents"]),
    ]
)
