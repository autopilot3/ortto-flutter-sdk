import 'package:flutter/material.dart';

import 'design.dart';

/// Screen identifiers, matching the iOS demo's AppTab screen names.
enum AppTab {
  home('sdk-home'),
  delivery('push-delivery'),
  diagnostics('push-diagnostics');

  const AppTab(this.screenName);

  final String screenName;
}

enum SDKActionID {
  identify,
  registerPush,
  redispatch,
  trackLink,
  refreshPermission,
  showWidget,
  loadWidgets,
}

enum SDKActionTone {
  ready,
  working,
  success,
  warning,
  blocked;

  IconData get icon {
    switch (this) {
      case SDKActionTone.ready:
        return Icons.circle_outlined;
      case SDKActionTone.working:
        return Icons.schedule;
      case SDKActionTone.success:
        return Icons.check_circle;
      case SDKActionTone.warning:
        return Icons.warning_rounded;
      case SDKActionTone.blocked:
        return Icons.block;
    }
  }

  Color get tint {
    switch (this) {
      case SDKActionTone.ready:
        return AppColors.ink.withValues(alpha: 0.48);
      case SDKActionTone.working:
        return AppColors.lilac;
      case SDKActionTone.success:
        return AppColors.green;
      case SDKActionTone.warning:
        return AppColors.orange;
      case SDKActionTone.blocked:
        return AppColors.coral;
    }
  }
}

class SDKActionStatus {
  const SDKActionStatus({required this.text, required this.tone});

  final String text;
  final SDKActionTone tone;
}

class SDKToast {
  SDKToast({required this.title, required this.detail, required this.tone});

  final String title;
  final String detail;
  final SDKActionTone tone;
}

enum SDKConfigurationSeverity {
  warning,
  critical;

  Color get tint {
    switch (this) {
      case SDKConfigurationSeverity.warning:
        return AppColors.orange;
      case SDKConfigurationSeverity.critical:
        return AppColors.coral;
    }
  }
}

class SDKConfigurationIssue {
  const SDKConfigurationIssue({
    required this.title,
    required this.detail,
    required this.severity,
  });

  final String title;
  final String detail;
  final SDKConfigurationSeverity severity;
}

/// A widget from the `/-/widgets/get` response, reduced to what the picker
/// needs. `showWidget` only renders `popup` types, so that is all we keep.
class DemoWidget {
  const DemoWidget({required this.id, required this.type});

  final String id;
  final String type;
}

/// A pending notification default-action deeplink awaiting in-app
/// confirmation.
class DeepLinkPrompt {
  const DeepLinkPrompt({required this.link});

  final String link;
}

// Source is assigned at ingestion time. Ortto entries echo SDK call results;
// demo entries come from this app's own flow.
enum LogSource {
  sdk('ortto', 'flutter-sdk'),
  demo('demo', 'push-demo');

  const LogSource(this.label, this.promptHost);

  final String label;
  final String promptHost;
}

enum LogLevel {
  info('info'),
  warning('warn'),
  error('err'),
  debug('debug');

  const LogLevel(this.label);

  final String label;
}

class LogEntry {
  LogEntry({
    required this.source,
    required this.level,
    required this.message,
    DateTime? date,
  }) : date = date ?? DateTime.now();

  final DateTime date;
  final LogSource source;
  final LogLevel level;
  final String message;
}
