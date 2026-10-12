import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import 'portal_reference_design.dart';

/// Chooses one of the nine real CineConnect information compositions for the
/// current operational route. Screens keep their live widgets and callbacks;
/// this layer changes their information architecture without copying data or
/// disconnecting a controller from the backend.
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
      return PortalGalleryLayout(
        minWidth: minWidth,
        gap: gap,
        maxColumns: maxColumns,
        children: children,
      );
    }

    return switch (PortalReferenceDesign.layoutForRoute(route)) {
      PortalBodyLayout.analytics => PortalAnalyticsLayout(
          minWidth: minWidth,
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.timeline => PortalTimelineLayout(
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.calendar => PortalCalendarLayout(
          minWidth: minWidth,
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.editorial => PortalEditorialLayout(
          minWidth: minWidth,
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.list => PortalListLayout(
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.kanban => PortalKanbanLayout(
          minWidth: minWidth,
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.gallery => PortalGalleryLayout(
          minWidth: minWidth.clamp(180.0, 260.0),
          gap: gap,
          maxColumns: maxColumns,
          children: children,
        ),
      PortalBodyLayout.splitView => PortalSplitCollectionLayout(
          minWidth: minWidth,
          gap: gap,
          children: children,
        ),
      PortalBodyLayout.horizontalRail => PortalSpotlightRailLayout(
          minWidth: minWidth,
          gap: gap,
          children: children,
        ),
    };
  }
}

/// 1. Analytics & graphs: a dominant analytical panel with a compact insight
/// rail, followed by a responsive supporting grid.
class PortalAnalyticsLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalAnalyticsLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) => _PortalMosaic(
        minWidth: minWidth,
        gap: gap,
        breakpoint: 860,
        primaryFlex: 7,
        secondaryFlex: 4,
        restColumns: 3,
        children: children,
      );
}

/// 2. Timelines & milestones: full-width events connected by a continuous
/// status rail. Existing live status cards become events rather than tiles.
class PortalTimelineLayout extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const PortalTimelineLayout({
    super.key,
    required this.children,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Stack(
      children: [
        Positioned(
          left: 8,
          top: 14,
          bottom: 14,
          child: Container(width: 1, color: colors.border),
        ),
        Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 18),
                    child: Container(
                      width: 17,
                      height: 17,
                      decoration: BoxDecoration(
                        color: colors.elevatedSurface,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _layoutAccent(colors, index),
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: children[index]),
                ],
              ),
              if (index != children.length - 1) SizedBox(height: gap),
            ],
          ],
        ),
      ],
    );
  }
}

/// 3. Calendars & scheduling: a broad calendar workspace beside its agenda
/// rail on desktop and a deliberate calendar-first stack on phones.
class PortalCalendarLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalCalendarLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) => _PortalMosaic(
        minWidth: minWidth,
        gap: gap,
        breakpoint: 900,
        primaryFlex: 8,
        secondaryFlex: 3,
        restColumns: 2,
        children: children,
      );
}

/// 4. Editorial open layouts: the lead story gets visual priority and the
/// remaining controls form a restrained supporting column.
class PortalEditorialLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalEditorialLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) => _PortalMosaic(
        minWidth: minWidth,
        gap: gap,
        breakpoint: 820,
        primaryFlex: 5,
        secondaryFlex: 3,
        restColumns: 2,
        children: children,
      );
}

/// 5. Lists & expandable rows: one readable ledger with quiet separators.
class PortalListLayout extends StatelessWidget {
  final List<Widget> children;
  final double gap;

  const PortalListLayout({
    super.key,
    required this.children,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final border = context.appColors.borderMuted;
    return Column(
      children: [
        for (var index = 0; index < children.length; index++) ...[
          SizedBox(width: double.infinity, child: children[index]),
          if (index != children.length - 1)
            Padding(
              padding: EdgeInsets.symmetric(vertical: gap * .45),
              child: Divider(height: 1, color: border),
            ),
        ],
      ],
    );
  }
}

/// 6. Kanban & workflow boards: horizontally scrollable lanes with distinct
/// status color rails and phone-safe widths.
class PortalKanbanLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalKanbanLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return _HorizontalCollection(
      gap: gap,
      itemWidth: minWidth.clamp(268.0, 336.0),
      children: [
        for (var index = 0; index < children.length; index++)
          DecoratedBox(
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(
                  color: _layoutAccent(colors, index),
                  width: 3,
                ),
              ),
            ),
            child: Padding(
              padding: const EdgeInsets.only(top: 7),
              child: children[index],
            ),
          ),
      ],
    );
  }
}

