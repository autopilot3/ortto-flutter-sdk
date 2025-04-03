import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';
import 'package:uuid/uuid.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(badge: true, alert: true, sound: true);

  await Ortto.instance.init(
    appKey: '<APP_KEY>',
    endpoint: '<APP_ENDPOINT>',
  );

  await Ortto.instance.initCapture(
    dataSourceKey: '<DATA_SOURCE_KEY>',
    captureJsUrl: '<CAPTURE_JS_URL>',
    apiHost: '<API_HOST>',
  );

  const uuid = Uuid();
  final user = UserID(externalId: uuid.v4(), email: 'example@ortto.com');
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
  String? _platformName;
  String? _permission;
  bool _pushInitialized = true;
  bool _captureInitialized = true;
  final String widgetId = '64b87236c1d0dbd9461a2515';

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
                // if (!_captureInitialized) {
                //   return;
                // }

                try {
                  // await
                  Ortto.instance.showWidget('<WIDGET_ID>');

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).primaryColor,
                      content: Text('Should show widget!'),
                    ),
                  );
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).primaryColor,
                      content: Text('$error'),
                    ),
                  );
                }
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
