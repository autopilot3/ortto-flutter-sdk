import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ortto_flutter_sdk_android/ortto_flutter_sdk_android.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

import 'support/method_channel_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ortto_flutter_sdk_android');
  late MethodChannelHarness harness;
  late FlutterOrttoPushSdkAndroid platform;

  setUp(() {
    harness = MethodChannelHarness(channel);
    platform = FlutterOrttoPushSdkAndroid();
  });

  tearDown(() => harness.uninstall());

  test('initialize sends the Android channel contract', () async {
    harness.respondWith(null);

    await platform.initialize(OrttoConfig(
      'app-key',
      'https://example.test',
      shouldSkipNonExistingContacts: true,
    ));

    expect(harness.singleCall.method, 'initialize');
    expect(
      harness.singleCall.arguments,
      containsPair('shouldSkipNonExistingContacts', true),
    );
  });
}
