import 'dart:async';
import 'dart:convert';

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:ortto_flutter_sdk/ortto_flutter_sdk.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app_config.dart';
import 'models.dart';

/// Demo state and SDK flows, ported from the iOS demo's PushViewModel.
/// Each action validates, calls the Ortto Flutter SDK directly, and reports
/// the outcome via [report] (inline status + floating toast + log line).
class PushModel extends ChangeNotifier {
  PushModel(this._prefs) {
    signedInEmail = _prefs.getString(_kSignedInEmail) ?? '';
    hasAskedFirstOpenPush = _prefs.getBool(_kHasAskedFirstOpenPush) ?? false;
    lastIdentifiedEmail = _prefs.getString(_kLastIdentifiedEmail) ?? '';
    fcmToken = _prefs.getString(_kLastFcmToken) ?? '';
    sdkToken = _prefs.getString(_kLastSdkToken);
    email = lastIdentifiedEmail;
  }

  static const _kSignedInEmail = 'OrttoPushDemo.signedInEmail';
  static const _kHasAskedFirstOpenPush = 'OrttoPushDemo.hasAskedFirstOpenPush';
  static const _kLastIdentifiedEmail = 'OrttoPushDemo.lastIdentifiedEmail';
  static const _kLastFcmToken = 'OrttoPushDemo.lastFcmToken';
  static const _kLastSdkToken = 'OrttoPushDemo.lastSdkToken';

  final SharedPreferences _prefs;

  String signedInEmail = '';
  bool hasAskedFirstOpenPush = false;
  String lastIdentifiedEmail = '';

  String email = '';
  AppTab selectedTab = AppTab.home;

  /// Set when a notification tap arrives, so the UI can present an in-app
  /// confirmation modal before navigating. Null when dismissed.
  DeepLinkPrompt? deepLinkPrompt;

  /// The reason the most recent identify failed, surfaced to the user so a
  /// misconfigured endpoint/app key is visible, not silent.
  String? lastIdentifyError;

  /// The session ID the SDK is currently using (from identify or
  /// getSessionId). Null until a session is established.
  String? sessionId;

  /// The 0.7 API does not expose the native session ID, so remember a
  /// successful identify separately from the optional diagnostic ID.
  bool identityEstablished = false;

  bool get hasActiveSession => identityEstablished || sessionId != null;

  /// The token this demo last forwarded to the SDK via registerDeviceToken.
  String? sdkToken;
  String permissionStatus = 'unknown';
  String fcmToken = '';
  String trackedDeepLink = '';
  String widgetID = '';
  List<DemoWidget> availableWidgets = [];
  bool isLoadingWidgets = false;
  final List<LogEntry> logEntries = [];
  bool isIdentifying = false;
  bool isLoggingOut = false;
  bool isRequestingPush = false;
  bool isTrackingLinkClick = false;
  bool isUsingRememberedLogin = true;
  final Map<SDKActionID, SDKActionStatus> actionStatuses = {};
  SDKToast? actionToast;
  int toastGeneration = 0;

  final Set<String> _logDedupeKeys = {};
  final Set<String> _sessionSnapshotKeys = {};
  bool _hasPreparedInitialState = false;
  Timer? _firstOpenPushTimer;
  Timer? _toastDismissTimer;
  StreamSubscription<String>? _tokenRefreshSubscription;

  @override
  void dispose() {
    _firstOpenPushTimer?.cancel();
    _toastDismissTimer?.cancel();
    _tokenRefreshSubscription?.cancel();
    super.dispose();
  }

  // MARK: - Derived state

  bool get isSignedIn => signedInEmail.trim().isNotEmpty;

  String get rememberedLoginEmail => normalizedEmail(lastIdentifiedEmail);

  String get visibleRememberedLoginEmail =>
      isUsingRememberedLogin ? rememberedLoginEmail : '';

  String get rememberedContactValue {
    if (rememberedLoginEmail.isEmpty) return 'No';
    return rememberedLoginEmail == signedInEmail ? 'Yes' : rememberedLoginEmail;
  }

  String? get currentPushToken {
    final trimmed = fcmToken.trim();
    if (trimmed.isNotEmpty && !isGeneratedFCMToken(trimmed)) return trimmed;
    if (sdkToken != null && !isGeneratedFCMToken(sdkToken)) return sdkToken;
    return null;
  }

  bool get hasGeneratedFCMToken =>
      isGeneratedFCMToken(sdkToken) || isGeneratedFCMToken(fcmToken);

  bool get isOrttoConfigurationMissing => !AppConfig.canInitializeSDK;

  /// True when the app is running on the placeholder Firebase config, which
  /// can never mint a real FCM registration token.
  bool get isFirebaseConfigStub {
    if (Firebase.apps.isEmpty) return true;
    final options = Firebase.app().options;
    return options.projectId == 'stub-project' ||
        options.apiKey.contains('DemoStubKey');
  }

  /// Short label for whichever Ortto value is missing. App key takes priority,
  /// matching [AppConfig.orttoConfigurationFailureDetail].
  String get orttoConfigurationMissingLabel => AppConfig.hasConfiguredAppKey
      ? 'Ortto endpoint missing'
      : 'Ortto app key missing';

  SDKConfigurationIssue? get orttoConfigurationFailure {
    if (!isOrttoConfigurationMissing) return null;
    return SDKConfigurationIssue(
      title: orttoConfigurationMissingLabel,
      detail: AppConfig.orttoConfigurationFailureDetail,
      severity: SDKConfigurationSeverity.critical,
    );
  }

  List<SDKConfigurationIssue> get blockingConfigurationIssues =>
      configurationIssues
          .where((issue) => issue.severity == SDKConfigurationSeverity.critical)
          .toList();

  SDKActionTone get currentRegisterTone {
    if (isOrttoConfigurationMissing || hasGeneratedFCMToken) {
      return SDKActionTone.blocked;
    }
    return SDKActionTone.ready;
  }

