import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

/// The Android implementation of [FlutterOrttoPushSdkPlatform].
class FlutterOrttoPushSdkAndroid extends OrttoFlutterSdkPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ortto_flutter_sdk_android');

  /// Registers this class as the default instance of [FlutterOrttoPushSdkPlatform]
  static void registerWith() {
    OrttoFlutterSdkPlatformInterface.instance = FlutterOrttoPushSdkAndroid();
  }

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }

  @override
  Future<void> initialize(OrttoConfig config) {
    return methodChannel.invokeMethod<void>('initialize', config.toMap());
  }

  @override
  Future<void> initializeCapture(CaptureConfig config) {
    return methodChannel.invokeMethod<void>('initializeCapture', config.toMap());
  }

  @override
  Future<void> identify(UserID user) {
    return methodChannel.invokeMethod<void>('identify', user.toMap());
  }

  @override
  Future<void> clearData() {
    return methodChannel.invokeMethod('clearData');
  }

  @override
  Future<void> dispatchPushRequest() {
    return methodChannel.invokeMethod('dispatchPushRequest');
  }

  @override
  Future<PushPermission> requestPermissions() {
    return methodChannel.invokeMethod<String>('requestPermissions')
        .then((value) => 
          PushPermission.values
            .firstWhere((e) => e.toString() == 'PushPermission.$value'),
        );
  }

  @override
  Future<void> registerDeviceToken(String token) {
    return methodChannel.invokeMethod('registerDeviceToken', {
      'token': token,
    });
  }

  @override
  Future<LinkUtm> trackLinkClick(String link) {
    return methodChannel.invokeMethod('trackLinkClick', {
      'link': link,
    }).then((value) => LinkUtm.fromMap(value.cast<String, dynamic>()));
  }

  @override
  Future<void> queueWidget(String widgetId) {
    return methodChannel.invokeMethod('queueWidget', {
      'widgetId': widgetId,
    });
  }

  @override
  Future<void> showWidget(String widgetId) {
    return methodChannel.invokeMethod('showWidget', {
      'widgetId': widgetId,
    });
  }

  @override
  Future<void> processNextWidgetFromQueue() {
    return methodChannel.invokeMethod('processNextWidgetInQueue');
  }

  @override
  Future<bool> onMessageReceived(Map<String, dynamic> message, {bool handleNotificationTrigger = true}) async {
    return await methodChannel.invokeMethod('onMessageReceived', {
      'message': message,
      'handleNotificationTrigger': handleNotificationTrigger,
    });
  }
}
