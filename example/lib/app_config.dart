import 'package:flutter/foundation.dart';

/// Reads Ortto configuration for the demo. Mirrors the iOS demo's
/// AppConfiguration: values come from dart-defines (use
/// `--dart-define-from-file=ortto.env.json`, copied from
/// `ortto.env.sample.json` — the real file is gitignored so keys never get
/// committed). Placeholder values are treated as "not configured" so the UI
/// can surface setup issues instead of failing silently.
class AppConfig {
  /// Ortto registers each mobile app per platform, so the push app key can
  /// differ between iOS and Android. The platform-specific define wins;
  /// ORTTO_APP_KEY is the shared fallback.
  static const String _sharedAppKey = String.fromEnvironment(
    'ORTTO_APP_KEY',
    defaultValue: '<APP_KEY>',
  );
  static const String _iosAppKey = String.fromEnvironment(
    'ORTTO_APP_KEY_IOS',
    defaultValue: _sharedAppKey,
  );
  static const String _androidAppKey = String.fromEnvironment(
    'ORTTO_APP_KEY_ANDROID',
    defaultValue: _sharedAppKey,
  );

  static String get orttoAppKey =>
      defaultTargetPlatform == TargetPlatform.iOS ? _iosAppKey : _androidAppKey;

  /// Raw values for Ortto.init, null when not configured — the SDK resolves
  /// the platform itself.
  static String? get iosAppKeyOrNull =>
      _isConfigured(_iosAppKey) ? _iosAppKey : null;
  static String? get androidAppKeyOrNull =>
      _isConfigured(_androidAppKey) ? _androidAppKey : null;
  static String? get sharedAppKeyOrNull =>
      _isConfigured(_sharedAppKey) ? _sharedAppKey : null;

  /// Which define supplied the active app key, so the demo can show whether
  /// the platform-specific key or the shared fallback is in use.
  static String get orttoAppKeySource {
    if (!hasConfiguredAppKey) return 'Not configured';
    final isIOS = defaultTargetPlatform == TargetPlatform.iOS;
    final platformKey = isIOS ? _iosAppKey : _androidAppKey;
    if (platformKey != _sharedAppKey) {
      return isIOS
          ? 'iOS key (ORTTO_APP_KEY_IOS)'
          : 'Android key (ORTTO_APP_KEY_ANDROID)';
    }
    return 'Shared fallback (ORTTO_APP_KEY)';
  }

  static const String orttoAppEndpoint = String.fromEnvironment(
    'ORTTO_ENDPOINT',
    defaultValue: '<APP_ENDPOINT>',
  );

  /// Capture (in-app notifications) uses its own data-source key, separate
  /// from the push app key.
  static const String orttoDatasourceKey = String.fromEnvironment(
    'ORTTO_DATA_SOURCE_KEY',
    defaultValue: '<DATA_SOURCE_KEY>',
  );
  static const String orttoCaptureJsUrl = String.fromEnvironment(
    'ORTTO_CAPTURE_JS_URL',
    defaultValue: '<CAPTURE_JS_URL>',
  );
  static const String orttoApiHost = String.fromEnvironment(
    'ORTTO_API_HOST',
    defaultValue: '<API_HOST>',
  );

  static bool get hasConfiguredAppKey => _isConfigured(orttoAppKey);
  static bool get hasConfiguredEndpoint => _isConfigured(orttoAppEndpoint);
  static bool get hasConfiguredCaptureJsUrl => _isConfigured(orttoCaptureJsUrl);
  static bool get hasConfiguredCaptureDataSourceKey =>
      _isConfigured(orttoDatasourceKey);
  static bool get canInitializeSDK =>
      hasConfiguredAppKey && hasConfiguredEndpoint;

  /// Capture needs BOTH its own data-source key and the capture JS URL.
  static bool get canInitializeCapture =>
      hasConfiguredCaptureDataSourceKey && hasConfiguredCaptureJsUrl;

  static String get orttoConfigurationFailureDetail {
    if (!hasConfiguredAppKey) {
      return 'No Ortto app key for this platform. Copy ortto.env.sample.json '
          'to ortto.env.json, fill in the values, then run with '
          '--dart-define-from-file=ortto.env.json.';
    }
    return 'Set ORTTO_ENDPOINT in ortto.env.json and run with '
        '--dart-define-from-file=ortto.env.json.';
  }

  static bool _isConfigured(String value) {
    final trimmed = value.trim();
    if (trimmed.isEmpty) return false;
    final lowered = trimmed.toLowerCase();
    return !lowered.startsWith('<') &&
        !lowered.contains('paste_') &&
        !lowered.contains('replace-with') &&
        !lowered.contains('your-');
  }
}
