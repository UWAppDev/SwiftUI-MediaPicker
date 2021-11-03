// swift-tools-version:5.5
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "SwiftUI-PhotoPicker",
    platforms: [
        .iOS(.v14), .macOS(.v11),
    ],
    products: [
        .library(
            name: "PhotoPicker",
            targets: ["PhotoPicker"]),
    ],
    targets: [
        .target(
            name: "PhotoPicker",
            dependencies: []),
        .testTarget(
            name: "PhotoPickerTests",
            dependencies: ["PhotoPicker"]),
    ]
)
