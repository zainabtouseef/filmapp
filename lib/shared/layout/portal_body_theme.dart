import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'portal_body_canvas.dart';
import 'portal_reference_design.dart';

/// Route-scoped body styling for CineConnect operational screens.
///
/// Dashboard and marketplace routes are deliberately excluded by
/// [PortalReferenceDesign]. Every other portal screen receives the same
/// compact control language so custom screen content still feels like part of
/// one product even when it does not use the shared card primitives directly.
class PortalBodyTheme extends StatelessWidget {
  final String? route;
  final Widget child;

  const PortalBodyTheme({
    super.key,
    required this.route,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    if (!PortalReferenceDesign.usesReference(route)) return child;

    final base = Theme.of(context);
    final colors = context.appColors;
    final layout = PortalReferenceDesign.layoutForRoute(route);
    final compactRows = layout == PortalBodyLayout.list ||
        layout == PortalBodyLayout.timeline ||
        layout == PortalBodyLayout.splitView;
    final controlRadius = switch (layout) {
      PortalBodyLayout.list || PortalBodyLayout.timeline => 12.0,
      PortalBodyLayout.splitView || PortalBodyLayout.kanban => 14.0,
      _ => 16.0,
    };
    final surfaceRadius = switch (layout) {
      PortalBodyLayout.editorial || PortalBodyLayout.analytics => 16.0,
      PortalBodyLayout.list || PortalBodyLayout.timeline => 12.0,
      PortalBodyLayout.kanban || PortalBodyLayout.splitView => 14.0,
      PortalBodyLayout.gallery || PortalBodyLayout.horizontalRail => 20.0,
      PortalBodyLayout.calendar => 18.0,
    };
    final controlShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(controlRadius),
    );
    final inputShape = OutlineInputBorder(
      borderRadius: BorderRadius.circular(controlRadius + 1),
      borderSide: BorderSide(color: colors.border),
    );

    return Theme(
      data: base.copyWith(
        visualDensity: VisualDensity(
          horizontal: -1,
          vertical: compactRows ? -2 : -1,
        ),
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        cardTheme: CardThemeData(
          margin: EdgeInsets.zero,
          color: colors.elevatedSurface,
          elevation: 0,
          shadowColor: colors.shadow.withValues(alpha: .16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(surfaceRadius),
            side: BorderSide(color: colors.borderMuted),
          ),
        ),
        dividerTheme: DividerThemeData(
          color: colors.borderMuted,
          thickness: 1,
          space: compactRows ? 14 : 18,
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Color.lerp(
            colors.elevatedSurface,
            colors.goldLight,
            colors.isLight ? .025 : .045,
          ),
          isDense: true,
          contentPadding: EdgeInsets.symmetric(
            horizontal: 14,
            vertical: compactRows ? 10 : 12,
          ),
          labelStyle: AppTextStyles.caption.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          hintStyle: AppTextStyles.bodyMuted.copyWith(
            color: colors.textTertiary,
          ),
          prefixIconColor: colors.goldDark,
          suffixIconColor: colors.iconMuted,
          border: inputShape,
          enabledBorder: inputShape,
          focusedBorder: inputShape.copyWith(
            borderSide: BorderSide(color: colors.goldMid, width: 1.5),
          ),
          errorBorder: inputShape.copyWith(
            borderSide: BorderSide(color: colors.danger),
          ),
        ),
        filledButtonTheme: FilledButtonThemeData(
          style: FilledButton.styleFrom(
            minimumSize: const Size(42, 42),
            padding: const EdgeInsets.symmetric(horizontal: 17, vertical: 11),
            shape: controlShape,
            textStyle: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        outlinedButtonTheme: OutlinedButtonThemeData(
          style: OutlinedButton.styleFrom(
            minimumSize: const Size(42, 42),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            side: BorderSide(color: colors.border),
            shape: controlShape,
            textStyle: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            minimumSize: const Size(38, 38),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            foregroundColor: colors.goldDark,
            shape: controlShape,
            textStyle: AppTextStyles.label.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        iconButtonTheme: IconButtonThemeData(
          style: IconButton.styleFrom(
            minimumSize: const Size.square(40),
            padding: const EdgeInsets.all(9),
            foregroundColor: colors.textPrimary,
            backgroundColor: colors.elevatedSurface.withValues(alpha: .76),
            side: BorderSide(color: colors.border),
            shape: const CircleBorder(),
          ),
        ),
        listTileTheme: ListTileThemeData(
          dense: true,
          minVerticalPadding: compactRows ? 5 : 8,
          contentPadding: EdgeInsets.symmetric(
            horizontal: compactRows ? 10 : 14,
            vertical: compactRows ? 3 : 5,
          ),
          iconColor: colors.goldDark,
          textColor: colors.textPrimary,
          titleTextStyle: AppTextStyles.cardTitle.copyWith(
            color: colors.textPrimary,
            fontSize: 14,
          ),
          subtitleTextStyle: AppTextStyles.smallMeta.copyWith(
            color: colors.textSecondary,
            height: 1.3,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(
              layout == PortalBodyLayout.list ? 8 : controlRadius,
            ),
          ),
        ),
        chipTheme: base.chipTheme.copyWith(
          backgroundColor: colors.softSurface,
          selectedColor: colors.goldGlow,
          side: BorderSide(color: colors.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(999),
          ),
          labelStyle: AppTextStyles.smallMeta.copyWith(
            color: colors.textPrimary,
            fontWeight: FontWeight.w700,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        ),
        expansionTileTheme: ExpansionTileThemeData(
          tilePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 3),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
          iconColor: colors.goldDark,
          collapsedIconColor: colors.iconMuted,
          textColor: colors.textPrimary,
          collapsedTextColor: colors.textPrimary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
          collapsedShape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(controlRadius),
          ),
        ),
        dataTableTheme: DataTableThemeData(
          headingRowColor: WidgetStatePropertyAll(
            Color.lerp(
              colors.elevatedSurface,
              colors.goldLight,
              colors.isLight ? .035 : .07,
            ),
          ),
          dataRowColor: const WidgetStatePropertyAll(Colors.transparent),
          dividerThickness: 1,
          horizontalMargin: compactRows ? 12 : 16,
          columnSpacing: compactRows ? 16 : 22,
          headingTextStyle: AppTextStyles.smallMeta.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w800,
            letterSpacing: .3,
          ),
          dataTextStyle: AppTextStyles.body.copyWith(
            color: colors.textPrimary,
          ),
        ),
        progressIndicatorTheme: ProgressIndicatorThemeData(
          color: colors.goldMid,
          linearTrackColor: colors.borderMuted,
          circularTrackColor: colors.borderMuted,
        ),
        popupMenuTheme: PopupMenuThemeData(
          color: colors.elevatedSurface,
          elevation: 12,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(18),
            side: BorderSide(color: colors.border),
          ),
          textStyle: AppTextStyles.body.copyWith(color: colors.textPrimary),
        ),
        scrollbarTheme: ScrollbarThemeData(
          radius: const Radius.circular(99),
          thickness: const WidgetStatePropertyAll(4),
          thumbColor: WidgetStateProperty.resolveWith(
            (states) => states.contains(WidgetState.hovered)
                ? colors.goldMid
                : colors.goldMid.withValues(alpha: .54),
          ),
        ),
      ),
      child: PortalBodyCanvas(
        route: route,
        child: DefaultTextStyle.merge(
          style: AppTextStyles.body.copyWith(
            color: colors.textPrimary,
            height: 1.32,
          ),
          child: child,
        ),
      ),
    );
  }
}
