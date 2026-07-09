import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';
import 'package:ortto_flutter_sdk_platform_interface/src/method_channel_ortto_flutter_sdk.dart';

import 'support/method_channel_harness.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter_ortto_push_sdk');
  late MethodChannelHarness harness;
  late MethodChannelOrttoFlutterSdk platform;

  setUp(() {
    harness = MethodChannelHarness(channel);
    platform = MethodChannelOrttoFlutterSdk();
  });

  tearDown(() => harness.uninstall());

  test('initialize uses the default channel contract', () async {
    harness.respondWith(null);

    await platform.initialize(OrttoConfig('app-key', 'https://example.test'));

    expect(harness.singleCall.method, 'initialize');
    expect(harness.singleCall.arguments, <String, dynamic>{
      'appKey': 'app-key',
      'endpoint': 'https://example.test',
      'shouldSkipNonExistingContacts': false,
      'allowAnonUsers': false,
    });
  });

  test('completion helper fails fast for a hanging native call', () async {
    final neverCompletes = Completer<void>().future;

    await expectLater(
      MethodChannelHarness.expectCompletes(neverCompletes),
      throwsA(isA<TimeoutException>()),
    );
  });
}
