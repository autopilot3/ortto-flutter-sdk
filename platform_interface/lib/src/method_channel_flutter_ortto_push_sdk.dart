import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:flutter/services.dart';
import 'package:ortto_flutter_platform_interface/ortto_flutter_sdk_platform_interface.dart';

/// An implementation of [FlutterOrttoPushSdkPlatform] that uses method channels.
class MethodChannelFlutterOrttoPushSdk extends FlutterOrttoPushSdkPlatform {
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
    // TODO: implement identify
    throw UnimplementedError();
  }

  @override
  Future<void> clearData() {
    // TODO: implement clearData
    throw UnimplementedError();
  }

  @override
  Future<void> dispatchPushRequest() {
    // TODO: implement dispatchPushRequest
    throw UnimplementedError();
  }

  @override
  Future<PushPermission> requestPermissions() {
    // TODO: implement requestPermissions
    throw UnimplementedError();
  }

  @override
  Future<LinkUtm> trackLinkClick(String link) {
    // TODO: implement trackLinkClick
    throw UnimplementedError();
  }

  @override
  Future<void> processNextWidgetFromQueue() {
    // TODO: implement processNextWidgetInQueue
    throw UnimplementedError();
  }

  @override
  Future<void> queueWidget(String widgetId) {
    // TODO: implement queueWidget
    throw UnimplementedError();
  }

  @override
  Future<void> showWidget(String widgetId) {
    // TODO: implement showWidget
    throw UnimplementedError();
  }
}
