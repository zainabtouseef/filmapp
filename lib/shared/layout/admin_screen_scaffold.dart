import 'package:flutter/material.dart';

import '../../core/theme/app_breakpoints.dart';
import '../../core/theme/app_spacing.dart';
import '../widgets/cinematic_backdrop.dart';
import 'admin_section_header.dart';

typedef AdminTopBarBuilder = Widget Function(
  BuildContext context,
  bool wide,
  VoidCallback onMenuTap,
);

typedef AdminSideNavBuilder = Widget Function(
  BuildContext context,
  String currentRoute,
  ValueChanged<String> onRouteTap,
);

typedef AdminBottomNavBuilder = Widget Function(
  BuildContext context,
  String currentRoute,
  bool menuOpen,
  ValueChanged<String> onRouteTap,
  VoidCallback onMoreTap,
);

typedef AdminFloatingMenuBuilder = Widget Function(
  BuildContext context,
  bool open,
  String currentRoute,
  VoidCallback onClose,
  ValueChanged<String> onRouteTap,
);

/// [bottomInset] is the distance already reserved below the content by the
/// bottom nav (mobile) or page padding (desktop) — pass it straight to a
/// `Positioned(bottom: ...)` so a persistent floating control never sits
/// under the nav bar.
typedef AdminFloatingActionBuilder = Widget Function(
  BuildContext context,
  bool wide,
  double bottomInset,
);

class AdminScreenScaffold extends StatefulWidget {
  final String title;
  final String currentRoute;
  final Widget child;
  final AdminTopBarBuilder topBarBuilder;
  final AdminSideNavBuilder? sideNavBuilder;
  final AdminBottomNavBuilder? bottomNavBuilder;
  final AdminFloatingMenuBuilder? floatingMenuBuilder;
  final AdminFloatingActionBuilder? floatingActionBuilder;
  final void Function(BuildContext context, String route) onRouteSelected;

  /// Set false to suppress the default centered [AdminScreenHeading] —
  /// used by screens (like the DP dashboard) that render their own
  /// compact command header as part of the content instead.
  final bool showHeading;

  const AdminScreenScaffold({
    super.key,
    required this.title,
    required this.currentRoute,
    required this.child,
    required this.topBarBuilder,
    required this.onRouteSelected,
    this.sideNavBuilder,
    this.bottomNavBuilder,
    this.floatingMenuBuilder,
    this.floatingActionBuilder,
    this.showHeading = true,
  });

  @override
  State<AdminScreenScaffold> createState() => _AdminScreenScaffoldState();
}

class _AdminScreenScaffoldState extends State<AdminScreenScaffold> {
  bool _menuOpen = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackdrop()),
          SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Aligned with AppBreakpoints.laptop so the desktop side
                // nav and multi-pane screen layouts (DPTwoColumn/_TwoPane/
                // _ThreePane, which key off the same constant) switch to
                // their desktop arrangement together — otherwise the side
                // nav can appear while content is still mobile-stacked.
                final wide = constraints.maxWidth >= AppBreakpoints.laptop;
                // PremiumBottomNavBar grows from 112 to 156 tall at its own
                // internal 700px breakpoint — mirror that here so scroll
                // content never ends up underneath a taller-than-expected
                // nav bar.
                final navBarWide = !wide && constraints.maxWidth >= 700;
                final reservedNavHeight = navBarWide ? 156.0 : 112.0;
                final headingTopGap =
                    widget.currentRoute.endsWith('/dashboard') ? 32.0 : 18.0;
                final contentTopGap =
                    widget.currentRoute.endsWith('/dashboard') ? 30.0 : 20.0;

                return Stack(
                  children: [
                    Row(
                      children: [
                        if (wide && widget.sideNavBuilder != null)
                          widget.sideNavBuilder!(
                            context,
                            widget.currentRoute,
                            _go,
                          ),
                        Expanded(
                          child: Column(
                            children: [
                              widget.topBarBuilder(
                                context,
                                wide,
                                _openMenu,
                              ),
                              if (widget.showHeading)
                                Padding(
                                  padding: EdgeInsets.fromLTRB(
                                    AppSpacing.pageHorizontal,
                                    headingTopGap,
                                    AppSpacing.pageHorizontal,
                                    0,
                                  ),
                                  child:
                                      AdminScreenHeading(title: widget.title),
                                ),
                              Expanded(
                                child: SingleChildScrollView(
                                  padding: EdgeInsets.fromLTRB(
                                    AppSpacing.pageHorizontal,
                                    contentTopGap,
                                    AppSpacing.pageHorizontal,
                                    wide
                                        ? 28
                                        : reservedNavHeight +
                                            MediaQuery.paddingOf(context)
                                                .bottom +
                                            32,
                                  ),
                                  child: ConstrainedBox(
                                    constraints: BoxConstraints(
                                        maxWidth:
                                            AppBreakpoints.maxContentWidth),
                                    child: widget.child,
                                  ),
                                ),
                              ),
                              if (!wide && widget.bottomNavBuilder != null)
                                widget.bottomNavBuilder!(
                                  context,
                                  widget.currentRoute,
                                  _menuOpen,
                                  _go,
                                  _openMenu,
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (!wide && widget.floatingMenuBuilder != null)
                      widget.floatingMenuBuilder!(
                        context,
                        _menuOpen,
                        widget.currentRoute,
                        _closeMenu,
                        _go,
                      ),
                    if (widget.floatingActionBuilder != null)
                      widget.floatingActionBuilder!(
                        context,
                        wide,
                        wide
                            ? 24.0
                            : reservedNavHeight +
                                MediaQuery.paddingOf(context).bottom +
                                16,
                      ),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openMenu() {
    setState(() => _menuOpen = true);
  }

  void _closeMenu() {
    setState(() => _menuOpen = false);
  }

  void _go(String route) {
    if (_menuOpen) _closeMenu();
    if (route == widget.currentRoute) return;
    widget.onRouteSelected(context, route);
  }
}
