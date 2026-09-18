# Ortto Flutter Plugin

[![pub package](https://img.shields.io/pub/v/ortto_flutter_sdk.svg)](https://pub.dev/packages/ortto_flutter_sdk)

## Other Packages 
- ortto_flutter_sdk_platform_interface https://pub.dev/packages/ortto_flutter_sdk_platform_interface
- ortto_flutter_sdk_android https://pub.dev/packages/ortto_flutter_sdk_android
- ortto_flutter_sdk_ios https://pub.dev/packages/ortto_flutter_sdk_ios

## Pre-Requisites

1. Set up and configure firebase flutter project
2. Install Flutterfire CLI `dart pub global activate flutterfire_cli`
3. Attach Firebase project `flutterfire configure --project=<FIREBASE_PROJECT_ID>`
4. Add Firebase messaging dependency `flutter pub add firebase_messaging`
5. Ensure `lib/firebase_options.dart` config file is present and configured correctly

## Development

Run every federated package test suite from the repository root:

```shell
./tool/test_all.sh
```

Additional `flutter test` arguments are forwarded to every package, for example:

```shell
./tool/test_all.sh --coverage
```

## Usage

1. In the root of your project, run: `flutter pub add ortto_flutter_sdk`
2. In your projects main file, import firebase_messaging `import 'package:firebase_messaging/firebase_messaging.dart';`
3. Import Flutter's platform helpers `import 'package:flutter/foundation.dart';`
4. Import firebase_options file `import 'firebase_options.dart';`
5. Import ortto_flutter_sdk `import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';`
6. Set up Firebase Messaging and Ortto

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // The handler must be a top-level function and registered before runApp.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  await Ortto.instance.init(
    appKey: '<APP_KEY>',
    endpoint: '<APP_ENDPOINT>',
  );

  await Ortto.instance.initCapture(
    dataSourceKey: '<DATASOURCE_KEY>',
    captureJsUrl: '<CAPTURE_JS_URL>',
    apiHost: '<API_HOST>>',
  );
  
  const uuid = Uuid();
  final user = UserID(
    externalId: uuid.v4(),
    email: 'example@ortto.com',
  );

  await Ortto.instance.identify(user);

  // On iOS, macOS, web, and Android 13+, Firebase Messaging owns the
  // notification permission request. On iOS this displays the system modal.
  final settings = await FirebaseMessaging.instance.requestPermission(
    alert: true,
    badge: true,
    sound: true,
  );

  if (settings.authorizationStatus == AuthorizationStatus.authorized ||
      settings.authorizationStatus == AuthorizationStatus.provisional) {
    final token = await FirebaseMessaging.instance.getToken();
    if (token != null) {
      await Ortto.instance.registerDeviceToken(token);
    }
  }

  FirebaseMessaging.instance.onTokenRefresh.listen(
    Ortto.instance.registerDeviceToken,
  );

  await Ortto.instance.dispatchPushRequest();

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    badge: true,
    alert: true,
    sound: true,
  );

  // Android delivery is owned by the native Ortto FirebaseMessagingService.
  // Forward Firebase callbacks only on iOS to avoid duplicate Android
  // notifications.
  if (defaultTargetPlatform == TargetPlatform.iOS) {
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      Ortto.instance.onBackgroundMessageReceived(message.toMap());
    });
  }

  FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
    // Route message.data after a tap while the app was in the background.
  });
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    // Route initialMessage.data after a tap that cold-started the app.
  }

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (defaultTargetPlatform == TargetPlatform.android) return;

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Ortto.instance.onBackgroundMessageReceived(message.toMap());
}

