import 'package:flutter/services.dart';
import 'package:ortto_flutter_platform_interface/src/method_channel_flutter_ortto_push_sdk.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const kPlatformName = 'platformName';

  group('$MethodChannelFlutterOrttoPushSdk', () {
    late MethodChannelFlutterOrttoPushSdk methodChannelFlutterOrttoPushSdk;
    final log = <MethodCall>[];

    setUp(() async {
      methodChannelFlutterOrttoPushSdk = MethodChannelFlutterOrttoPushSdk();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
        methodChannelFlutterOrttoPushSdk.methodChannel,
        (methodCall) async {
          log.add(methodCall);
          switch (methodCall.method) {
            case 'getPlatformName':
              return kPlatformName;
            default:
              return null;
          }
        },
      );
    });

    tearDown(log.clear);

    test('getPlatformName', () async {
      final platformName = await methodChannelFlutterOrttoPushSdk.getPlatformName();
      expect(
        log,
        <Matcher>[isMethodCall('getPlatformName', arguments: null)],
      );
      expect(platformName, equals(kPlatformName));
    });
  });
}