  String get registrationActionTitle {
    if (isOrttoConfigurationMissing) return 'SDK config missing';
    if (hasGeneratedFCMToken) return 'FCM blocked';
    return 'Request FCM token';
  }

  bool get homePushActionDisabled => isRequestingPush;

  String get deliveryTokenStatus {
    final token = currentPushToken;
    if (token != null) return short(token);
    return sdkToken == null ? 'No SDK token' : 'FCM token registered';
  }

  String get currentIdentityStatus =>
      hasActiveSession ? 'Session is active' : 'No active session yet';

  String get currentRegisterStatus {
    if (isOrttoConfigurationMissing) return orttoConfigurationMissingLabel;
    if (isGeneratedFCMToken(fcmToken)) return 'Generated FCM token blocked';
    if (sdkToken != null && sdkToken == fcmToken.trim()) {
      return 'FCM token forwarded to Ortto SDK';
    }
    if (fcmToken.trim().isNotEmpty) return 'Ready to submit pasted FCM token';
    return 'Ready to request Firebase registration token';
  }

  String get pushTokenPlaceholder {
    if (isOrttoConfigurationMissing) return orttoConfigurationMissingLabel;
    if (hasGeneratedFCMToken) return 'invalid generated token blocked';
    return 'No FCM token yet';
  }

  String get currentRedispatchStatus => sdkToken == null
      ? 'Needs an SDK token first'
      : 'SDK token ready to redispatch';

  String get currentTrackLinkStatus {
    final value = trackedDeepLink.trim();
    if (value.isEmpty) return 'Paste a tracked push-action deeplink';
    if (Uri.tryParse(value) == null) return 'Deeplink is not a valid URL';
    if (!deepLinkContainsTrackingURL(value)) {
      return 'Deeplink is missing tracking_url';
    }
    return 'Tracked deeplink ready';
  }

  SDKActionTone get currentTrackLinkTone {
    final value = trackedDeepLink.trim();
    if (value.isEmpty) return SDKActionTone.ready;
    if (Uri.tryParse(value) == null || !deepLinkContainsTrackingURL(value)) {
      return SDKActionTone.warning;
    }
    return SDKActionTone.ready;
  }

  String get currentPermissionStatus => 'Permission status: $permissionStatus';

  String get currentShowWidgetStatus {
    if (!AppConfig.hasConfiguredCaptureJsUrl) {
      return 'Set ORTTO_CAPTURE_JS_URL to enable widgets';
    }
    return widgetID.trim().isEmpty
        ? 'Enter a widget ID to show'
        : 'Ready to show widget';
  }

  SDKActionTone get showWidgetTone => AppConfig.hasConfiguredCaptureJsUrl
      ? SDKActionTone.ready
      : SDKActionTone.blocked;

  String get currentLoadWidgetsStatus {
    if (!AppConfig.canInitializeSDK) return 'Configure the SDK to load widgets';
    return availableWidgets.isEmpty
        ? "Load this account's popup widgets"
        : '${availableWidgets.length} popup widget(s) loaded';
  }

  List<SDKConfigurationIssue> get configurationIssues {
    final issues = <SDKConfigurationIssue>[];

    if (!hasActiveSession) {
      issues.add(const SDKConfigurationIssue(
        title: 'No active SDK session',
        detail:
            'Identify needs to complete before token dispatch can be tied to a user.',
        severity: SDKConfigurationSeverity.warning,
      ));
    }

    final orttoFailure = orttoConfigurationFailure;
    if (orttoFailure != null) issues.add(orttoFailure);

    if (isFirebaseConfigStub) {
      issues.add(const SDKConfigurationIssue(
        title: 'Firebase rejects the placeholder API key',
        detail:
            'firebaseinstallations.googleapis.com returns HTTP 400 API_KEY_INVALID for the stub project, so FCM cannot mint a registration token (retries then surface as "Too many server requests"). Run flutterfire configure to install real Firebase config.',
        severity: SDKConfigurationSeverity.critical,
      ));
    }

    if (hasGeneratedFCMToken) {
      issues.add(const SDKConfigurationIssue(
        title: 'Invalid generated FCM token detected',
        detail:
            'A previous build remembered an fcm_demo token. Paste or register a real Firebase token before using FCM results.',
        severity: SDKConfigurationSeverity.critical,
      ));
    }

    if (permissionStatus == 'denied') {
      issues.add(const SDKConfigurationIssue(
        title: 'Push permission denied',
        detail:
            'The OS will not deliver notifications until permission is re-enabled in Settings.',
        severity: SDKConfigurationSeverity.critical,
      ));
    } else if (permissionStatus == 'not determined') {
      issues.add(const SDKConfigurationIssue(
        title: 'Push permission has not been requested',
        detail: 'Run registration to trigger the notification permission path.',
        severity: SDKConfigurationSeverity.warning,
      ));
    }

    if (fcmToken.trim().isEmpty && sdkToken == null) {
      issues.add(const SDKConfigurationIssue(
        title: 'Waiting for Firebase token',
        detail:
            'Firebase Messaging provides the registration token after permission is granted.',
        severity: SDKConfigurationSeverity.warning,
      ));
    }

    if (sdkToken == null) {
      issues.add(const SDKConfigurationIssue(
        title: 'No SDK push token',
        detail: 'Register FCM to forward a device token to the Ortto SDK.',
        severity: SDKConfigurationSeverity.warning,
      ));
    }

    if (!AppConfig.canInitializeCapture) {
      issues.add(const SDKConfigurationIssue(
        title: 'Capture (in-app) not configured',
        detail:
            'Set ORTTO_DATA_SOURCE_KEY and ORTTO_CAPTURE_JS_URL to enable in-app notifications.',
        severity: SDKConfigurationSeverity.warning,
      ));
    }

    return issues;
  }