```


## iOS dependency management

Flutter 3.44 and later can integrate the iOS plugin with Swift Package Manager. Enable Flutter's SPM support before building:

```shell
flutter config --enable-swift-package-manager
flutter clean
flutter pub get
```

The plugin resolves Ortto iOS SDK `1.10.1` or newer up to, but excluding, `2.0.0`. Projects that keep CocoaPods enabled use the final podspec fallback pinned to Ortto iOS SDK `1.10.1`; later native iOS releases are Swift Package Manager only. Maintainers can test an unpublished native checkout by setting `ORTTO_IOS_SDK_PATH` to its absolute path before running a Flutter build.

## iOS Background Notifications

1. Open the `ios/Runner.xcworkspace` workspace folder in Xcode
2. Add a new capability for Background Modes
   1. Select your project in the Project Navigator
   2. Navigate to the Runner target -> Signing & Capabilities
   3. Click the + Capability button
   4. Select Background Modes
   5. Check the Remote notifications checkbox
3. Add a background extension
   1. In the application menu bar select File -> New -> Target
   2. Select Notification Service Extension
   3. Click Next
   4. Name the extension `NotificationServiceExtension`
   5. Click Finish
4. With Swift Package Manager enabled, select the `NotificationServiceExtension` target in Xcode, open **General > Frameworks, Libraries, and Embedded Content**, and add the `ortto-flutter-notification-service-extension` product from the generated `ortto_flutter_sdk_ios` package.
5. Open the `NotificationService.swift` file in the Notification Service Extension folder and replace its contents with:

```swift
import UserNotifications
import OrttoFlutterNotificationServiceExtension

class NotificationService: UNNotificationServiceExtension {
    private var handledByOrtto = false

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        handledByOrtto = OrttoNotificationService.didReceive(request, withContentHandler: contentHandler)

        if !handledByOrtto {
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if handledByOrtto {
            OrttoNotificationService.serviceExtensionTimeWillExpire()
        }
    }
}
```

### CocoaPods fallback

For projects that have not enabled Swift Package Manager, add the final CocoaPods release to the extension target in `ios/Podfile`:

```ruby
target 'NotificationServiceExtension' do
  use_frameworks!
  pod 'OrttoPushMessagingFCM', '1.10.1'
end 
```

Then run `pod install --repo-update --project-directory=ios` and use this implementation:

```swift 
import UserNotifications
import OrttoPushMessagingFCM

class NotificationService: UNNotificationServiceExtension {

    private var handledByOrtto = false

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        handledByOrtto = PushMessaging.shared.didReceive(request, withContentHandler: contentHandler)

        if !handledByOrtto {
            contentHandler(request.content)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if handledByOrtto {
            PushMessaging.shared.serviceExtensionTimeWillExpire()
        }
    }
}
```

## Deep linking

Please refer to the following documentation for deep linking in Flutter https://docs.flutter.dev/ui/navigation/deep-linking 

Ensure your deep linking URL scheme is set up correctly in your Ortto dashboard.


```dart
await Ortto.instance.trackLinkClick("deep://link-from/push-notification?with=parameters&included=true");
```


## API

initialize
initializeCapture
identify
clearData
dispatchPushRequest
requestPermissions
trackLinkClick
queueWidget
showWidget
processNextWidgetFromQueue
onMessageReceived

## Reporting Issues

Please report all issues to Github https://github.com/autopilot3/ortto-flutter-sdk/issues 

# Publishing

Publishing must be done in this order.
Don't forget to update the changelog of each library

## 1. ortto_flutter_sdk_platform_interface
```bash 
# Update version in pubspec.yaml
# Update CHANGELOG.md 
cd ortto_flutter_sdk_platform_interface
flutter pub publish
# confirm version and publish
```

## 2. ortto_flutter_sdk_ios
```bash
# Update version in pubspec.yaml
# Update CHANGELOG.md 
cd ortto_flutter_sdk_ios
flutter pub publish
# confirm version and publish
```

## 3. ortto_flutter_sdk_android
```bash
# Update version in pubspec.yaml
# Update CHANGELOG.md 
cd ortto_flutter_sdk_android
flutter pub publish
# confirm version and publish
```

## 4. ortto_flutter_sdk
```bash
# Update version in pubspec.yaml
# Update CHANGELOG.md
cd ortto_flutter_sdk
flutter pub publish
# confirm version and publish
```

## License
   
MIT License (MIT)
