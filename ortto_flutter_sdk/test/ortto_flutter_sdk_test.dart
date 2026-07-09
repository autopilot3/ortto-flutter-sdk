import 'package:flutter_test/flutter_test.dart';
import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('init delegates the complete configuration to the platform', () async {
    final platform = RecordingPlatform();
    OrttoFlutterSdkPlatformInterface.instance = platform;

    await Ortto.instance.init(
      appKey: 'app-key',
      endpoint: 'https://example.test',
      shouldSkipNonExistingContacts: true,
    );

    expect(platform.configuration?.toMap(), <String, dynamic>{
      'appKey': 'app-key',
      'endpoint': 'https://example.test',
      'shouldSkipNonExistingContacts': true,
      'allowAnonUsers': false,
    });
  });
}

class RecordingPlatform extends OrttoFlutterSdkPlatformInterface {
  OrttoConfig? configuration;

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
  Future<String?> getPlatformName() async => 'test';

  @override
  Future<IdentityResult> clearIdentity() async => IdentityResult();
}