  SDKActionStatus actionStatus(
    SDKActionID id, {
    required String fallback,
    SDKActionTone tone = SDKActionTone.ready,
  }) {
    return actionStatuses[id] ?? SDKActionStatus(text: fallback, tone: tone);
  }

  // MARK: - Status and toast plumbing

  void setActionStatus(SDKActionID id, String text, SDKActionTone tone) {
    actionStatuses[id] = SDKActionStatus(text: text, tone: tone);
    notifyListeners();
  }

  void showToast({
    required String title,
    required String detail,
    required SDKActionTone tone,
  }) {
    _toastDismissTimer?.cancel();
    actionToast = SDKToast(title: title, detail: detail, tone: tone);
    toastGeneration += 1;
    notifyListeners();

    _toastDismissTimer = Timer(const Duration(milliseconds: 2400), () {
      actionToast = null;
      notifyListeners();
    });
  }

  /// Paints an action's inline status and the floating toast in one call;
  /// every SDK action reports progress through this.
  void report(
    SDKActionID id,
    SDKActionTone tone, {
    required String status,
    required String toast,
    required String detail,
  }) {
    setActionStatus(id, status, tone);
    showToast(title: toast, detail: detail, tone: tone);
  }

  // MARK: - Clipboard

  void copyCurrentPushToken() {
    copyToClipboard(currentPushToken, 'FCM push token');
  }

  Future<void> copyToClipboard(String? value, String label) async {
    if (value == null || value.trim().isEmpty) {
      showToast(
        title: 'Nothing to copy',
        detail: 'No $label is available yet.',
        tone: SDKActionTone.blocked,
      );
      appendLog('copy blocked: missing $label');
      return;
    }

    await Clipboard.setData(ClipboardData(text: value));
    showToast(
      title: 'Copied',
      detail: '${_capitalized(label)} copied to clipboard.',
      tone: SDKActionTone.success,
    );
    appendLog('copied $label $value');
  }

  // MARK: - Log feed

  void appendLog(String line, {String? dedupeKey}) {
    if (dedupeKey != null) {
      if (_logDedupeKeys.contains(dedupeKey)) return;
      _logDedupeKeys.add(dedupeKey);
    }
    appendRawLog(
      LogEntry(source: LogSource.demo, level: LogLevel.info, message: line),
    );
  }

  void appendSdkLog(String line, {LogLevel level = LogLevel.info}) {
    appendRawLog(LogEntry(source: LogSource.sdk, level: level, message: line));
  }

  void appendRawLog(LogEntry entry) {
    logEntries.add(entry);
    notifyListeners();
  }

  void recordSessionSnapshot() {
    final key = [
      sessionId ?? 'anonymous',
      sdkToken == null ? 'no-token' : short(sdkToken),
      permissionStatus,
    ].join('|');

    if (_sessionSnapshotKeys.contains(key)) return;
    _sessionSnapshotKeys.add(key);
    appendLog(
      'session snapshot: ${sessionId ?? "anonymous"} / '
      '${sdkToken == null ? "no-token" : short(sdkToken)} / '
      '$permissionStatus',
    );
  }

  /// Forwards foreground iOS delivery through Ortto and leaves a sanitized
  /// observable breadcrumb for the physical-device test matrix.
  Future<void> handleForegroundMessage(RemoteMessage message) async {
    final messageLabel = message.messageId?.trim().isNotEmpty == true
        ? short(message.messageId)
        : 'no-message-id';
    appendLog('foreground FCM message received: $messageLabel');
    try {
      final handled =
          await Ortto.instance.onBackgroundMessageReceived(message.toMap());
      appendSdkLog('foreground message forwarded to Ortto: handled=$handled');
    } catch (error) {
      appendSdkLog('foreground message forwarding failed: $error',
          level: LogLevel.error);
    }
  }

  // MARK: - Deep links (notification tap routing)

  /// Routes a deeplink from a tapped push notification. The URL host selects
  /// the screen (e.g. `ortto-demo://delivery`); any `tracking_url` query is
  /// ignored — the SDK already tracked the click on its way through.
  void handleDeepLink(String link) {
    appendLog('deeplink opened: $link');

    final uri = Uri.tryParse(link);
    final target = (uri?.host.isNotEmpty ?? false)
        ? uri!.host.toLowerCase()
        : (uri?.pathSegments.isNotEmpty ?? false)
            ? uri!.pathSegments.first.toLowerCase()
            : '';

    switch (target) {
      case 'confirm':
        // Default (body-tap) action: confirm in-app before doing anything.
        deepLinkPrompt = DeepLinkPrompt(link: link);
      case 'delivery' || 'campaign' || 'push':
        selectedTab = AppTab.delivery;
      case 'log' || 'logs' || 'diagnostics':
        selectedTab = AppTab.diagnostics;
      case 'home' || '':
        selectedTab = AppTab.home;
      default:
        appendLog("deeplink host '$target' unrecognized — no screen change");
    }

    if (!isSignedIn) {
      appendLog(
          'deeplink received while signed out — screen applies after sign-in');
    }
    notifyListeners();
  }

  /// Confirms the pending default-action deeplink: dismiss the modal and
  /// navigate to the Delivery screen.
  void confirmDeepLinkPrompt() {
    final link = deepLinkPrompt?.link;
    if (link != null) {
      appendLog('deeplink confirmed: $link — opening Delivery');
    }
    deepLinkPrompt = null;
    selectedTab = AppTab.delivery;
    notifyListeners();
  }

  /// Dismisses the pending default-action deeplink without navigating.
  void dismissDeepLinkPrompt() {
    final link = deepLinkPrompt?.link;
    if (link != null) {
      appendLog('deeplink dismissed: $link');
    }
    deepLinkPrompt = null;
    notifyListeners();
  }

