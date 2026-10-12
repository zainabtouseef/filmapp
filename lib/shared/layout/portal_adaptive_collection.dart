import 'package:flutter/material.dart';

import 'portal_reference_design.dart';

/// Route-aware collection layout shared by every CineConnect portal.
///
/// Existing screens keep supplying their live child widgets. This class only
/// changes composition: ledgers become full-width rows, workflow boards and
/// recommendation sets become horizontal lanes, galleries retain a visual
/// grid, and analytical/editorial pages use restrained responsive columns.
class PortalAdaptiveCollection extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;
  final int maxColumns;

  const PortalAdaptiveCollection({
    super.key,
    required this.children,
    this.minWidth = 240,
    this.gap = 12,
    this.maxColumns = 4,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    final route = ModalRoute.of(context)?.settings.name;
    if (!PortalReferenceDesign.usesReference(route)) {
      return _ResponsiveWrap(
        minWidth: minWidth,
        gap: gap,
        maxColumns: maxColumns,
        children: children,
      );
    }

    final layout = PortalReferenceDesign.layoutForRoute(route);
    if (layout == PortalBodyLayout.list ||
        layout == PortalBodyLayout.timeline) {
      return Column(
        children: [
          for (var index = 0; index < children.length; index++) ...[
            SizedBox(width: double.infinity, child: children[index]),
            if (index != children.length - 1) SizedBox(height: gap),
          ],
        ],
      );
    }

    if (layout == PortalBodyLayout.horizontalRail ||
        layout == PortalBodyLayout.kanban) {
      final itemWidth = layout == PortalBodyLayout.kanban
          ? minWidth.clamp(260.0, 340.0)
          : minWidth.clamp(220.0, 320.0);
      return Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (var index = 0; index < children.length; index++) ...[
                  SizedBox(width: itemWidth, child: children[index]),
                  if (index != children.length - 1) SizedBox(width: gap),
                ],
              ],
            ),
          ),
        ),
      );
    }

    final columns = switch (layout) {
      PortalBodyLayout.gallery => maxColumns,
      PortalBodyLayout.analytics => 3,
      PortalBodyLayout.calendar || PortalBodyLayout.splitView => 2,
      PortalBodyLayout.editorial => 2,
      _ => maxColumns,
    };
    return _ResponsiveWrap(
      minWidth: layout == PortalBodyLayout.gallery
          ? minWidth.clamp(180.0, 260.0)
          : minWidth,
      gap: gap,
      maxColumns: columns,
      children: children,
    );
  }
}

/// Shared master/detail composition for operational workspaces.
///
/// It keeps a clear primary working area and a compact secondary rail on
/// desktop, then stacks both panels without horizontal overflow on phones.
class PortalSplitView extends StatelessWidget {
  final Widget primary;
  final Widget secondary;
  final double breakpoint;
  final double gap;
  final int primaryFlex;
  final int secondaryFlex;

  const PortalSplitView({
    super.key,
    required this.primary,
    required this.secondary,
    this.breakpoint = 820,
    this.gap = 12,
    this.primaryFlex = 6,
    this.secondaryFlex = 4,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              primary,
              SizedBox(height: gap),
              secondary,
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: primaryFlex, child: primary),
            SizedBox(width: gap),
            Expanded(flex: secondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

class _ResponsiveWrap extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;
  final int maxColumns;

  const _ResponsiveWrap({
    required this.children,
    required this.minWidth,
    required this.gap,
    required this.maxColumns,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final rawWidth = constraints.maxWidth;
        final count = rawWidth.isFinite
            ? (rawWidth / minWidth).floor().clamp(1, maxColumns).toInt()
            : 1;
        final width = rawWidth.isFinite
            ? (rawWidth - (count - 1) * gap) / count
            : minWidth;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final child in children) SizedBox(width: width, child: child),
          ],
        );
      },
    );
  }
}
