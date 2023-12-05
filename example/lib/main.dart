import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import 'package:ortto_flutter_sdk/flutter_ortto_push_sdk.dart';
import 'package:ortto_flutter_example/firebase_options.dart';

import 'package:uuid/uuid.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    name: "example-project",
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await FirebaseMessaging.instance.setForegroundNotificationPresentationOptions(
    alert: true,
    badge: true,
    sound: true,
  );

  await FirebaseMessaging.instance.setAutoInitEnabled(true);
  await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(true);

  final fcmToken = await FirebaseMessaging.instance.getToken();

  print('FCMToken $fcmToken');

  // FirebaseMessaging.onMessage.listen((RemoteMessage message) {
  //   print('Got a message whilst in the foreground!');
  //   print('Message data: ${message.data}');

  //   if (message.notification != null) {
  //     print('Message also contained a notification: ${message.notification}');
  //   }
  // });

  await Ortto.instance.init(
    appKey: 'Y3FsgI3b4q0o8XfrbWl0Y2hzdGFnaW5n',
    endpoint: 'https://capture-api-au.ortto-stg.app/',
  );

  await Ortto.instance.initCapture(
    dataSourceKey: 'Y3FsgI3b4q0o8XfrbWl0Y2hzdGFnaW5n',
    captureJsUrl: 'https://static.ap3stg.com/capture/master/capture.js',
    // captureJsUrl: 'https://wavy.flindev.com/capture16.js',
    apiHost: 'https://capture-api-au.ortto-stg.app/',
  );

  const uuid = Uuid();

  final user = UserID(
      contactId: uuid.v4(),
      email: 'ops+2@flindev.com',
  );

  await Ortto.instance.identify(user);

  await Ortto.instance.dispatchPushRequest();

  runApp(const MyApp());
}

Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp();
  // Ortto.messagingPush().onBackgroundMessageReceived(message.toMap()).then((handled) {
  // //   handled is true if notification was handled by Customer.io SDK; false otherwise
    // return handled;
  // });
}


class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

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
      appBar: AppBar(title: const Text('FlutterOrttoPushSdk Example')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_platformName == null)
              const SizedBox.shrink()
            else
              Text(
                'Platform Name: $_platformName',
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            Text(
              'Push permission: $_permission',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                

                // PushPermission permissionResult = await Ortto.instance.requestPermissions();

                // // Convert the enum result to a string and display in Snackbar
                // String resultString = permissionResult.toString().split('.').last;

                // // Show a Snackbar with the result
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(
                //     backgroundColor: Theme.of(context).primaryColor,
                //     content: Text('Permission status: $resultString'),
                //   ),
                // );
                FirebaseMessaging messaging = FirebaseMessaging.instance;

                NotificationSettings settings = await messaging.requestPermission(
                  alert: true,
                  announcement: false,
                  badge: true,
                  carPlay: false,
                  criticalAlert: false,
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
              },
              child: const Text('requestPermissions'),
            ),
            ElevatedButton(
              onPressed: () async {
                await Ortto.instance.dispatchPushRequest();
              },
              child: const Text('dispatchPushRequest'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (!_captureInitialized) {
                  return;
                }

                try {
                  // await
                  Ortto.instance.showWidget(widgetId);

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
            ElevatedButton(
              onPressed: () async {
                if (!_captureInitialized) {
                  return;
                }

                try {
                  await Ortto.instance.queueWidget(widgetId);
                } catch (error) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      backgroundColor: Theme.of(context).primaryColor,
                      content: Text('$error'),
                    ),
                  );
                }
              },
              child: const Text('Queue Widget'),
            ),
          ],
        ),
      ),
    );
  }
}
