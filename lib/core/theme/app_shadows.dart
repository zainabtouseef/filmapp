import 'package:flutter/material.dart';

/// Reusable elevation / glow shadow presets.
///
/// Prefer these (or `context.appColors.shadow` / `.goldGlow` combined
/// with them) over inventing new BoxShadow lists per widget.
class AppShadows {
  AppShadows._();

  /// Deep elevation + gold glow used behind the Featured Talent card.
  static const card = [
    BoxShadow(
      color: Color(0x33C88A1E),
      blurRadius: 30,
      spreadRadius: -8,
      offset: Offset(0, 12),
    ),
    BoxShadow(
      color: Color(0x99000000),
      blurRadius: 24,
      spreadRadius: -12,
      offset: Offset(0, 18),
    ),
  ];

  /// Lighter elevation for buttons, chips, and small controls.
  static const control = [
    BoxShadow(
      color: Color(0x22C88A1E),
      blurRadius: 18,
      spreadRadius: -8,
      offset: Offset(0, 8),
    ),
  ];
}
