import 'package:flutter/material.dart';

import '../design.dart';
import '../models.dart';
import '../push_model.dart';

/// The Log tab: a terminal-style console of SDK and demo log entries, ported
/// from the iOS demo's MatrixLogConsole.
class LogView extends StatefulWidget {
  const LogView({super.key, required this.model});

  final PushModel model;

  @override
  State<LogView> createState() => _LogViewState();
}

class _LogViewState extends State<LogView> {
  final ScrollController _scrollController = ScrollController();
  int _lastEntryCount = 0;

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final entries = widget.model.logEntries;

    if (entries.length != _lastEntryCount) {
      _lastEntryCount = entries.length;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!_scrollController.hasClients) return;
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
        );
      });
    }

    return Container(
      decoration: const BoxDecoration(
        color: MatrixColors.surface,
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          stops: [0.0, 0.35, 1.0],
          colors: [
            Color(0x1261FF94),
            MatrixColors.surface,
            MatrixColors.surface
          ],
        ),
      ),
      child: entries.isEmpty
          ? const _EmptyConsoleState()
          : ListView.builder(
              controller: _scrollController,
              padding: const EdgeInsets.fromLTRB(14, 10, 14, 100),
              itemCount: entries.length,
              itemBuilder: (context, index) =>
                  _ConsoleLine(entry: entries[index]),
            ),
    );
  }
}

class _ConsoleLine extends StatelessWidget {
  const _ConsoleLine({required this.entry});

  final LogEntry entry;

  static const TextStyle _base = TextStyle(
    fontSize: 12,
    fontFamily: AppFonts.mono,
    fontFamilyFallback: AppFonts.monoFallback,
    fontWeight: FontWeight.w500,
    height: 1.4,
  );

  String get _timestamp {
    final d = entry.date;
    String pad(int v) => v.toString().padLeft(2, '0');
    return '${pad(d.hour)}:${pad(d.minute)}:${pad(d.second)}';
  }

  Color get _sourceColor =>
      entry.source == LogSource.sdk ? MatrixColors.ortto : MatrixColors.primary;

  Color get _levelColor {
    switch (entry.level) {
      case LogLevel.info:
        return MatrixColors.primary;
      case LogLevel.debug:
        return MatrixColors.secondary;
      case LogLevel.warning:
        return MatrixColors.warning;
      case LogLevel.error:
        return MatrixColors.error;
    }
  }

  Color get _lineColor {
    if (entry.level == LogLevel.error ||
        entry.message.toLowerCase().contains('error')) {
      return MatrixColors.error;
    }
    if (entry.level == LogLevel.warning) return MatrixColors.warning;
    if (entry.level == LogLevel.debug) return MatrixColors.dim;
    if (entry.message.toLowerCase().contains('success')) {
      return MatrixColors.primary;
    }
    return MatrixColors.output;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: SelectableText.rich(
        TextSpan(
          style: _base,
          children: [
            TextSpan(
              text: entry.source.label,
              style:
                  TextStyle(color: _sourceColor, fontWeight: FontWeight.w600),
            ),
            const TextSpan(
                text: '@', style: TextStyle(color: MatrixColors.dim)),
            TextSpan(
              text: entry.source.promptHost,
              style: const TextStyle(color: MatrixColors.host),
            ),
            TextSpan(
              text: ' [$_timestamp]',
              style: const TextStyle(color: MatrixColors.dim),
            ),
            const TextSpan(
              text: ' % ',
              style: TextStyle(
                color: MatrixColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (entry.level != LogLevel.info)
              TextSpan(
                text: '${entry.level.label} ',
                style:
                    TextStyle(color: _levelColor, fontWeight: FontWeight.w600),
              ),
            TextSpan(
              text: entry.message,
              style: TextStyle(color: _lineColor),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyConsoleState extends StatelessWidget {
  const _EmptyConsoleState();

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.terminal, size: 28, color: MatrixColors.primary),
          SizedBox(height: 10),
          Text(
            'demo@push-demo % waiting for log events',
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppFonts.mono,
              fontFamilyFallback: AppFonts.monoFallback,
              fontWeight: FontWeight.w700,
              color: MatrixColors.primary,
            ),
          ),
          SizedBox(height: 4),
          Text(
            'ortto@flutter-sdk % idle',
            style: TextStyle(
              fontSize: 12,
              fontFamily: AppFonts.mono,
              fontFamilyFallback: AppFonts.monoFallback,
              fontWeight: FontWeight.w600,
              color: MatrixColors.dim,
            ),
          ),
        ],
      ),
    );
  }
}
