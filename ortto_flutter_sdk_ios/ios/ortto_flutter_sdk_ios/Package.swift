// swift-tools-version: 5.9

import Foundation
import PackageDescription

let orttoSdkDependency: Package.Dependency
if let localPath = ProcessInfo.processInfo.environment["ORTTO_IOS_SDK_PATH"],
   !localPath.isEmpty {
    orttoSdkDependency = .package(
        name: "ortto-push-ios-sdk",
        path: localPath
    )
} else {
    orttoSdkDependency = .package(
        url: "https://github.com/autopilot3/ortto-push-ios-sdk.git",
        "1.10.1"..<"2.0.0"
    )
}

let package = Package(
    name: "ortto_flutter_sdk_ios",
    platforms: [
        .iOS("15.0")
    ],
    products: [
        .library(
            name: "ortto-flutter-sdk-ios",
            targets: ["ortto_flutter_sdk_ios"]
        ),
        .library(
            name: "ortto-flutter-notification-service-extension",
            targets: ["OrttoFlutterNotificationServiceExtension"]
        )
    ],
    dependencies: [
        .package(name: "FlutterFramework", path: "../FlutterFramework"),
        orttoSdkDependency
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
        ),
        .target(
            name: "OrttoFlutterNotificationServiceExtension",
            dependencies: [
                .product(name: "OrttoPushMessagingFCM", package: "ortto-push-ios-sdk")
            ]
        )
    ]
)