  /// Pulls an action link out of a notification payload, if one exists.
  void handleNotificationTap(Map<String, dynamic> data) {
    final link = (data['link'] ??
            data['action_link'] ??
            data['deep_link'] ??
            data['url'])
        ?.toString();
    appendLog('notification tapped: ${jsonEncode(data)}');
    if (link != null && link.isNotEmpty) {
      handleDeepLink(link);
    }
  }

  // MARK: - Identify

  void runIdentifyAction() {
    report(
      SDKActionID.identify,
      SDKActionTone.working,
      status: 'Identifying signed-in account...',
      toast: 'Identify started',
      detail: 'Calling Ortto.instance.identify.',
    );
    identify(signedInEmail);
  }

  /// Identifies the signed-in contact. Calls the SDK directly —
  /// `Ortto.instance.identify` is the integration point; the future only
  /// drives UI state and surfaces failures.
  Future<void> identify(String rawEmail) async {
    final cleaned = normalizedEmail(rawEmail);
    if (cleaned.isEmpty) return;

    // Calling the SDK before init() hard-crashes natively, so an
    // unconfigured demo surfaces the config issue instead. The local
    // sign-in still completes — the demo stays explorable without keys.
    if (isOrttoConfigurationMissing) {
      appendLog(
          'identify skipped: ${AppConfig.orttoConfigurationFailureDetail}',
          dedupeKey: 'identify:unconfigured');
      report(
        SDKActionID.identify,
        SDKActionTone.blocked,
        status: orttoConfigurationMissingLabel,
        toast: 'Signed in locally — identify skipped',
        detail: AppConfig.orttoConfigurationFailureDetail,
      );
      return;
    }

    isIdentifying = true;
    notifyListeners();

    appendLog('calling Ortto.instance.identify for $cleaned');
    try {
      await Ortto.instance.identify(UserID(email: cleaned, acceptsGdpr: true));
      isIdentifying = false;
      sessionId = null;
      identityEstablished = true;
      lastIdentifiedEmail = cleaned;
      await _prefs.setString(_kLastIdentifiedEmail, cleaned);
      lastIdentifyError = null;
      appendSdkLog(
          'Ortto.instance.identify completed for $cleaned; session ${sessionId ?? "unknown"}');
      setActionStatus(
        SDKActionID.identify,
        'Identify complete; active session updated',
        SDKActionTone.success,
      );
    } catch (error) {
      isIdentifying = false;
      lastIdentifyError = error.toString();
      appendSdkLog('Ortto.instance.identify failed: $error',
          level: LogLevel.error);
      _surfaceIdentifyFailure();
    }
    recordSessionSnapshot();
    notifyListeners();
  }

  /// Surfaces an identify failure to the user. A server rejection (e.g. a 404
  /// from a wrong endpoint/app key) is shown as blocked with the actual reason
  /// so a misconfiguration is visible, not silently swallowed.
  void _surfaceIdentifyFailure() {
    final reason = lastIdentifyError ?? 'Identify did not complete.';
    if (reason.contains('Server error') || reason.contains('404')) {
      setActionStatus(
        SDKActionID.identify,
        'Ortto rejected identify — check endpoint / app key',
        SDKActionTone.blocked,
      );
      showToast(
        title: 'Identify rejected — check config',
        detail:
            '$reason\n\nVerify ORTTO_ENDPOINT and ORTTO_APP_KEY point at the same Ortto instance.',
        tone: SDKActionTone.blocked,
      );
    } else {
      setActionStatus(
        SDKActionID.identify,
        'Identify did not complete',
        SDKActionTone.warning,
      );
      showToast(
        title: 'Identify failed',
        detail: reason,
        tone: SDKActionTone.warning,
      );
    }
  }

  // MARK: - Login and logout

  void signIn(String rawEmail) {
    final cleaned = normalizedEmail(rawEmail);
    if (cleaned.isEmpty) return;
    _cancelPendingFirstOpenPushForLogin();
    email = cleaned;

    // Sign in locally right away, then identify in the background. Order vs.
    // identify doesn't matter; a failure surfaces via the identify handler.
    _completeLogin(cleaned);
    identify(cleaned);

    // Signing in also kicks off push registration: the permission prompt,
    // then the Firebase token is fetched and forwarded to the SDK.
    if (!hasAskedFirstOpenPush && !isOrttoConfigurationMissing) {
      hasAskedFirstOpenPush = true;
      _prefs.setBool(_kHasAskedFirstOpenPush, true);
      appendLog('sign-in: starting push registration');
      runRegisterPushAction();
    }
  }

  void _completeLogin(String cleaned) {
    signedInEmail = cleaned;
    email = cleaned;
    isUsingRememberedLogin = true;
    _prefs.setString(_kSignedInEmail, cleaned);
    appendLog('customer signed in as $cleaned');
    notifyListeners();
  }

  void useAnotherAccount() {
    isUsingRememberedLogin = false;
    email = '';
    notifyListeners();
  }

  void _cancelPendingFirstOpenPushForLogin() {
    if (_firstOpenPushTimer == null) return;
    _firstOpenPushTimer?.cancel();
    _firstOpenPushTimer = null;
    appendLog('first-open push prompt deferred: login started');
  }

  Future<void> logout() async {
    if (isLoggingOut) {
      appendLog('logout skipped: already in flight',
          dedupeKey: 'logout:in-flight');
      return;
    }

    isLoggingOut = true;
    notifyListeners();
    if (isOrttoConfigurationMissing) {
      appendLog(
          'clearIdentity skipped: SDK not configured; clearing local state');
    } else {
      appendLog('calling Ortto.instance.clearIdentity');
      try {
        final result = await Ortto.instance.clearIdentity();
        appendSdkLog(
            'Ortto.instance.clearIdentity completed: session ${result.sessionId ?? "none"}');
      } catch (error) {
        appendSdkLog('Ortto.instance.clearIdentity failed: $error',
            level: LogLevel.error);
      }
    }
    isLoggingOut = false;
    sessionId = await _readSessionId();
    identityEstablished = false;
    signedInEmail = '';
    isUsingRememberedLogin = true;
    actionStatuses.clear();
    await _prefs.setString(_kSignedInEmail, '');
    notifyListeners();
  }

