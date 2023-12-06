import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

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

  Future<void> showWidget(String widgetId) {
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
}
