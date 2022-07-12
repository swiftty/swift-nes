// swift-tools-version: 5.7

// WARNING:
// This file is automatically generated.
// Do not edit it by hand because the contents will be replaced.

import PackageDescription
import AppleProductTypes

let package = Package(
    name: "01_snake",
    platforms: [
        .iOS("16.0")
    ],
    products: [
        .iOSApplication(
            name: "01_snake",
            targets: ["01_snake"],
            displayVersion: "1.0",
            bundleVersion: "1",
            appIcon: .placeholder(icon: .earth),
            accentColor: .presetColor(.cyan),
            supportedDeviceFamilies: [
                .pad,
                .phone
            ],
            supportedInterfaceOrientations: [
                .portrait,
                .landscapeRight,
                .landscapeLeft,
                .portraitUpsideDown(.when(deviceFamilies: [.pad]))
            ]
        )
    ],
    dependencies: [
        .package(path: "../")
    ],
    targets: [
        .executableTarget(
            name: "01_snake",
            dependencies: [
                .product(name: "SwiftNES", package: "swift-nes")
            ]
        )
    ]
)