/// 7. Visual galleries & media layouts.
class PortalGalleryLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;
  final int maxColumns;

  const PortalGalleryLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
    required this.maxColumns,
  });

  @override
  Widget build(BuildContext context) => _ResponsiveWrap(
        minWidth: minWidth,
        gap: gap,
        maxColumns: maxColumns,
        children: children,
      );
}

/// 8. Split-view workspaces: the first item becomes the navigator/master and
/// the next item becomes the active work surface.
class PortalSplitCollectionLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalSplitCollectionLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) {
    if (children.length < 2) {
      return PortalListLayout(gap: gap, children: children);
    }
    return Column(
      children: [
        PortalSplitView(
          primary: children.first,
          secondary: children[1],
          breakpoint: 860,
          gap: gap,
          primaryFlex: 4,
          secondaryFlex: 6,
        ),
        if (children.length > 2) ...[
          SizedBox(height: gap),
          _ResponsiveWrap(
            minWidth: minWidth,
            gap: gap,
            maxColumns: 2,
            children: children.skip(2).toList(),
          ),
        ],
      ],
    );
  }
}

/// 9. Horizontal scrolling & spotlight sections.
class PortalSpotlightRailLayout extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;

  const PortalSpotlightRailLayout({
    super.key,
    required this.children,
    required this.minWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) => _HorizontalCollection(
        gap: gap,
        itemWidth: minWidth.clamp(220.0, 310.0),
        children: children,
      );
}

/// Shared master/detail composition for operational workspaces.
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
    final route = ModalRoute.of(context)?.settings.name;
    final layout = PortalReferenceDesign.layoutForRoute(route);
    final resolvedPrimaryFlex = switch (layout) {
      PortalBodyLayout.calendar => 8,
      PortalBodyLayout.analytics => 7,
      PortalBodyLayout.splitView => 6,
      _ => primaryFlex,
    };
    final resolvedSecondaryFlex = switch (layout) {
      PortalBodyLayout.calendar => 3,
      PortalBodyLayout.analytics => 4,
      PortalBodyLayout.splitView => 4,
      _ => secondaryFlex,
    };
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
            Expanded(flex: resolvedPrimaryFlex, child: primary),
            SizedBox(width: gap),
            Expanded(flex: resolvedSecondaryFlex, child: secondary),
          ],
        );
      },
    );
  }
}

class _PortalMosaic extends StatelessWidget {
  final List<Widget> children;
  final double minWidth;
  final double gap;
  final double breakpoint;
  final int primaryFlex;
  final int secondaryFlex;
  final int restColumns;

  const _PortalMosaic({
    required this.children,
    required this.minWidth,
    required this.gap,
    required this.breakpoint,
    required this.primaryFlex,
    required this.secondaryFlex,
    required this.restColumns,
  });

  @override
  Widget build(BuildContext context) {
    if (children.length < 2) {
      return SizedBox(width: double.infinity, child: children.first);
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth < breakpoint) {
          return _ResponsiveWrap(
            minWidth: minWidth,
            gap: gap,
            maxColumns: constraints.maxWidth >= 620 ? 2 : 1,
            children: children,
          );
        }
        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: primaryFlex, child: children[0]),
                SizedBox(width: gap),
                Expanded(flex: secondaryFlex, child: children[1]),
              ],
            ),
            if (children.length > 2) ...[
              SizedBox(height: gap),
              _ResponsiveWrap(
                minWidth: minWidth,
                gap: gap,
                maxColumns: restColumns,
                children: children.skip(2).toList(),
              ),
            ],
          ],
        );
      },
    );
  }
}

class _HorizontalCollection extends StatelessWidget {
  final List<Widget> children;
  final double itemWidth;
  final double gap;

  const _HorizontalCollection({
    required this.children,
    required this.itemWidth,
    required this.gap,
  });

  @override
  Widget build(BuildContext context) => Scrollbar(
        thumbVisibility: false,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 5),
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

Color _layoutAccent(CineThemeColors colors, int index) {
  final palette = <Color>[
    colors.goldMid,
    colors.infoBlue,
    colors.success,
    colors.infoPurple,
    colors.holographicTeal,
    colors.warning,
  ];
  return palette[index % palette.length];
}
