import 'package:flutter/material.dart';

/// Typography shared by the demo without bundling organization-specific
/// font binaries in the public SDK repository.
class AppFonts {
  AppFonts._();

  static const String? sans = null;
  static const String? display = null;
  static const String mono = 'Menlo';
  static const List<String> monoFallback = ['Courier', 'monospace'];
}

/// Shared visual styling for the Ortto Flutter SDK demo app. Ports the iOS
/// demo's DesignSystem.swift color palette.
class AppColors {
  AppColors._();

  static const Color inkLight = Color(0xFF0D1217);
  static const Color inkDark = Color(0xFFF0F5FA);
  static const Color blue = Color(0xFF00C4CC);
  static const Color green = Color(0xFF00C29E);
  static const Color coral = Color(0xFFFF597D);
  static const Color orange = Color(0xFFFF9900);
  static const Color yellow = Color(0xFFFFD138);
  static const Color lilac = Color(0xFF8C3DFF);
  static const Color surface = Colors.white;
  static const Color groupedBackground = Color(0xFFF2F2F7);
  static const Color secondaryLabel = Color(0x993C3C43);
  static const Color separator = Color(0x4A3C3C43);

  /// The app runs the signed-in screens in light mode (matching the iOS demo,
  /// which forces `.light` outside the Log tab), so ink is the light value.
  static const Color ink = inkLight;
}

/// Terminal palette for the Log tab, ported from MatrixColor.
class MatrixColors {
  MatrixColors._();

  static const Color primary = Color(0xFF61FF94);
  static const Color ortto = Color(0xFF8FE0FF);
  static const Color output = Color(0xFFE0F0E6);
  static const Color host = Color(0xFFBADBC4);
  static const Color dim = Color(0xFF789985);
  static const Color surface = Color(0xFF030605);
  static const Color secondary = dim;
  static const Color warning = Color(0xFFFFC24D);
  static const Color error = Color(0xFFFF7A6B);
}
