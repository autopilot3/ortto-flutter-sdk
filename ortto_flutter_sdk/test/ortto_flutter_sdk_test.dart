import 'package:flutter_test/flutter_test.dart';
import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final platform = RecordingPlatform();

  setUpAll(() {
    OrttoFlutterSdkPlatformInterface.instance = platform;
  });

  setUp(platform.reset);

  test('init delegates the complete configuration to the platform', () async {
    await Ortto.instance.init(
      appKey: 'app-key',
      endpoint: 'https://example.test',
      shouldSkipNonExistingContacts: true,
    );

    expect(platform.configuration?.toMap(), <String, dynamic>{
      'appKey': 'app-key',
      'endpoint': 'https://example.test',
      'shouldSkipNonExistingContacts': true,
    });
  });

  test('background notification payload suppresses duplicate display', () async {
    await Ortto.instance.onBackgroundMessageReceived(<String, dynamic>{
      'notification': <String, dynamic>{'title': 'Already displayed by FCM'},
      'data': <String, dynamic>{'ortto': 'payload'},
    });

    expect(platform.handleNotificationTrigger, isFalse);
  });

  test('background data-only payload enables notification display', () async {
    await Ortto.instance.onBackgroundMessageReceived(<String, dynamic>{
      'data': <String, dynamic>{'ortto': 'payload'},
    });

    expect(platform.handleNotificationTrigger, isTrue);
  });

  test('foreground caller can explicitly enable notification display', () async {
    await Ortto.instance.onBackgroundMessageReceived(
      <String, dynamic>{
        'notification': <String, dynamic>{'title': 'Foreground'},
      },
      handleNotificationTrigger: true,
    );

    expect(platform.handleNotificationTrigger, isTrue);
  });
}

class RecordingPlatform extends OrttoFlutterSdkPlatformInterface {
  OrttoConfig? configuration;
  bool? handleNotificationTrigger;

  void reset() {
    configuration = null;
    handleNotificationTrigger = null;
  }

  @override
  Future<void> initialize(OrttoConfig config) async {
    configuration = config;
  }

  @override
  Future<void> initializeCapture(CaptureConfig config) async {}

  @override
  Future<void> identify(UserID user) async {}

  @override
  Future<void> clearData() async {}

  @override
  Future<PushPermission> requestPermissions() async => PushPermission.ASK;

  @override
  Future<void> registerDeviceToken(String token) async {}

  @override
  Future<void> dispatchPushRequest() async {}

  @override
  Future<LinkUtm> trackLinkClick(String link) async => LinkUtm();

  @override
  Future<void> queueWidget(String widgetId) async {}

  @override
  Future<WidgetResult> showWidget(String widgetId) async => WidgetResult();

  @override
  Future<void> processNextWidgetFromQueue() async {}

  @override
  Future<bool> onMessageReceived(
    Map<String, dynamic> message, {
    bool handleNotificationTrigger = true,
  }) async {
    this.handleNotificationTrigger = handleNotificationTrigger;
    return true;
  }

  @override
  Future<String?> getPlatformName() async => 'test';

  @override
  Future<IdentityResult> clearIdentity() async => IdentityResult();
}
