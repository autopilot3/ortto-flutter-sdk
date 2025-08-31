import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';

import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

class AppConfig {
  static const String orttoAppKey = "<APP_KEY>";
  static const String orttoAppEndpoint = "<APP_ENDPOINT>";
  static const String orttoDatasourceKey = "<DATA_SOURCE_KEY>";
  static const String orttoCaptureJsUrl = "<CAPTURE_JS_URL>";
  static const String orttoApiHost = "<API_HOST>";
  static const String widgetId = "<WIDGET_ID>";
}

void main() async {
  // Ensure that plugin services are initialized
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Set up Firebase Messaging
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(badge: true, alert: true, sound: true);

  // Initialize Ortto SDK
  await Ortto.instance.init(
    appKey: AppConfig.orttoAppKey,
    endpoint: AppConfig.orttoAppEndpoint,
  );

  final token = (await FirebaseMessaging.instance.getToken())!;

  // Initialize Ortto Capture (not required)
  await Ortto.instance.initCapture(
    dataSourceKey: AppConfig.orttoDatasourceKey,
    captureJsUrl: AppConfig.orttoCaptureJsUrl,
    apiHost: AppConfig.orttoAppEndpoint,
  );

  await Ortto.instance.requestPermissions();

  // Set up Ortto User to identify
  const uuid = Uuid();
  final user = UserID(externalId: uuid.v4(), email: 'joe@ortto.com');

  // Identify the user
  await Ortto.instance.identify(user);

  // Uncomment if you need to automatically register device token
  // await Ortto.instance.dispatchPushRequest();

  // Set up Firebase Messaging
  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
      badge: true,
      alert: true,
      sound: true
  );

  // Use registerDeviceToken to register the device token manually
  final fcmToken = await FirebaseMessaging.instance.getToken();
  if (fcmToken != null) {
    Ortto.instance.registerDeviceToken(fcmToken);
  }

  // Handle foreground messages
  FirebaseMessaging.onMessage.listen((RemoteMessage message) {
    Ortto.instance
      .onbackgroundMessageReceived(message.toMap())
      .then((handled) {
        print("handled $handled");
        return handled;
      });
  });

  // Register background message handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

// This is the background message handler
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Pass the received background message to Ortto SDK
  Ortto.instance
    .onbackgroundMessageReceived(message.toMap())
    .then((handled) {
      return handled;
    });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Live Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const HomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key, required this.title});
  final String title;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {

  final String widgetId = AppConfig.widgetId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () async {
                Ortto.instance.clearIdentity()
                  .then((value) {
                    print("Cleared identity");
                  })
                  .catchError((error) {
                    print(error);
                  });
              },
              child: const Text('Clear Identity'),
            ),
            ElevatedButton(
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    backgroundColor: Theme.of(context).primaryColor,
                    content: Text('Should show widget!'),
                  ),
                );

                Ortto.instance.showWidget(widgetId)
                  .then((value) {
                    print("Widget shown successfully");
                  }).catchError((error) {
                    print("Error showing widget: $error");
                  });
              },
              child: const Text('Show Widget'),
            ),

            ElevatedButton(onPressed: () async {
              FirebaseMessaging messaging = FirebaseMessaging.instance;

              NotificationSettings settings = await messaging.requestPermission(
                alert: true,
                badge: true,
                provisional: false,
                sound: true,
              );

              if (settings.authorizationStatus == AuthorizationStatus.authorized) {
                print('User granted permission');
              } else if (settings.authorizationStatus == AuthorizationStatus.provisional) {
                print('User granted provisional permission');
              } else {
                print('User declined or has not accepted permission');
              }

              final apnsToken = await FirebaseMessaging.instance.getAPNSToken();
              print(apnsToken);

              Ortto.instance.dispatchPushRequest();
            }, child: const Text('Request Permissions')),

            ElevatedButton(onPressed: () async {
              final fcmToken = await FirebaseMessaging.instance.getToken();
              print(fcmToken);

              Ortto.instance.trackLinkClick("some-link");

            }, child: const Text('Test LInk Tracking'))
          ],
        ),
      ),
    );
  }
}
