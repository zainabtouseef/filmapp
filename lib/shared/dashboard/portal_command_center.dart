import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_radius.dart';
import '../../core/theme/app_text_styles.dart';
import '../widgets/cine_hover_zoom.dart';

/// A single, spacious operational surface modelled on the CinePlanner and
/// Financial Command Centre sections in the shared portal reference.
class PortalCommandCenter extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String primaryTitle;
  final Widget primary;
  final String actionsTitle;
  final List<PortalCommandAction> actions;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PortalCommandCenter({
    super.key,
    required this.eyebrow,
    required this.title,
    this.subtitle,
    required this.icon,
    required this.primaryTitle,
    required this.primary,
    this.actionsTitle = 'Next actions',
    this.actions = const [],
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final border = colors.border.withValues(alpha: dark ? 0.66 : 0.8);

    return CineHoverZoom(
      scale: 1.004,
      pressedScale: 1.012,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(22),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              colors.card,
              Color.alphaBlend(
                colors.goldMid.withValues(alpha: dark ? 0.045 : 0.065),
                colors.softSurface,
              ),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(AppRadius.panel),
          border: Border.all(color: border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: dark ? 0.22 : 0.075),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _CommandHeader(
              eyebrow: eyebrow,
              title: title,
              subtitle: subtitle,
              icon: icon,
              actionLabel: actionLabel,
              onAction: onAction,
            ),
            const SizedBox(height: 18),
            Divider(height: 1, color: border),
            const SizedBox(height: 18),
            LayoutBuilder(
              builder: (context, constraints) {
                final primaryPane = _CommandPane(
                  label: primaryTitle,
                  child: primary,
                );
                final actionPane = _CommandPane(
                  label: actionsTitle,
                  child: actions.isEmpty
                      ? Text(
                          'No actions need attention.',
                          style: AppTextStyles.body.copyWith(
                            color: colors.textSecondary,
                          ),
                        )
                      : Column(
                          children: [
                            for (var i = 0; i < actions.length; i++) ...[
                              _PortalCommandActionRow(action: actions[i]),
                              if (i != actions.length - 1)
                                Divider(height: 1, color: border),
                            ],
                          ],
                        ),
                );

                if (constraints.maxWidth < 760) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      primaryPane,
                      const SizedBox(height: 18),
                      Divider(height: 1, color: border),
                      const SizedBox(height: 18),
                      actionPane,
                    ],
                  );
                }
                return Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(flex: 11, child: primaryPane),
                    const SizedBox(width: 22),
                    Container(width: 1, height: 196, color: border),
                    const SizedBox(width: 22),
                    Expanded(flex: 9, child: actionPane),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class PortalCommandAction {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? value;
  final VoidCallback? onTap;

  const PortalCommandAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.value,
    this.onTap,
  });
}

class PortalCommandDataRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const PortalCommandDataRow({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.goldMid),
          const SizedBox(width: 10),
          SizedBox(
            width: 104,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CommandHeader extends StatelessWidget {
  final String eyebrow;
  final String title;
  final String? subtitle;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _CommandHeader({
    required this.eyebrow,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.actionLabel,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    Widget identity() => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: colors.goldMid.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.goldMid.withValues(alpha: 0.28),
                ),
              ),
              child: Icon(icon, size: 21, color: colors.goldMid),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow.toUpperCase(),
                    style: AppTextStyles.micro.copyWith(
                      color: colors.goldMid,
                      letterSpacing: 2,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    title,
                    style: AppTextStyles.sectionSerifHeading.copyWith(
                      color: colors.textPrimary,
                      fontSize: 25,
                      height: 1.08,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle!,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

    Widget action() => TextButton.icon(
          onPressed: onAction,
          icon: const Icon(Icons.arrow_forward_rounded, size: 17),
          label: Text(actionLabel!),
        );

    return LayoutBuilder(
      builder: (context, constraints) {
        final hasAction = actionLabel != null && onAction != null;
        if (constraints.maxWidth < 520) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              identity(),
              if (hasAction) ...[
                const SizedBox(height: 8),
                Align(alignment: Alignment.centerRight, child: action()),
              ],
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: identity()),
            if (hasAction) ...[
              const SizedBox(width: 12),
              action(),
            ],
          ],
        );
      },
    );
  }
}

class _CommandPane extends StatelessWidget {
  final String label;
  final Widget child;

  const _CommandPane({required this.label, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: AppTextStyles.micro.copyWith(
            color: colors.textTertiary,
            letterSpacing: 1.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 9),
        child,
      ],
    );
  }
}

class _PortalCommandActionRow extends StatelessWidget {
  final PortalCommandAction action;

  const _PortalCommandActionRow({required this.action});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CineHoverZoom(
      scale: 1.008,
      pressedScale: 1.018,
      child: InkWell(
        onTap: action.onTap,
        borderRadius: BorderRadius.circular(15),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: colors.goldMid.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(action.icon, size: 19, color: colors.goldMid),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      action.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.body.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      action.subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (action.value != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                  decoration: BoxDecoration(
                    color: colors.goldMid.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppRadius.pill),
                  ),
                  child: Text(
                    action.value!,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.goldMid,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ],
              if (action.onTap != null) ...[
                const SizedBox(width: 7),
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  size: 14,
                  color: colors.textTertiary,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
