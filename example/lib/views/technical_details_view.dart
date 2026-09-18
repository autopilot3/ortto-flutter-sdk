import 'package:flutter/material.dart';

import '../app_config.dart';
import '../design.dart';
import '../push_model.dart';
import 'controls.dart';

/// The Technical Details modal, ported from TechnicalDetailsView.
Future<void> showTechnicalDetails(BuildContext context, PushModel model) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: AppColors.groupedBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
    ),
    builder: (context) => DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.92,
      maxChildSize: 0.92,
      builder: (context, scrollController) => ListenableBuilder(
        listenable: model,
        builder: (context, _) => Column(
          children: [
            _sheetHeader(context),
            Expanded(
              child: ListView(
                controller: scrollController,
                padding: const EdgeInsets.only(bottom: 24),
                children: [
                  _sdkSection(model),
                  _sessionSection(model),
                  _notificationSection(model),
                  if (model.configurationIssues.isNotEmpty)
                    _checksSection(model),
                ],
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

Widget _sheetHeader(BuildContext context) {
  return Padding(
    padding: const EdgeInsets.fromLTRB(16, 14, 8, 4),
    child: Row(
      children: [
        const Expanded(
          child: Padding(
            padding: EdgeInsets.only(left: 44),
            child: Text(
              'Technical Details',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w600,
                color: AppColors.ink,
              ),
            ),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text(
            'Done',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: AppColors.lilac,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _sdkSection(PushModel model) {
  return GroupedSection(
    header: 'SDK',
    children: [
      const LabeledRow('Target', value: 'FCM (Flutter)'),
      LabeledRow(
        'Endpoint',
        trailing: CopyableValue(
          display: AppConfig.orttoAppEndpoint,
          onCopy: () =>
              model.copyToClipboard(AppConfig.orttoAppEndpoint, 'endpoint'),
        ),
      ),
      LabeledRow(
        'App key',
        value: AppConfig.hasConfiguredAppKey ? 'Configured' : 'Missing',
      ),
      LabeledRow('Key source', value: AppConfig.orttoAppKeySource),
      const LabeledRow('Push package', value: 'ortto_flutter_sdk'),
      LabeledRow(
        'Capture config',
        value: AppConfig.canInitializeCapture ? 'Configured' : 'Missing',
      ),
    ],
  );
}

Widget _sessionSection(PushModel model) {
  return GroupedSection(
    header: 'Session',
    children: [
      LabeledRow(
        'Session',
        trailing: model.sessionId != null
            ? CopyableValue(
                display: model.short(model.sessionId),
                isMonospaced: true,
                onCopy: () =>
                    model.copyToClipboard(model.sessionId, 'session ID'),
              )
            : null,
        value: model.sessionId == null
            ? (model.identityEstablished ? 'Active (native)' : 'None')
            : null,
      ),
      const LabeledRow('SDK token type', value: 'FCM'),
      LabeledRow(
        'SDK token',
        trailing: model.sdkToken != null
            ? CopyableValue(
                display: model.short(model.sdkToken),
                isMonospaced: true,
                onCopy: () =>
                    model.copyToClipboard(model.sdkToken, 'SDK token'),
              )
            : null,
        value: model.sdkToken == null ? 'None' : null,
      ),
    ],
  );
}

Widget _notificationSection(PushModel model) {
  return GroupedSection(
    header: 'Notifications',
    children: [
      LabeledRow('Permission', value: model.permissionStatus),
      LabeledRow(
        'Capture JS URL',
        value: AppConfig.hasConfiguredCaptureJsUrl ? 'Configured' : 'Missing',
      ),
      const LabeledRow('Message source', value: 'firebase_messaging'),
    ],
  );
}

Widget _checksSection(PushModel model) {
  return GroupedSection(
    header: 'Checks',
    children: [
      ConfigurationIssueRows(issues: model.configurationIssues),
    ],
  );
}
