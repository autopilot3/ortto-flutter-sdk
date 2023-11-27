import 'package:flutter/services.dart';
import 'package:ortto_flutter_sdk_android/ortto_flutter_sdk_android.dart';
import 'package:ortto_flutter_platform_interface/ortto_flutter_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterOrttoPushSdkAndroid', () {
    const kPlatformName = 'Android';
    late FlutterOrttoPushSdkAndroid flutterOrttoPushSdk;
    late List<MethodCall> log;

    setUp(() async {
      flutterOrttoPushSdk = FlutterOrttoPushSdkAndroid();

      log = <MethodCall>[];
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(flutterOrttoPushSdk.methodChannel, (methodCall) async {
        log.add(methodCall);
        switch (methodCall.method) {
          case 'getPlatformName':
            return kPlatformName;
          default:
            return null;
        }
      });
    });

    test('can be registered', () {
      FlutterOrttoPushSdkAndroid.registerWith();
      expect(FlutterOrttoPushSdkPlatform.instance, isA<FlutterOrttoPushSdkAndroid>());
    });

    test('getPlatformName returns correct name', () async {
      final name = await flutterOrttoPushSdk.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(name, equals(kPlatformName));
    });
  });
}
