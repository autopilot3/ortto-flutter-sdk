import 'package:flutter/material.dart';

import '../design.dart';
import '../models.dart';
import '../push_model.dart';
import 'controls.dart';

/// The Delivery tab: token status, overrides, click tracking, in-app
/// notifications, and the SDK action list.
class DeliveryView extends StatefulWidget {
  const DeliveryView({super.key, required this.model});

  final PushModel model;

  @override
  State<DeliveryView> createState() => _DeliveryViewState();
}

class _DeliveryViewState extends State<DeliveryView> {
  late final TextEditingController _fcmTokenController;
  late final TextEditingController _trackedDeepLinkController;
  late final TextEditingController _widgetIDController;

  PushModel get model => widget.model;

  @override
  void initState() {
    super.initState();
    _fcmTokenController = TextEditingController(text: model.fcmToken);
    _trackedDeepLinkController =
        TextEditingController(text: model.trackedDeepLink);
    _widgetIDController = TextEditingController(text: model.widgetID);
    _fcmTokenController.addListener(() {
      model.fcmToken = _fcmTokenController.text;
    });
    _trackedDeepLinkController.addListener(() {
      model.trackedDeepLink = _trackedDeepLinkController.text;
    });
    _widgetIDController.addListener(() {
      model.widgetID = _widgetIDController.text;
      setState(() {});
    });
    // Keep the token field in sync when Firebase fills it in the background.
    model.addListener(_syncFcmTokenField);
  }

  void _syncFcmTokenField() {
    if (_fcmTokenController.text.isEmpty && model.fcmToken.isNotEmpty) {
      _fcmTokenController.text = model.fcmToken;
    }
  }

  @override
  void dispose() {
    model.removeListener(_syncFcmTokenField);
    _fcmTokenController.dispose();
    _trackedDeepLinkController.dispose();
    _widgetIDController.dispose();
    super.dispose();
  }

