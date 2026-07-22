import 'package:flutter/material.dart';

import '../../theme/app_breakpoints.dart';
import 'brand_panel.dart';

/// Wraps an auth-flow screen (onboarding, role selection, sign in, sign
/// up) with the persistent [BrandPanel] — half the screen on wide/web
/// layouts, the top portion on narrow/mobile layouts — so the brand
/// moment the splash animation ends on keeps a visible presence while
/// the user moves through account setup.
class AuthSplitScaffold extends StatelessWidget {
  final Widget content;

  const AuthSplitScaffold({super.key, required this.content});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    final wide = size.width >= AppBreakpoints.tablet;

    if (wide) {
      return Scaffold(
        body: Row(
          children: [
            const Expanded(flex: 5, child: BrandPanel()),
            Expanded(flex: 6, child: content),
          ],
        ),
      );
    }

    return Scaffold(
      body: Column(
        children: [
          SizedBox(height: size.height * 0.32, child: const BrandPanel()),
          Expanded(child: content),
        ],
      ),
    );
  }
}
