import 'dart:async';

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

    await platform.initialize(
      OrttoConfig(
        'app-key',
        'https://example.test',
        shouldSkipNonExistingContacts: true,
      ),
    );

    expect(harness.singleCall.method, 'initialize');
    expect(
      harness.singleCall.arguments,
      containsPair('shouldSkipNonExistingContacts', true),
    );
  });

  test('identify sends every canonical identity field', () async {
    harness.respondWith(null);

    await platform.identify(
      UserID(
        firstName: 'Ada',
        lastName: 'Lovelace',
        acceptsGdpr: true,
        contactId: 'contact-id',
        email: 'ada@example.test',
        externalId: 'external-id',
        phone: '+61000000000',
      ),
    );

    expect(harness.singleCall.method, 'identify');
    expect(harness.singleCall.arguments, <String, dynamic>{
      'first_name': 'Ada',
      'last_name': 'Lovelace',
      'accepts_gdpr': true,
      'contact_id': 'contact-id',
      'email': 'ada@example.test',
      'external_id': 'external-id',
      'phone': '+61000000000',
    });
  });

  test('identify propagates native failures', () async {
    harness.respond(
      (_) async => throw PlatformException(
        code: 'IDENTIFY_ERROR',
        message: 'native failure',
      ),
    );

    await expectLater(
      platform.identify(UserID(email: 'ada@example.test')),
      throwsA(isA<PlatformException>()),
    );
  });

  test('getPlatformName returns the iOS native value', () async {
    harness.respondWith('iOS');

    await expectLater(platform.getPlatformName(), completion('iOS'));
    expect(harness.singleCall.method, 'getPlatformName');
  });

  for (final permission in <PushPermission>[
    PushPermission.ASK,
    PushPermission.PREVIOUSLY_DENIED,
    PushPermission.PREVIOUSLY_GRANTED,
  ]) {
    test('requestPermissions maps ${permission.name}', () async {
      harness.respondWith(permission.name);

      await expectLater(platform.requestPermissions(), completion(permission));
      expect(harness.singleCall.method, 'requestPermissions');
    });
  }

  test('registerDeviceToken sends a token and completes', () async {
    harness.respondWith(null);

    await MethodChannelHarness.expectCompletes(
      platform.registerDeviceToken('device-token'),
    );

    expect(harness.singleCall.method, 'registerDeviceToken');
    expect(harness.singleCall.arguments, <String, dynamic>{
      'token': 'device-token',
    });
  });

  test('registerDeviceToken propagates invalid argument failures', () async {
    harness.respond(
      (_) async => throw PlatformException(
        code: 'INVALID_ARGUMENTS',
        message: 'registerDeviceToken requires a non-empty token',
      ),
    );

    await expectLater(
      platform.registerDeviceToken(''),
      throwsA(isA<PlatformException>()),
    );
  });

  test('registerDeviceToken fails fast when native never completes', () async {
    harness.respond((_) => Completer<Object?>().future);

    await expectLater(
      MethodChannelHarness.expectCompletes(
        platform.registerDeviceToken('device-token'),
      ),
      throwsA(isA<TimeoutException>()),
    );
  });

  test('onMessageReceived preserves the iOS handled=false result', () async {
    harness.respondWith(false);

    final handled = await platform.onMessageReceived(<String, dynamic>{
      'data': <String, dynamic>{'unrelated': 'payload'},
    });

    expect(handled, isFalse);
    expect(harness.singleCall.method, 'onMessageReceived');
  });

  test('trackLinkClick returns the shared LinkUtm shape', () async {
    harness.respondWith(<String, dynamic>{
      'utm_campaign': 'launch',
      'utm_medium': 'push',
      'utm_source': 'ortto',
      'utm_content': null,
    });

    final utm = await platform.trackLinkClick(
      'https://example.test?utm_campaign=launch',
    );

    expect(utm.campaign, 'launch');
    expect(utm.medium, 'push');
    expect(utm.source, 'ortto');
    expect(utm.content, isNull);
  });

  test('trackLinkClick accepts an encoded tracking link', () async {
    harness.respondWith(<String, dynamic>{
      'utm_campaign': 'launch',
      'utm_medium': null,
      'utm_source': null,
      'utm_content': null,
    });
    const link =
        'https://click.example.test?tracking_url=aHR0cHM6Ly9leGFtcGxlLnRlc3Q_dXRtX2NhbXBhaWduPWxhdW5jaA';

    final utm = await platform.trackLinkClick(link);

    expect(utm.campaign, 'launch');
    expect(harness.singleCall.arguments, <String, dynamic>{'link': link});
  });

  test('trackLinkClick permits links with missing UTM values', () async {
    harness.respondWith(<String, dynamic>{
      'utm_campaign': null,
      'utm_medium': null,
      'utm_source': null,
      'utm_content': null,
    });

    final utm = await platform.trackLinkClick('https://example.test/path');

    expect(utm.campaign, isNull);
    expect(utm.medium, isNull);
  });

  test('trackLinkClick propagates malformed-link errors', () async {
    harness.respond(
      (_) async => throw PlatformException(
        code: 'INVALID_LINK',
        message: 'The link is malformed',
      ),
    );

    await expectLater(
      platform.trackLinkClick('not a URL'),
      throwsA(isA<PlatformException>()),
    );
  });

  test('trackLinkClick propagates native tracking failures', () async {
    harness.respond(
      (_) async => throw PlatformException(
        code: 'TRACKING_ERROR',
        message: 'Link tracking did not complete',
      ),
    );

    await expectLater(
      platform.trackLinkClick('https://example.test/tracked'),
      throwsA(isA<PlatformException>()),
    );
  });
}
