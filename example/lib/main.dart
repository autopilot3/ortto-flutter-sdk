import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'design.dart';
import 'firebase_options.dart';
import 'push_model.dart';
import 'views/root_view.dart';

const _useNativeAndroidFirebaseConfig = bool.fromEnvironment(
  'USE_NATIVE_ANDROID_FIREBASE_CONFIG',
);

Future<void> _initializeFirebase() async {
  final useNativeConfig = !kIsWeb &&
      defaultTargetPlatform == TargetPlatform.android &&
      _useNativeAndroidFirebaseConfig;
  try {
    await Firebase.initializeApp(
      options: useNativeConfig ? null : DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (error) {
    if (error.code != 'duplicate-app') rethrow;
  }
}

// This is the background message handler.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // The Android SDK registers its own FirebaseMessagingService and owns
  // delivery in foreground, background, and process-dead states. Forwarding
  // the same message from firebase_messaging would display it twice.
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) return;

  await _initializeFirebase();

  // Pass the received background message to the Ortto SDK.
  await Ortto.instance.onBackgroundMessageReceived(message.toMap());
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // On Android the google-services plugin auto-initializes the default app
  // from google-services.json before Dart runs, which surfaces here as a
  // duplicate-app error (Firebase.apps stays empty until the first call).
  await _initializeFirebase();
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final prefs = await SharedPreferences.getInstance();
  final model = PushModel(prefs);

  // Ortto SDK: initialize push and (when configured) in-app notifications.
  if (AppConfig.canInitializeSDK) {
    try {
      await Ortto.instance.init(
        appKey: AppConfig.orttoAppKey,
        endpoint: AppConfig.orttoAppEndpoint,
      );
      model.appendSdkLog('Ortto.instance.init completed');
    } catch (error) {
      model.appendSdkLog('Ortto.instance.init failed: $error');
    }
  } else {
    model.appendLog(
        'Ortto init skipped: ${AppConfig.orttoConfigurationFailureDetail}');
  }

  if (AppConfig.canInitializeCapture) {
    try {
      await Ortto.instance.initCapture(
        dataSourceKey: AppConfig.orttoDatasourceKey,
        captureJsUrl: AppConfig.orttoCaptureJsUrl,
        apiHost: AppConfig.orttoApiHost,
      );
      model.appendSdkLog('Ortto.instance.initCapture completed');
    } catch (error) {
      model.appendSdkLog('Ortto.instance.initCapture failed: $error');
    }
  } else {
    model.appendLog('Ortto capture init skipped: capture keys not configured');
  }

  // Ortto SDK: notification tap routing. A tap while the app is in the
  // background arrives via onMessageOpenedApp; a tap that cold-started the
  // app arrives via getInitialMessage.
  FirebaseMessaging.onMessageOpenedApp.listen((message) {
    model.handleNotificationTap(message.data);
  });
  final initialMessage = await FirebaseMessaging.instance.getInitialMessage();
  if (initialMessage != null) {
    model.handleNotificationTap(initialMessage.data);
  }

  runApp(PushDemoApp(model: model));
}

class PushDemoApp extends StatelessWidget {
  const PushDemoApp({super.key, required this.model});

  final PushModel model;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Push Demo',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: AppFonts.sans,
        colorScheme: ColorScheme.fromSeed(
          seedColor: AppColors.lilac,
          primary: AppColors.lilac,
        ),
        scaffoldBackgroundColor: AppColors.groupedBackground,
      ),
      home: RootView(model: model),
    );
  }
}