  // MARK: - Push registration

  Future<void> runRegisterPushAction() async {
    final failure = orttoConfigurationFailure;
    if (failure != null) {
      appendLog(
          'register FCM blocked: ${AppConfig.orttoConfigurationFailureDetail}');
      report(
        SDKActionID.registerPush,
        SDKActionTone.blocked,
        status: failure.title,
        toast: failure.title,
        detail: failure.detail,
      );
      return;
    }

    if (isGeneratedFCMToken(fcmToken)) {
      appendLog('register FCM blocked: generated token detected');
      report(
        SDKActionID.registerPush,
        SDKActionTone.blocked,
        status: 'Generated FCM token blocked',
        toast: 'Registration blocked',
        detail: 'That is a generated token, not a real FCM registration token.',
      );
      return;
    }

    report(
      SDKActionID.registerPush,
      SDKActionTone.working,
      status: 'Registering FCM...',
      toast: 'Registration started',
      detail: 'Registering FCM push messaging.',
    );

    final failureReason = await _registerFCM();
    if (failureReason == null) {
      final message = sdkToken == null
          ? 'FCM registration requested; waiting for Firebase callback'
          : 'FCM token forwarded to Ortto SDK';
      report(
        SDKActionID.registerPush,
        SDKActionTone.success,
        status: message,
        toast: 'Registration started',
        detail: message,
      );
    } else {
      report(
        SDKActionID.registerPush,
        failureReason.contains('stub')
            ? SDKActionTone.blocked
            : SDKActionTone.warning,
        status: failureReason,
        toast: 'Registration failed',
        detail: failureReason,
      );
    }
  }

