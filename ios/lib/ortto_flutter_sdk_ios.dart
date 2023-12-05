import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ortto_flutter_platform_interface/ortto_flutter_sdk_platform_interface.dart';

/// The iOS implementation of [FlutterOrttoPushSdkPlatform].
class FlutterOrttoPushSdkIOS extends FlutterOrttoPushSdkPlatform {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ortto_push_sdk_ios');

  /// Registers this class as the default instance of [FlutterOrttoPushSdkPlatform]
  static void registerWith() {
    FlutterOrttoPushSdkPlatform.instance = FlutterOrttoPushSdkIOS();
  }

  @override
  Future<String?> getPlatformName() {
    return methodChannel.invokeMethod<String>('getPlatformName');
  }

  @override
  Future<void> initialize(OrttoConfig config) {
    return methodChannel.invokeMethod('initialize', config.toMap());
  }

  @override
  Future<void> initializeCapture(CaptureConfig config) {
    return methodChannel.invokeMethod('initializeCapture', config.toMap());
  }

  @override
  Future<void> identify(UserID user) {
    return methodChannel.invokeMethod('identify', user.toMap());
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
    return methodChannel.invokeMethod('requestPermissions')
        .then((value) =>
          PushPermission.values
            .firstWhere((e) => e.toString() == 'PushPermission.$value'),
        );
  }

  @override
  Future<LinkUtm> trackLinkClick(String link) {
    return methodChannel.invokeMethod("trackLinkClick", {
      'link': link,
    }).then((value) => LinkUtm.fromMap(value.cast<String, String>()));
  }

  @override
  Future<void> queueWidget(String widgetId) {
    return methodChannel.invokeMethod("queueWidget", {
      'widgetId': widgetId,
    });
  }

  @override
  Future<void> showWidget(String widgetId) {
    return methodChannel.invokeMethod("showWidget", {
      'widgetId': widgetId,
    });
  }

  @override
  Future<void> processNextWidgetFromQueue() {
    return methodChannel.invokeMethod('processNextWidgetFromQueue');
  }

  @override
  Future<bool> onMessageReceived(Map<String, dynamic> message, {bool handleNotificationTrigger = true}) {
    methodChannel.invokeMethod('onMessageReceived', {
      'message': message,
      'handleNotificationTrigger': handleNotificationTrigger,
    });
    return Future.value(true);
  }
}
