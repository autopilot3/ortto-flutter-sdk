# Migrating to 0.7.0

## Initialization

Remove `allowAnonUsers` from calls to `Ortto.instance.init`. The option was never forwarded to either native SDK, so removing it does not change native behavior.

```dart
await Ortto.instance.init(
  appKey: appKey,
  endpoint: endpoint,
  shouldSkipNonExistingContacts: true,
);
```

## Background messages

Rename `onbackgroundMessageReceived` to `onBackgroundMessageReceived`. The old spelling remains as a deprecated forwarding alias for this release.

For Android background delivery, notification payloads now suppress a second SDK-posted notification automatically. Data-only payloads still allow the SDK to display the notification. Foreground handlers can override this explicitly:

```dart
await Ortto.instance.onBackgroundMessageReceived(
  message.toMap(),
  handleNotificationTrigger: true,
);
```

## Firebase 12

Version 0.7.0 uses `firebase_core` 4.x and `firebase_messaging` 16.x. These packages resolve Firebase Apple SDK 12.x. Review the FlutterFire migration guidance if the application uses Firebase APIs outside this SDK.

## Swift Package Manager

Flutter 3.44 and later can integrate the iOS plugin with Swift Package Manager:

```shell
flutter config --enable-swift-package-manager
flutter clean
flutter pub get
```

SPM resolves Ortto iOS SDK `>=1.10.1 <2.0.0`. CocoaPods remains available as a fallback and is pinned to the final CocoaPods-compatible Ortto iOS SDK 1.10.1. Future Ortto iOS SDK releases are distributed through Swift Package Manager.

## Android native SDK

Version 0.7.0 resolves Ortto Android SDK 1.8.9, requires Android API 26 or later, and replaces the retired `firebase-messaging-ktx` artifact with the main Firebase Messaging module.