  void _dismissKeyboard() => FocusManager.instance.primaryFocus?.unfocus();

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _dismissKeyboard,
      behavior: HitTestBehavior.translucent,
      child: ListView(
        padding: const EdgeInsets.only(top: 4, bottom: 90),
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        children: [
          _currentStatusSection(),
          if (model.blockingConfigurationIssues.isNotEmpty)
            _configurationSection(),
          _fcmTokenOverrideSection(),
          _clickTrackingSection(),
          _inAppNotificationsSection(),
          _actionsSection(),
        ],
      ),
    );
  }

  Widget _currentStatusSection() {
    final token = model.currentPushToken;
    return GroupedSection(
      header: 'Current status',
      children: [
        const LabeledRow('Provider', value: 'Firebase Cloud Messaging'),
        LabeledRow(
          'Token',
          trailing: token != null
              ? CopyableValue(
                  display: model.short(token),
                  isMonospaced: true,
                  onCopy: model.copyCurrentPushToken,
                )
              : null,
          value: token == null ? model.deliveryTokenStatus : null,
        ),
        LabeledRow('Permission', value: model.permissionStatus),
      ],
    );
  }

  Widget _configurationSection() {
    return GroupedSection(
      header: 'Configuration',
      children: [
        ConfigurationIssueRows(issues: model.blockingConfigurationIssues),
        InkWell(
          onTap: () => model.selectTab(AppTab.diagnostics),
          child: const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Text(
              'View Log',
              style: TextStyle(fontSize: 17, color: AppColors.lilac),
            ),
          ),
        ),
      ],
    );
  }

  Widget _fcmTokenOverrideSection() {
    return GroupedSection(
      header: 'FCM token override',
      footer:
          'Filled automatically from Firebase Messaging; paste a token only as a fallback.',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _fcmTokenController,
            autocorrect: false,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.monoFallback),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'Firebase registration token',
            ),
            onSubmitted: (_) => _dismissKeyboard(),
          ),
        ),
      ],
    );
  }

  Widget _clickTrackingSection() {
    return GroupedSection(
      header: 'Click tracking',
      footer:
          'Paste the action deeplink from an Ortto push payload. The automatic tap path calls the same SDK method after the notification response is forwarded.',
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: TextField(
            controller: _trackedDeepLinkController,
            autocorrect: false,
            minLines: 1,
            maxLines: 5,
            style: const TextStyle(
                fontSize: 13,
                fontFamily: AppFonts.mono,
                fontFamilyFallback: AppFonts.monoFallback),
            decoration: const InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: 'ortto-demo://campaign?tracking_url=...',
            ),
          ),
        ),
      ],
    );
  }

  Widget _inAppNotificationsSection() {
    return GroupedSection(
      header: 'In-app notifications',
      footer:
          'Tap Load widgets, then tap a result to present it — or type a widget ID and tap Show.',
      children: [
        // 1 — Fetch the account's popup widgets to choose from.
        DeliveryActionButton(
          title: model.isLoadingWidgets ? 'Loading widgets…' : 'Load widgets',
          detail:
              "Fetch this account's popup widgets so you can tap one to show.",
          tint: AppColors.lilac,
          isLoading: model.isLoadingWidgets,
          enabled: !model.isLoadingWidgets,
          status: model.actionStatus(
            SDKActionID.loadWidgets,
            fallback: model.currentLoadWidgetsStatus,
            tone: model.showWidgetTone,
          ),
          onTap: model.runLoadWidgetsAction,
        ),
        // 2 — Fetched widgets: tap a row to present it.
        for (final widget in model.availableWidgets)
          InkWell(
            onTap: () {
              _dismissKeyboard();
              model.showWidget(widget.id);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              child: Row(
                children: [
                  const Icon(Icons.picture_in_picture_alt_outlined,
                      size: 22, color: AppColors.lilac),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 13,
                            fontFamily: AppFonts.mono,
                            fontFamilyFallback: AppFonts.monoFallback,
                            color: AppColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.type.isEmpty
                              ? 'Widget'
                              : widget.type[0].toUpperCase() +
                                  widget.type.substring(1),
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: AppColors.secondaryLabel,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.chevron_right,
                      size: 20, color: AppColors.secondaryLabel),
                ],
              ),
            ),
          ),
        // 3 — Show by ID: an explicit input with its own Show action.
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _widgetIDController,
                      autocorrect: false,
                      style: const TextStyle(
                          fontSize: 13,
                          fontFamily: AppFonts.mono,
                          fontFamilyFallback: AppFonts.monoFallback),
                      decoration: const InputDecoration(
                        isCollapsed: true,
                        border: InputBorder.none,
                        hintText: 'Enter a widget ID',
                      ),
                      onSubmitted: (_) {
                        _dismissKeyboard();
                        model.runShowWidgetAction();
                      },
                    ),
                  ),
                  const SizedBox(width: 10),
                  FilledButton(
                    onPressed: model.widgetID.trim().isEmpty
                        ? null
                        : () {
                            _dismissKeyboard();
                            model.runShowWidgetAction();
                          },
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.lilac,
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text(
                      'Show',
                      style:
                          TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ActionStatusRow(
                status: model.actionStatus(
                  SDKActionID.showWidget,
                  fallback: model.currentShowWidgetStatus,
                  tone: model.showWidgetTone,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _actionsSection() {
    return GroupedSection(
      header: 'Actions',
      children: [
        DeliveryActionButton(
          title:
              model.isIdentifying ? 'Identifying contact' : 'Identify contact',
          detail: 'Attach the remembered email to the Ortto SDK session.',
          tint: AppColors.lilac,
          isLoading: model.isIdentifying,
          enabled: !model.isIdentifying,
          status: model.actionStatus(
            SDKActionID.identify,
            fallback: model.currentIdentityStatus,
          ),
          onTap: model.runIdentifyAction,
        ),
        DeliveryActionButton(
          title: model.registrationActionTitle,
          detail:
              'Request Firebase Messaging registration and forward the FCM token.',
          tint: AppColors.orange,
          isLoading: model.isRequestingPush,
          enabled: !model.homePushActionDisabled,
          status: model.actionStatus(
            SDKActionID.registerPush,
            fallback: model.currentRegisterStatus,
            tone: model.currentRegisterTone,
          ),
          onTap: model.runRegisterPushAction,
        ),
        DeliveryActionButton(
          title: 'Redispatch SDK token',
          detail: 'Ask the SDK to process the SDK token again.',
          tint: AppColors.green,
          enabled: model.sdkToken != null,
          status: model.actionStatus(
            SDKActionID.redispatch,
            fallback: model.currentRedispatchStatus,
          ),
          onTap: model.runRedispatchAction,
        ),
        DeliveryActionButton(
          title: 'Track link click',
          detail:
              'Call Ortto.instance.trackLinkClick with a tracked push-action deeplink.',
          tint: AppColors.blue,
          isLoading: model.isTrackingLinkClick,
          enabled: !model.isTrackingLinkClick,
          status: model.actionStatus(
            SDKActionID.trackLink,
            fallback: model.currentTrackLinkStatus,
            tone: model.currentTrackLinkTone,
          ),
          onTap: model.runTrackLinkAction,
        ),
        DeliveryActionButton(
          title: 'Refresh permission',
          detail: 'Read the latest notification permission state from the OS.',
          tint: AppColors.lilac,
          status: model.actionStatus(
            SDKActionID.refreshPermission,
            fallback: model.currentPermissionStatus,
          ),
          onTap: model.runRefreshPermissionAction,
        ),
      ],
    );
  }
}
