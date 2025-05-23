import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

/// The iOS implementation of [FlutterOrttoPushSdkPlatform].
class OrttoFlutterSdkIOS extends OrttoFlutterSdkPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('ortto_flutter_sdk_ios');

  /// Registers this class as the default instance of [OrttoFlutterSdkPlatformInterface]
  static void registerWith() {
    OrttoFlutterSdkPlatformInterface.instance = OrttoFlutterSdkIOS();
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
  Future<void> registerDeviceToken(String token) {
    return methodChannel.invokeMethod('registerDeviceToken', {
      'token': token,
    });
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
  Future<void> processNextWidgetFromQueue() {
    return methodChannel.invokeMethod('processNextWidgetFromQueue');
  }

  @override
  Future<bool> onMessageReceived(Map<String, dynamic> message, {bool handleNotificationTrigger = true}) async {
    final bool result = await methodChannel.invokeMethod('onMessageReceived', {
      'message': message,
      'handleNotificationTrigger': handleNotificationTrigger,
    });

    return result;
  }

  @override
  Future<WidgetResult> showWidget(String widgetId) async {
    final result = await methodChannel.invokeMethod("showWidget", {
      'widgetId': widgetId,
    });

    if (result is Map) {
      final map = result.cast<String, dynamic>();
      if (map['success'] == true) {
        return WidgetResult.fromMap(map);
      } else {
        throw Exception(map['message'] ?? 'Failed to show widget');
      }
    } else {
      throw Exception("Invalid response type: ${result.runtimeType}");
    }
  }

  Future<IdentityResult> clearIdentity() async {
    final response = await methodChannel.invokeMethod('clearIdentity');
    if (response != null) {
      final Map<String, dynamic> responseMap = (response as Map).cast<String, dynamic>();

      if (responseMap['success'] != true) {
        throw Exception(responseMap['message'] ?? "Failed to clear identity");
      }

      return IdentityResult.fromMap(responseMap);
    } else {
      throw Exception("Failed to clear identity");
    }
  }
}
