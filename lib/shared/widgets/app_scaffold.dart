import 'package:flutter/material.dart';

import 'bottom_nav_bar.dart';
import 'cinematic_backdrop.dart';

/// The standard CineConnect page shell: cinematic backdrop + safe area
/// + scrollable body + floating bottom nav.
///
/// New dashboards should be built as `AppScaffold(body: ..., navIndex:
/// ..., onNavTap: ...)` instead of re-assembling Scaffold/backdrop/nav
/// by hand, so every screen shares the same chrome.
class AppScaffold extends StatelessWidget {
  final Widget body;
  final int navIndex;
  final ValueChanged<int> onNavTap;

  const AppScaffold({
    super.key,
    required this.body,
    required this.navIndex,
    required this.onNavTap,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackdrop()),
          SafeArea(
            bottom: false,
            child: Column(
              children: [
                Expanded(child: body),
                CineBottomNav(
                  currentIndex: navIndex,
                  onTap: onNavTap,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
