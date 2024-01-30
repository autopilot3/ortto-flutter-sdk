# Ortto Flutter SDK


## Pre-Requisites

1. Set up and configure firebase flutter project
2. Install Flutterfire CLI `dart pub global activate flutterfire_cli`
3. Attach Firebase project `flutterfire configure --project=<FIREBASE_PROJECT_ID>`
4. Add Firebase messaging dependency `flutter pub add firebase_messaging`
5. Ensure `lib/firebase_options.dart` config file is present and configured correctly


## Usage

1. In the root of your project, run: `flutter pub add ortto_flutter_sdk`
2. In your projects main file, import firebase_messaging `import 'package:firebase_messaging/firebase_messaging.dart';`
3. Import firebase_options file `import 'firebase_options.dart';`
4. Import ortto_flutter_sdk `import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';`
5. Set up Firebase Messaging and Ortto 

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

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

  await Ortto.instance.dispatchPushRequest();

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(badge: true, alert: true, sound: true);

  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    if (message.notification != null) {
      Ortto.instance
          .onbackgroundMessageReceived(message.toMap())
          .then((handled) {
        print("handled $handled");
        return handled;
      });
    }
  });

  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  Ortto.instance
    .onbackgroundMessageReceived(message.toMap())
    .then((handled) {
      return handled;
    });
}

```


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
   4. Name the extension `NotificationService`
   5. Click Finish
4. In the `ios/Podfile` add the following
```ruby
target 'NotificationExtension' do
  use_frameworks!
  pod 'OrttoPushMessagingFCM', '~> 1.5'
end 
```
5. Run `pod install --repo-update --project-directory=ios` in root project folder
6. Open the `NotificationService.swift` file in the NotificationExtension folder
7. Add an/or replace contents as follows:

```swift 
import UserNotifications
import OrttoPushMessagingFCM

class NotificationService: UNNotificationServiceExtension {

    var contentHandler: ((UNNotificationContent) -> Void)?
    var bestAttemptContent: UNMutableNotificationContent?

    override func didReceive(_ request: UNNotificationRequest, withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void) {
        self.contentHandler = contentHandler

        let handled = PushMessaging.shared.didReceive(request, withContentHandler: contentHandler)        
    }
    
    override func serviceExtensionTimeWillExpire() {
    
        if let contentHandler = contentHandler, let bestAttemptContent =  bestAttemptContent {
            contentHandler(bestAttemptContent)
        }
    }
}
```

## Deep linking

Please refer to the following documentation for deep linking in Flutter https://docs.flutter.dev/ui/navigation/deep-linking 

Ensure your deep linking URL scheme is set up correctly in your Ortto dashboard.


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