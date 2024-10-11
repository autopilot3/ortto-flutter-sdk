import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

export 'package:ortto_flutter_sdk_platform_interface/src/models/capture_config.dart';
export 'package:ortto_flutter_sdk_platform_interface/src/models/link_utm.dart';
export 'package:ortto_flutter_sdk_platform_interface/src/models/ortto_config.dart';
export 'package:ortto_flutter_sdk_platform_interface/src/models/push_permission.dart';
export 'package:ortto_flutter_sdk_platform_interface/src/models/user_id.dart';
export 'package:ortto_flutter_sdk_platform_interface/src/models/identity_result.dart';
export 'package:ortto_flutter_sdk_platform_interface/src/models/widget_result.dart';


class Ortto {
  Ortto._privateConstructor();

  static final Ortto _instance = Ortto._privateConstructor();

  final OrttoFlutterSdkPlatformInterface _platform = OrttoFlutterSdkPlatformInterface.instance;

  static Ortto get instance {
    return _instance;
  }

  Future<void> init({ 
    required String appKey, 
    required String endpoint,
    bool shouldSkipNonExistingContacts = false,
    bool allowAnonUsers = false,
  }) {
    final config = OrttoConfig(
      appKey, 
      endpoint, 
      shouldSkipNonExistingContacts: shouldSkipNonExistingContacts, 
      allowAnonUsers: allowAnonUsers,
    );

    return _platform.initialize(config);
  }

  Future<void> initCapture({ 
    required String dataSourceKey, 
    required String captureJsUrl, 
    required String apiHost 
  }) {
    final config = CaptureConfig( 
      dataSourceKey,
      captureJsUrl,
      apiHost,
    );

    return _platform.initializeCapture(config);
  }

  Future<void> identify(UserID user) {
    return _platform.identify(user);
  }

  Future<PushPermission> requestPermissions() {
    return _platform.requestPermissions();
  }

  Future<void> registerDeviceToken(String token) {
    return _platform.registerDeviceToken(token);
  }

  Future<WidgetResult> showWidget(String widgetId) {
    return _platform.showWidget(widgetId);
  }

  Future<void> queueWidget(String widgetId) {
    return _platform.queueWidget(widgetId);
  }

  Future<void> processNextWidgetFromQueue() {
    return _platform.processNextWidgetFromQueue(); 
  }

  Future<void> clearData() {
    return _platform.clearData();
  }

  Future<void> dispatchPushRequest() {
    return _platform.dispatchPushRequest();
  }

  Future<LinkUtm> trackLinkClick(String link) {
    return _platform.trackLinkClick(link);
  }

  Future<bool> onbackgroundMessageReceived(Map<String, dynamic> message, {bool handleNotificationTrigger = true}) {
    return _platform.onMessageReceived(message, handleNotificationTrigger: handleNotificationTrigger);
  }

  Future<IdentityResult> clearIdentity() {
    return _platform.clearIdentity();
  }
}
