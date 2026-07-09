// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ortto_flutter_sdk_ios",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "ortto-flutter-sdk-ios",
            targets: ["ortto_flutter_sdk_ios"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        .package(
            url: "https://github.com/autopilot3/ortto-push-ios-sdk.git",
            "1.10.0"..<"2.0.0"
        )
    ],
    targets: [
        .target(
            name: "ortto_flutter_sdk_ios",
            dependencies: [
                .product(name: "FlutterFramework", package: "FlutterFramework"),
                .product(name: "OrttoSDKCore", package: "ortto-push-ios-sdk"),
                .product(name: "OrttoInAppNotifications", package: "ortto-push-ios-sdk"),
                .product(name: "OrttoPushMessaging", package: "ortto-push-ios-sdk"),
                .product(name: "OrttoPushMessagingFCM", package: "ortto-push-ios-sdk")
            ]
        )
    ]
)
