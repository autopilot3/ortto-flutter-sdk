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
}
