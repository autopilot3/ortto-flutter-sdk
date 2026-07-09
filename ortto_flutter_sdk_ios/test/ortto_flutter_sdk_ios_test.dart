import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ortto_flutter_sdk_ios/ortto_flutter_sdk_ios.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

import 'support/method_channel_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('ortto_flutter_sdk_ios');
  late MethodChannelHarness harness;
  late OrttoFlutterSdkIOS platform;

  setUp(() {
    harness = MethodChannelHarness(channel);
    platform = OrttoFlutterSdkIOS();
  });

  tearDown(() => harness.uninstall());

  test('initialize sends the iOS channel contract', () async {
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
