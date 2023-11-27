import 'package:flutter/services.dart';
import 'package:ortto_flutter_sdk_ios/ortto_flutter_sdk_ios.dart';
import 'package:ortto_flutter_platform_interface/ortto_flutter_sdk_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('FlutterOrttoPushSdkIOS', () {
    const kPlatformName = 'iOS';
    late FlutterOrttoPushSdkIOS flutterOrttoPushSdk;
    late List<MethodCall> log;

    setUp(() async {
      flutterOrttoPushSdk = FlutterOrttoPushSdkIOS();

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
      FlutterOrttoPushSdkIOS.registerWith();
      expect(FlutterOrttoPushSdkPlatform.instance, isA<FlutterOrttoPushSdkIOS>());
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
