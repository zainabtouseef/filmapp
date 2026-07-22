import 'package:flutter/material.dart';

/// Reusable elevation / glow shadow presets.
///
/// Prefer these (or `context.appColors.shadow` / `.goldGlow` combined
/// with them) over inventing new BoxShadow lists per widget.
class AppShadows {
  AppShadows._();

  /// Soft ambient separation for feature cards.
  static const card = [
    BoxShadow(
      color: Color(0x18131A20),
      blurRadius: 18,
      spreadRadius: -8,
      offset: Offset(0, 8),
    ),
  ];

  /// Lighter elevation for buttons, chips, and small controls.
  static const control = [
    BoxShadow(
      color: Color(0x14131A20),
      blurRadius: 12,
      spreadRadius: -6,
      offset: Offset(0, 5),
    ),
  ];
}
