import 'package:flutter/material.dart';

import '../design.dart';
import '../models.dart';
import '../push_model.dart';
import 'controls.dart';
import 'technical_details_view.dart';

/// The Home tab: contact, configuration issues, and device registration.
class HomeView extends StatelessWidget {
  const HomeView({super.key, required this.model});

  final PushModel model;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.only(top: 4, bottom: 90),
      children: [
        _contactSection(context),
        if (model.blockingConfigurationIssues.isNotEmpty)
          _configurationSection(),
        _deviceSection(),
      ],
    );
  }

  Widget _contactSection(BuildContext context) {
    return GroupedSection(
      header: 'Contact',
      children: [
        LabeledRow(
          'Email',
          trailing: CopyableValue(
            display: model.signedInEmail,
            onCopy: () => model.copyToClipboard(model.signedInEmail, 'email'),
          ),
        ),
        LabeledRow('Remembered', value: model.rememberedContactValue),
        LabeledRow(
          'SDK session',
          trailing: model.sessionId != null
              ? CopyableValue(
                  display: model.short(model.sessionId),
                  isMonospaced: true,
                  onCopy: () =>
                      model.copyToClipboard(model.sessionId, 'session ID'),
                )
              : null,
          value: model.sessionId == null
              ? (model.identityEstablished ? 'Active (native)' : 'Anonymous')
              : null,
        ),
        ModalRowButton(
          title: 'Technical Details',
          onTap: () => showTechnicalDetails(context, model),
        ),
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

  Widget _deviceSection() {
    final token = model.currentPushToken;
    return GroupedSection(
      header: 'Device',
      footer:
          'Firebase Messaging provides the registration token after permission is granted.',
      children: [
        const LabeledRow('Provider', value: 'Firebase Cloud Messaging'),
        LabeledRow(
          'Status',
          value: token == null ? 'Not registered' : 'Registered',
        ),
        LabeledRow('Permission', value: model.permissionStatus),
        LabeledRow(
          'SDK token',
          value: model.sdkToken == null ? 'Not forwarded' : 'Forwarded',
        ),
        if (token != null)
          LabeledRow(
            'Token',
            trailing: CopyableValue(
              display: model.short(token),
              isMonospaced: true,
              onCopy: model.copyCurrentPushToken,
            ),
          )
        else ...[
          LabeledRow('Token', value: model.pushTokenPlaceholder),
          // Ortto SDK: push registration — Firebase owns Apple's permission
          // prompt, then the token is forwarded to
          // Ortto.instance.registerDeviceToken.
          InkWell(
            onTap: model.homePushActionDisabled
                ? null
                : model.runRegisterPushAction,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      model.registrationActionTitle,
                      style: TextStyle(
                        fontSize: 17,
                        color: model.homePushActionDisabled
                            ? AppColors.secondaryLabel
                            : AppColors.lilac,
                      ),
                    ),
                  ),
                  if (model.isRequestingPush)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }
}
