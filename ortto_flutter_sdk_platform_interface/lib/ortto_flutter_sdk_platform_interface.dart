import 'package:ortto_flutter_sdk_platform_interface/src/method_channel_ortto_flutter_sdk.dart';
import 'package:ortto_flutter_sdk_platform_interface/src/models/capture_config.dart';
import 'package:ortto_flutter_sdk_platform_interface/src/models/link_utm.dart';
import 'package:ortto_flutter_sdk_platform_interface/src/models/ortto_config.dart';
import 'package:ortto_flutter_sdk_platform_interface/src/models/push_permission.dart';
import 'package:ortto_flutter_sdk_platform_interface/src/models/user_id.dart';
import 'src/models/identity_result.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

export 'src/models/capture_config.dart';
export 'src/models/link_utm.dart';
export 'src/models/ortto_config.dart';
export 'src/models/push_permission.dart';
export 'src/models/user_id.dart';
export 'src/models/identity_result.dart';


/// The interface that implementations of flutter_ortto_push_sdk must implement.
///
/// Platform implementations should extend this class
/// rather than implement it as `FlutterOrttoPushSdk`.
/// Extending this class (using `extends`) ensures that the subclass will get
/// the default implementation, while platform implementations that `implements`
///  this interface will be broken by newly added [OrttoFlutterSdkPlatformInterface] methods.
abstract class OrttoFlutterSdkPlatformInterface extends PlatformInterface {
  /// Constructs a FlutterOrttoPushSdkPlatform.
  OrttoFlutterSdkPlatformInterface() : super(token: _token);

  static final Object _token = Object();

  static OrttoFlutterSdkPlatformInterface _instance = MethodChannelOrttoFlutterSdk();

  /// The default instance of [OrttoFlutterSdkPlatformInterface] to use.
  ///
  /// Defaults to [MethodChannelFlutterOrttoPushSdk].
  static OrttoFlutterSdkPlatformInterface get instance => _instance;

  /// Platform-specific plugins should set this with their own platform-specific
  /// class that extends [OrttoFlutterSdkPlatformInterface] when they register themselves.
  static set instance(OrttoFlutterSdkPlatformInterface instance) {
    PlatformInterface.verify(instance, _token);
    _instance = instance;
  }

  /// Return the current platform name.
  Future<String?> getPlatformName();

  /// Initialize Ortto Push
  Future<void> initialize(OrttoConfig config);

  /// Initialize Ortto Capture
  Future<void> initializeCapture(CaptureConfig config);

  Future<void> identify(UserID user);

  Future<void> clearData();

  Future<PushPermission> requestPermissions();

  Future<void> registerDeviceToken(String token);

  Future<void> dispatchPushRequest();

  Future<LinkUtm> trackLinkClick(String link);

  Future<void> queueWidget(String widgetId);

  Future<void> showWidget(String widgetId);

  Future<void> processNextWidgetFromQueue();

  Future<bool> onMessageReceived(Map<String, dynamic> message, {bool handleNotificationTrigger = true}) {
    throw UnimplementedError('onMessageReceived() has not been implemented.');
  }

  Future<bool> onBackgroundMessageReceived(Map<String, dynamic> message) {
    return onMessageReceived(message,  handleNotificationTrigger: message['notification'] == null);
  }

  Future<IdentityResult> clearIdentity();
}

