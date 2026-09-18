import 'dart:ui' as ui;

import 'package:flutter/material.dart';

import '../design.dart';
import '../models.dart';

/// iOS insetGrouped-style section: caption header, white rounded card of rows
/// separated by hairlines, optional caption footer.
class GroupedSection extends StatelessWidget {
  const GroupedSection({
    super.key,
    this.header,
    this.footer,
    required this.children,
  });

  final String? header;
  final String? footer;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final rows = <Widget>[];
    for (var i = 0; i < children.length; i++) {
      rows.add(children[i]);
      if (i < children.length - 1) {
        rows.add(const Divider(
          height: 1,
          thickness: 0.5,
          indent: 16,
          color: AppColors.separator,
        ));
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (header != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 7),
              child: Text(
                header!.toUpperCase(),
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.secondaryLabel,
                  letterSpacing: 0.4,
                ),
              ),
            ),
          ClipRRect(
            borderRadius: BorderRadius.circular(10),
            child: Container(
              color: AppColors.surface,
              child: Column(children: rows),
            ),
          ),
          if (footer != null)
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 7, right: 16),
              child: Text(
                footer!,
                style: const TextStyle(
                  fontSize: 13,
                  color: AppColors.secondaryLabel,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// A LabeledContent-style row: title on the left, value (or custom trailing
/// widget) on the right.
class LabeledRow extends StatelessWidget {
  const LabeledRow(this.label, {super.key, this.value, this.trailing});

  final String label;
  final String? value;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 17, color: AppColors.ink),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: trailing ??
                Text(
                  value ?? '',
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 17,
                    color: AppColors.secondaryLabel,
                  ),
                ),
          ),
        ],
      ),
    );
  }
}

/// Trailing value with a copy button, ported from CopyableValue.
class CopyableValue extends StatelessWidget {
  const CopyableValue({
    super.key,
    required this.display,
    required this.onCopy,
    this.isMonospaced = false,
  });

  final String display;
  final VoidCallback onCopy;
  final bool isMonospaced;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Flexible(
          child: Text(
            display,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.right,
            style: TextStyle(
              fontSize: isMonospaced ? 13 : 17,
              fontFamily: isMonospaced ? AppFonts.mono : null,
              fontFamilyFallback: isMonospaced ? AppFonts.monoFallback : null,
              fontWeight: isMonospaced ? FontWeight.w600 : FontWeight.w400,
              color: AppColors.secondaryLabel,
            ),
          ),
        ),
        const SizedBox(width: 7),
        GestureDetector(
          onTap: onCopy,
          child:
              const Icon(Icons.copy_outlined, size: 18, color: AppColors.lilac),
        ),
      ],
    );
  }
}

/// A row that opens a modal, ported from ModalRowButton.
class ModalRowButton extends StatelessWidget {
  const ModalRowButton({super.key, required this.title, required this.onTap});

  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w500,
                  color: AppColors.ink,
                ),
              ),
            ),
            const Icon(Icons.open_in_new, size: 20, color: AppColors.lilac),
          ],
        ),
      ),
    );
  }
}

/// Inline status line: tone icon + caption text.
class ActionStatusRow extends StatelessWidget {
  const ActionStatusRow({super.key, required this.status});

  final SDKActionStatus status;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(status.tone.icon, size: 12, color: status.tone.tint),
        const SizedBox(width: 5),
        Flexible(
          child: Text(
            status.text,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: status.tone.tint,
            ),
          ),
        ),
      ],
    );
  }
}

/// A tinted SDK action row, ported from DeliveryActionButton.
class DeliveryActionButton extends StatelessWidget {
  const DeliveryActionButton({
    super.key,
    required this.title,
    required this.detail,
    required this.tint,
    this.isLoading = false,
    this.status,
    this.enabled = true,
    required this.onTap,
  });

  final String title;
  final String detail;
  final Color tint;
  final bool isLoading;
  final SDKActionStatus? status;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: tint.withValues(alpha: enabled ? 0.12 : 0.05),
      child: InkWell(
        onTap: enabled ? onTap : null,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: enabled ? tint : AppColors.secondaryLabel,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      detail,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: AppColors.secondaryLabel,
                      ),
                    ),
                    if (status != null) ...[
                      const SizedBox(height: 5),
                      ActionStatusRow(status: status!),
                    ],
                  ],
                ),
              ),
              const SizedBox(width: 12),
              if (isLoading)
                SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation(tint),
                  ),
                )
              else
                Icon(
                  Icons.arrow_circle_up_rounded,
                  size: 24,
                  color: enabled ? tint : AppColors.secondaryLabel,
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Configuration issue rows, ported from ConfigurationIssueRows.
class ConfigurationIssueRows extends StatelessWidget {
  const ConfigurationIssueRows({super.key, required this.issues});

  final List<SDKConfigurationIssue> issues;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var i = 0; i < issues.length; i++) ...[
          if (i > 0)
            const Divider(
              height: 1,
              thickness: 0.5,
              indent: 16,
              color: AppColors.separator,
            ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  issues[i].title,
                  style: TextStyle(
                    fontSize: 17,
                    color: issues[i].severity.tint,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  issues[i].detail,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.secondaryLabel,
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

/// Floating action toast: a frosted-glass card with a tone-tinted icon,
/// modernized from the iOS demo's SDKToastView.
class SDKToastView extends StatelessWidget {
  const SDKToastView({super.key, required this.toast});

  final SDKToast toast;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ui.ImageFilter.blur(sigmaX: 24, sigmaY: 24),
        child: Container(
          constraints: const BoxConstraints(maxWidth: 520),
          padding: const EdgeInsets.fromLTRB(14, 14, 18, 14),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.86),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withValues(alpha: 0.65)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.10),
                blurRadius: 30,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: toast.tone.tint.withValues(alpha: 0.10),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      toast.tone.tint.withValues(alpha: 0.22),
                      toast.tone.tint.withValues(alpha: 0.10),
                    ],
                  ),
                ),
                child: Icon(toast.tone.icon, size: 19, color: toast.tone.tint),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      toast.title,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.ink,
                        letterSpacing: -0.2,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      toast.detail,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                        color: AppColors.ink.withValues(alpha: 0.55),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
