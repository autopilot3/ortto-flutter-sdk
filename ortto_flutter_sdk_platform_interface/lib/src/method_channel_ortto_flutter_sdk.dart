import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:ortto_flutter_sdk_platform_interface/ortto_flutter_sdk_platform_interface.dart';

import '../ortto_flutter_sdk_platform_interface.dart';

/// An implementation of [OrttoFlutterSdkPlatformInterface] that uses method channels.
class MethodChannelOrttoFlutterSdk extends OrttoFlutterSdkPlatformInterface {
  /// The method channel used to interact with the native platform.
  @visibleForTesting
  final methodChannel = const MethodChannel('flutter_ortto_push_sdk');

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
    throw UnimplementedError();
  }

  @override
  Future<void> clearData() {
    throw UnimplementedError();
  }

  @override
  Future<void> dispatchPushRequest() {
    throw UnimplementedError();
  }

  @override
  Future<void> registerDeviceToken(String token) {
    throw UnimplementedError();
  }

  @override
  Future<PushPermission> requestPermissions() {
    throw UnimplementedError();
  }

  @override
  Future<LinkUtm> trackLinkClick(String link) {
    throw UnimplementedError();
  }

  @override
  Future<void> processNextWidgetFromQueue() {
    throw UnimplementedError();
  }

  @override
  Future<void> queueWidget(String widgetId) {
    throw UnimplementedError();
  }

  @override
  Future<void> showWidget(String widgetId) {
    throw UnimplementedError();
  }

  @override
  Future<IdentityResult> clearIdentity() {
    throw UnimplementedError();
  }
}