  /// Requests permission then fetches the Firebase registration token and
  /// forwards it to the Ortto SDK. Returns null when the flow started
  /// cleanly, or a human-readable failure reason.
  Future<String?> _registerFCM() async {
    await requestPushPermission('FCM registration');

    final pasted = fcmToken.trim();
    if (pasted.isNotEmpty) {
      return await registerFCMToken(pasted)
          ? null
          : 'Pasted token was not accepted; check the log';
    }

    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token == null || token.isEmpty) {
        appendLog('waiting for Firebase Messaging registration token callback');
        return null;
      }
      fcmToken = token;
      await _prefs.setString(_kLastFcmToken, token);
      notifyListeners();
      return await registerFCMToken(token)
          ? null
          : 'Token was not accepted by the SDK; check the log';
    } catch (error) {
      // Surface Firebase's own error; the stub note is context, not the
      // message. Note "Too many server requests." is Firebase throttling its
      // retries after the underlying failure (e.g. API_KEY_INVALID).
      var reason = error is FirebaseException
          ? 'Firebase getToken failed: ${error.message ?? error.code}'
          : 'Firebase getToken failed: $error';
      if (isFirebaseConfigStub) {
        reason += ' (running on the stub Firebase project, which the '
            'Firebase API rejects with API_KEY_INVALID)';
      }
      appendSdkLog(reason, level: LogLevel.error);
      return reason;
    }
  }

  /// Submits a pasted or Firebase-provided FCM token to the SDK.
  Future<bool> registerFCMToken(String rawToken) async {
    final token = rawToken.trim();
    if (token.isEmpty) {
      appendLog('FCM registration skipped: token is empty',
          dedupeKey: 'fcm:empty');
      return false;
    }
    if (isGeneratedFCMToken(token)) {
      appendLog('FCM registration skipped: generated token detected');
      return false;
    }

    if (isOrttoConfigurationMissing) {
      appendLog('registerDeviceToken skipped: SDK not configured',
          dedupeKey: 'fcm:unconfigured');
      return false;
    }

    appendLog(
        'calling Ortto.instance.registerDeviceToken with ${short(token)}');
    try {
      // The Android SDK only fires its completion callback on success, so a
      // server rejection would otherwise hang this await forever.
      await Ortto.instance
          .registerDeviceToken(token)
          .timeout(const Duration(seconds: 12));
      sdkToken = token;
      await _prefs.setString(_kLastSdkToken, token);
      appendSdkLog('Ortto.instance.registerDeviceToken completed');
      setActionStatus(
        SDKActionID.registerPush,
        'FCM token forwarded to Ortto SDK',
        SDKActionTone.success,
      );
      recordSessionSnapshot();
      notifyListeners();
      return true;
    } on TimeoutException {
      appendSdkLog(
          'Ortto.instance.registerDeviceToken gave no completion within 12s '
          '— the SDK reports only success, so the server likely rejected the '
          'token (check the app key for this platform)',
          level: LogLevel.warning);
      return false;
    } catch (error) {
      appendSdkLog('Ortto.instance.registerDeviceToken failed: $error',
          level: LogLevel.error);
      return false;
    }
  }

  Future<void> requestPushPermission(String source) async {
    if (isRequestingPush) {
      appendLog('push permission skipped: request already in flight',
          dedupeKey: 'push:in-flight');
      return;
    }

    isRequestingPush = true;
    notifyListeners();
    appendLog('requesting push permission: $source');
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) {
      try {
        // On Apple platforms Firebase owns the OS authorization prompt. The
        // Ortto iOS bridge reports the current state but does not show it.
        final settings = await FirebaseMessaging.instance.requestPermission(
          alert: true,
          badge: true,
          sound: true,
        );
        appendLog(
          'FirebaseMessaging.requestPermission result: '
          '${settings.authorizationStatus.name}',
        );
      } catch (error) {
        appendLog('Firebase permission error: $error');
      }
    } else if (isOrttoConfigurationMissing) {
      appendLog('Ortto.requestPermissions skipped: SDK not configured; '
          'requesting via Firebase Messaging only');
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (error) {
        appendLog('Firebase permission error: $error');
      }
    } else {
      try {
        // Ortto SDK: push permission prompt + registration path.
        final permission = await Ortto.instance.requestPermissions();
        appendSdkLog(
            'Ortto.instance.requestPermissions result: ${permission.name}');
      } catch (error) {
        appendSdkLog('push permission error: $error', level: LogLevel.error);
      }
    }
    isRequestingPush = false;
    notifyListeners();
    await refreshPermission();
  }

  /// Forwards a refreshed Firebase token to the SDK; wired at boot.
  void watchTokenRefresh() {
    _tokenRefreshSubscription ??=
        FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      appendLog('Firebase token refresh callback received');
      fcmToken = token;
      _prefs.setString(_kLastFcmToken, token);
      registerFCMToken(token);
    });
  }

  Future<void> runRedispatchAction() async {
    if (isOrttoConfigurationMissing) {
      report(
        SDKActionID.redispatch,
        SDKActionTone.blocked,
        status: orttoConfigurationMissingLabel,
        toast: 'Not configured',
        detail: AppConfig.orttoConfigurationFailureDetail,
      );
      return;
    }
    if (sdkToken == null) {
      appendLog('re-dispatch skipped: no SDK token',
          dedupeKey: 'redispatch:none');
      report(
        SDKActionID.redispatch,
        SDKActionTone.blocked,
        status: 'No SDK token to redispatch',
        toast: 'Redispatch blocked',
        detail: 'Register a push token first.',
      );
      return;
    }

    report(
      SDKActionID.redispatch,
      SDKActionTone.working,
      status: 'Calling dispatchPushRequest...',
      toast: 'Redispatch started',
      detail: 'Calling Ortto.instance.dispatchPushRequest.',
    );
    try {
      await Ortto.instance.dispatchPushRequest();
      appendSdkLog('Ortto.instance.dispatchPushRequest completed');
      report(
        SDKActionID.redispatch,
        SDKActionTone.success,
        status: 'Redispatch called; watching SDK de-dupe logs',
        toast: 'Redispatch called',
        detail: 'Watch the Log tab for SDK de-dupe output.',
      );
    } catch (error) {
      appendSdkLog('Ortto.instance.dispatchPushRequest failed: $error',
          level: LogLevel.error);
      report(
        SDKActionID.redispatch,
        SDKActionTone.warning,
        status: 'Redispatch failed; check the log',
        toast: 'Redispatch failed',
        detail: error.toString(),
      );
    }
  }

  // MARK: - Click tracking

  Future<void> runTrackLinkAction() async {
    final deepLink = trackedDeepLink.trim();
    if (deepLink.isEmpty) {
      report(
        SDKActionID.trackLink,
        SDKActionTone.blocked,
        status: 'Paste a tracked push-action deeplink first',
        toast: 'Missing deeplink',
        detail: 'Paste a push action deeplink containing tracking_url.',
      );
      appendLog('link tracking blocked: no deeplink pasted');
      return;
    }

    final uri = Uri.tryParse(deepLink);
    if (uri == null) {
      report(
        SDKActionID.trackLink,
        SDKActionTone.blocked,
        status: 'Deeplink is not a valid URL',
        toast: 'Invalid deeplink',
        detail: 'The pasted value is not a URL.',
      );
      appendLog('link tracking blocked: invalid deeplink $deepLink');
      return;
    }

    if (!deepLinkContainsTrackingURL(deepLink)) {
      report(
        SDKActionID.trackLink,
        SDKActionTone.blocked,
        status: 'Deeplink is missing tracking_url',
        toast: 'Missing tracking URL',
        detail: 'Ortto click tracking requires a tracking_url query item.',
      );
      appendLog(
          'link tracking blocked: deeplink missing tracking_url $deepLink');
      return;
    }

    if (isOrttoConfigurationMissing) {
      report(
        SDKActionID.trackLink,
        SDKActionTone.blocked,
        status: orttoConfigurationMissingLabel,
        toast: 'Not configured',
        detail: AppConfig.orttoConfigurationFailureDetail,
      );
      appendLog('link tracking blocked: SDK not configured');
      return;
    }

    if (!hasActiveSession) {
      appendLog(
          'link tracking warning: no active SDK session before trackLinkClick');
    }

    isTrackingLinkClick = true;
    report(
      SDKActionID.trackLink,
      SDKActionTone.working,
      status: 'Calling Ortto.instance.trackLinkClick...',
      toast: 'Tracking link',
      detail: 'Calling Ortto.instance.trackLinkClick.',
    );
    appendLog('calling Ortto.instance.trackLinkClick for $deepLink');

    try {
      final utm = await Ortto.instance
          .trackLinkClick(deepLink)
          .timeout(const Duration(seconds: 12));
      isTrackingLinkClick = false;
      final utmSummary = _utmSummary(utm);
      if (utmSummary != null) {
        appendLog('deeplink UTM parameters: $utmSummary');
      }
      report(
        SDKActionID.trackLink,
        SDKActionTone.success,
        status: 'Click tracking request completed',
        toast: 'Click tracked',
        detail: 'The SDK completed the link tracking call.',
      );
      appendSdkLog('Ortto.instance.trackLinkClick completed for $deepLink');
      recordSessionSnapshot();
    } on TimeoutException {
      isTrackingLinkClick = false;
      report(
        SDKActionID.trackLink,
        SDKActionTone.warning,
        status: 'No completion yet; check the SDK log',
        toast: 'Still waiting',
        detail: 'No SDK completion was received. Check Log for SDK output.',
      );
      appendLog(
          'Ortto.instance.trackLinkClick did not complete within 12s for $deepLink');
    } catch (error) {
      isTrackingLinkClick = false;
      report(
        SDKActionID.trackLink,
        SDKActionTone.warning,
        status: 'Track link failed; check the SDK log',
        toast: 'Track link failed',
        detail: error.toString(),
      );
      appendSdkLog('Ortto.instance.trackLinkClick failed: $error',
          level: LogLevel.error);
    }
    notifyListeners();
  }

  /// Formats the UTM parameters the SDK extracts from a tracked deeplink,
  /// e.g. "utm_source=ortto utm_campaign=demo". Null when none are present.
  String? _utmSummary(LinkUtm utm) {
    final values = <String, String?>{
      'utm_source': utm.source,
      'utm_medium': utm.medium,
      'utm_campaign': utm.campaign,
      'utm_content': utm.content,
    };
    final formatted = values.entries
        .where((entry) => (entry.value ?? '').isNotEmpty)
        .map((entry) => '${entry.key}=${entry.value}')
        .join(' ');
    return formatted.isEmpty ? null : formatted;
  }

  // MARK: - In-app notifications (widgets)

  void runShowWidgetAction() {
    showWidget(widgetID.trim());
  }

  /// Presents an in-app notification by ID — used by both the manual ID field
  /// and the fetched widget picker.
  Future<void> showWidget(String id) async {
    if (!AppConfig.hasConfiguredCaptureJsUrl) {
      report(
        SDKActionID.showWidget,
        SDKActionTone.blocked,
        status: 'Set ORTTO_CAPTURE_JS_URL to enable widgets',
        toast: 'Widgets not configured',
        detail: 'Add a capture JS URL to the app config, then rebuild.',
      );
      appendLog('show widget blocked: ORTTO_CAPTURE_JS_URL not configured');
      return;
    }

    if (id.isEmpty) {
      report(
        SDKActionID.showWidget,
        SDKActionTone.blocked,
        status: 'Pick or enter a widget ID first',
        toast: 'Missing widget ID',
        detail: 'Load the widget list or paste a widget ID.',
      );
      appendLog('show widget blocked: no widget ID');
      return;
    }

    report(
      SDKActionID.showWidget,
      SDKActionTone.working,
      status: 'Calling Ortto.instance.showWidget...',
      toast: 'Showing widget',
      detail: 'Calling Ortto.instance.showWidget.',
    );
    appendLog('calling Ortto.instance.showWidget for $id');

    // Ortto SDK: present a specific in-app notification (widget) by ID. The
    // SDK owns the WebView overlay, fetch, and dismissal.
    try {
      final result = await Ortto.instance.showWidget(id);
      if (result.success ?? false) {
        report(
          SDKActionID.showWidget,
          SDKActionTone.success,
          status: 'Widget shown',
          toast: 'Widget shown',
          detail: 'The SDK presented the in-app notification.',
        );
        appendSdkLog('Ortto.instance.showWidget presented $id');
      } else {
        report(
          SDKActionID.showWidget,
          SDKActionTone.warning,
          status: 'Widget did not show; check the SDK log',
          toast: 'Widget not shown',
          detail: result.message ?? 'The SDK did not present the widget.',
        );
        appendSdkLog(
            'Ortto.instance.showWidget failed for $id: ${result.message ?? "unknown"}',
            level: LogLevel.warning);
      }
    } catch (error) {
      report(
        SDKActionID.showWidget,
        SDKActionTone.warning,
        status: 'Widget did not show; check the SDK log',
        toast: 'Widget not shown',
        detail: error.toString(),
      );
      appendSdkLog('Ortto.instance.showWidget failed for $id: $error',
          level: LogLevel.error);
    }
  }

  /// Lists the account's widgets so the tester can pick one instead of typing
  /// an ID. The SDK keeps its widget fetch internal, so this calls the same
  /// `/-/widgets/get` endpoint directly, then keeps only `popup` types —
  /// the only kind `showWidget` will actually render.
  Future<void> runLoadWidgetsAction() async {
    if (!AppConfig.canInitializeSDK) {
      report(
        SDKActionID.loadWidgets,
        SDKActionTone.blocked,
        status: 'Configure the SDK first',
        toast: 'Not configured',
        detail: AppConfig.orttoConfigurationFailureDetail,
      );
      return;
    }

    isLoadingWidgets = true;
    report(
      SDKActionID.loadWidgets,
      SDKActionTone.working,
      status: 'Fetching widget list...',
      toast: 'Loading widgets',
      detail: 'POST ${AppConfig.orttoAppEndpoint}/-/widgets/get',
    );
    appendLog(
        'fetching widget list: POST ${AppConfig.orttoAppEndpoint}/-/widgets/get');

    try {
      final widgets = await _fetchWidgetList();
      final popups = widgets.where((w) => w.type == 'popup').toList();
      availableWidgets = popups;
      isLoadingWidgets = false;

      final hidden = widgets.length - popups.length;
      final suffix = hidden > 0 ? '; $hidden non-popup hidden' : '';
      report(
        SDKActionID.loadWidgets,
        popups.isEmpty ? SDKActionTone.warning : SDKActionTone.success,
        status: '${popups.length} popup widget(s)$suffix',
        toast: 'Widgets loaded',
        detail: 'Found ${popups.length} popup widget(s)$suffix.',
      );
      appendLog('widget list loaded: ${popups.length} popup, $hidden other');
    } catch (error) {
      isLoadingWidgets = false;
      report(
        SDKActionID.loadWidgets,
        SDKActionTone.warning,
        status: 'Could not load widgets; check the log',
        toast: 'Load failed',
        detail: error.toString(),
      );
      appendLog('widget list fetch failed: $error');
    }
    notifyListeners();
  }

  /// Mirrors the SDK's internal widget fetch (same endpoint, same wire keys)
  /// since those types are not part of the SDK's public surface.
  Future<List<DemoWidget>> _fetchWidgetList() async {
    final base = AppConfig.orttoAppEndpoint;
    final joined =
        base.endsWith('/') ? '$base-/widgets/get' : '$base/-/widgets/get';
    final url = Uri.parse(joined);

    // Wire keys match FetchWidgetsRequest: h = data-source key, tk = talk.
    // Widgets belong to the CAPTURE data source — using the push app key here
    // queries the wrong data source and always returns zero widgets.
    final body = <String, dynamic>{
      'h': AppConfig.orttoDatasourceKey,
      'tk': false,
      'ottlk': '',
      if (sessionId != null) 's': sessionId,
    };

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw Exception(
          'widgets/get returned HTTP ${response.statusCode}: ${response.body}');
    }

    // The endpoint can return a bare `{}` (no session, or no widgets), so the
    // widgets key tolerates being missing rather than throwing.
    final decoded = jsonDecode(response.body);
    final widgets = (decoded is Map<String, dynamic>)
        ? decoded['widgets'] as List<dynamic>? ?? []
        : <dynamic>[];
    return widgets
        .whereType<Map<String, dynamic>>()
        .map((item) => DemoWidget(
              id: item['id']?.toString() ?? '',
              type: item['type']?.toString() ?? '',
            ))
        .where((item) => item.id.isNotEmpty)
        .toList();
  }

  // MARK: - Permission and state refresh

  Future<void> runRefreshPermissionAction() async {
    report(
      SDKActionID.refreshPermission,
      SDKActionTone.working,
      status: 'Reading notification settings...',
      toast: 'Refreshing permission',
      detail: 'Reading notification settings.',
    );
    final status = await refreshPermission();
    report(
      SDKActionID.refreshPermission,
      SDKActionTone.success,
      status: 'Permission status: $status',
      toast: 'Permission refreshed',
      detail: 'Current status: $status.',
    );
  }

  Future<String> refreshPermission() async {
    try {
      final settings =
          await FirebaseMessaging.instance.getNotificationSettings();
      permissionStatus = switch (settings.authorizationStatus) {
        AuthorizationStatus.authorized => 'authorized',
        AuthorizationStatus.denied => 'denied',
        AuthorizationStatus.deniedPermanently => 'denied permanently',
        AuthorizationStatus.notDetermined => 'not determined',
        AuthorizationStatus.provisional => 'provisional',
      };
    } catch (error) {
      appendLog('permission read failed: $error');
      permissionStatus = 'unknown';
    }
    notifyListeners();
    return permissionStatus;
  }

  // MARK: - Boot

  Future<void> prepareInitialState() async {
    if (_hasPreparedInitialState) return;
    _hasPreparedInitialState = true;

    final remembered = normalizedEmail(lastIdentifiedEmail);
    if (remembered.isNotEmpty) {
      isUsingRememberedLogin = true;
      email = remembered;
    }

    appendLog(
        'app boot: provider FCM, signedIn=$isSignedIn, app key: ${AppConfig.orttoAppKeySource}');

    // The SDK persists its session natively; read it back so the UI shows
    // the real session ID from the first frame.
    sessionId = await _readSessionId();
    if (sessionId != null) {
      appendLog('SDK session restored: ${short(sessionId)}');
    }

    if (signedInEmail.isNotEmpty) {
      email = signedInEmail;
      appendLog('remembered account loaded: $signedInEmail');
      identify(signedInEmail);

      // Re-associate the stored push token with Ortto on every open. Fired
      // independently of identify — order doesn't matter, and the SDK
      // self-guards (no-ops) if no token has been registered yet.
      if (isOrttoConfigurationMissing) {
        appendLog('boot token dispatch skipped: SDK not configured');
      } else {
        appendLog('app boot: dispatching stored push token');
        try {
          await Ortto.instance.dispatchPushRequest();
        } catch (error) {
          appendSdkLog('dispatchPushRequest failed at boot: $error',
              level: LogLevel.warning);
        }
      }
    }

    watchTokenRefresh();
    await refreshPermission();
    notifyListeners();
  }

  /// Console line for each tab view's appearance. The Flutter SDK does not
  /// expose a screen() call, so this is demo-side only.
  void logScreenView(AppTab tab) {
    appendLog('screen viewed: ${tab.screenName}',
        dedupeKey: 'screen:${tab.screenName}');
  }

  void performFirstOpenPushIfNeeded() {
    if (hasAskedFirstOpenPush || _firstOpenPushTimer != null) return;
    if (isOrttoConfigurationMissing) {
      appendLog(
          'first-open push skipped: ${AppConfig.orttoConfigurationFailureDetail}',
          dedupeKey: 'first-open:ortto-config');
      return;
    }

    _firstOpenPushTimer = Timer(const Duration(milliseconds: 1400), () {
      _firstOpenPushTimer = null;
      if (isIdentifying) return;
      hasAskedFirstOpenPush = true;
      _prefs.setBool(_kHasAskedFirstOpenPush, true);
      requestPushPermission('first open');
    });
  }

  void selectTab(AppTab tab) {
    if (selectedTab == tab) return;
    selectedTab = tab;
    notifyListeners();
  }

  // MARK: - Small utilities

  /// Flutter 0.7 does not expose the native session identifier. Keep this
  /// adapter so the demo can share its state model with the native demos.
  Future<String?> _readSessionId() async {
    return null;
  }

  String normalizedEmail(String rawEmail) => rawEmail.trim();

  bool isGeneratedFCMToken(String? value) {
    if (value == null) return false;
    return value.trim().toLowerCase().startsWith('fcm_demo_');
  }

  bool deepLinkContainsTrackingURL(String value) {
    final uri = Uri.tryParse(value);
    if (uri == null) return false;
    final tracking = uri.queryParameters['tracking_url'];
    return tracking != null && tracking.isNotEmpty;
  }

  String short(String? value) {
    if (value == null || value.isEmpty) return 'anonymous';
    if (value.length <= 16) return value;
    return '${value.substring(0, 8)}...${value.substring(value.length - 6)}';
  }

  String _capitalized(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
