import 'package:flutter/material.dart';

import '../../../shared/widgets/cinematic_backdrop.dart';
import '../../../shared/widgets/app_header.dart' show ThemeToggleButton;
import '../../../shared/widgets/dark_outline_button.dart';
import '../../../shared/widgets/glass_card.dart';
import '../../../shared/widgets/gold_button.dart';
import '../../theme/app_breakpoints.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../core_back_navigation.dart';
import '../models/shared_models.dart';

class CoreScreenScaffold extends StatelessWidget {
  final Widget child;
  final bool scrollable;
  final EdgeInsetsGeometry padding;
  final Widget? bottomBar;
  final bool showGlobalControls;

  /// Vertically centers [child] instead of pinning it to the top —
  /// use for single-card states (error, no-internet, maintenance)
  /// where top-alignment leaves a large empty area below on tall
  /// phones. Leave false for ordinary content screens.
  final bool centerContent;

  const CoreScreenScaffold({
    super.key,
    required this.child,
    this.scrollable = true,
    this.padding = const EdgeInsets.fromLTRB(18, 18, 18, 28),
    this.bottomBar,
    this.showGlobalControls = true,
    this.centerContent = false,
  });

  @override
  Widget build(BuildContext context) {
    final body = LayoutBuilder(
      builder: (context, outer) {
        // Cap content width on tablet/desktop so text/cards don't
        // stretch edge-to-edge — no-op below AppBreakpoints.maxContentWidth.
        Widget capWidth(Widget content) {
          final width = outer.maxWidth > AppBreakpoints.maxContentWidth
              ? AppBreakpoints.maxContentWidth
              : outer.maxWidth;
          return Align(
            alignment: Alignment.topCenter,
            child: SizedBox(width: width, child: content),
          );
        }

        if (!scrollable) {
          return Padding(padding: padding, child: capWidth(child));
        }

        if (!centerContent) {
          return SingleChildScrollView(
            padding: padding,
            child: capWidth(child),
          );
        }

        // Centers content when it fits the viewport; still scrolls
        // (instead of overflowing) if it doesn't.
        return SingleChildScrollView(
          padding: padding,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: outer.maxHeight - padding.vertical,
            ),
            child: Center(child: capWidth(child)),
          ),
        );
      },
    );

    return Scaffold(
      body: Stack(
        children: [
          const Positioned.fill(child: CinematicBackdrop()),
          SafeArea(
            child: Column(
              children: [
                if (showGlobalControls) const _GlobalScreenControls(),
                Expanded(child: body),
                if (bottomBar != null) bottomBar!,
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class CoreAppHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final bool showBack;
  final List<Widget> actions;

  const CoreAppHeader({
    super.key,
    required this.title,
    required this.subtitle,
    this.icon = Icons.movie_filter_outlined,
    this.showBack = false,
    this.actions = const [],
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showBack)
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: CoreIconButton(
              icon: Icons.arrow_back_rounded,
              tooltip: 'Back',
              onTap: () => navigateCoreBack(context),
            ),
          ),
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: colors.goldGradient,
            boxShadow: [BoxShadow(color: colors.goldGlow, blurRadius: 14)],
          ),
          child: Icon(icon, color: colors.onGold, size: 20),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.sectionTitle.copyWith(
                  color: colors.textPrimary,
                  fontSize: 20,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
        ...actions,
      ],
    );
  }
}

class _GlobalScreenControls extends StatelessWidget {
  const _GlobalScreenControls();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 0),
      child: Row(
        children: [
          CoreIconButton(
            icon: Icons.arrow_back_rounded,
            tooltip: 'Back',
            onTap: () => navigateCoreBack(context),
          ),
          const Spacer(),
          const ThemeToggleButton(size: 42),
        ],
      ),
    );
  }
}

class CoreBrandMark extends StatelessWidget {
  final bool large;

  const CoreBrandMark({super.key, this.large = false});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final size = large ? 31.0 : 20.0;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        FittedBox(
          child: RichText(
            maxLines: 1,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'CINE',
                  style: AppTextStyles.brand.copyWith(
                    color: colors.textPrimary,
                    fontSize: size,
                    fontWeight: FontWeight.w900,
                    letterSpacing: large ? 6 : 4,
                    height: 1,
                  ),
                ),
                TextSpan(
                  text: 'CONNECT',
                  style: AppTextStyles.brand.copyWith(
                    color: colors.goldMid,
                    fontSize: size,
                    fontWeight: FontWeight.w900,
                    letterSpacing: large ? 5.2 : 3.4,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          'CAST. CONNECT. CREATE.',
          textAlign: TextAlign.center,
          style: AppTextStyles.tagline.copyWith(
            color: colors.textSecondary,
            fontSize: large ? 11 : 8.5,
            fontWeight: FontWeight.w800,
            letterSpacing: large ? 4.8 : 3.1,
            height: 1,
          ),
        ),
      ],
    );
  }
}

class CorePrimaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;
  final bool loading;

  const CorePrimaryButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.compact = false,
    this.loading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return GoldGradientButton(
        icon: Icons.hourglass_top_rounded,
        label: 'Please wait',
        compact: compact,
      );
    }
    return Opacity(
      opacity: onTap == null ? 0.48 : 1,
      child: GoldGradientButton(
        icon: icon,
        label: label,
        compact: compact,
        onTap: onTap,
      ),
    );
  }
}

class CoreSecondaryButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;
  final bool compact;

  const CoreSecondaryButton({
    super.key,
    required this.icon,
    required this.label,
    this.onTap,
    this.compact = false,
  });

  @override
  Widget build(BuildContext context) {
    return DarkOutlineButton(
      icon: icon,
      label: label,
      compact: compact,
      onTap: onTap,
    );
  }
}

class CoreIconButton extends StatelessWidget {
  final IconData icon;
  final String tooltip;
  final VoidCallback? onTap;

  const CoreIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: GlassContainer(
          width: 42,
          height: 42,
          radius: 21,
          child: Icon(icon, color: colors.icon, size: 22),
        ),
      ),
    );
  }
}

class CoreGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool selected;

  const CoreGlassCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(18),
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassContainer(
      radius: 22,
      padding: padding,
      borderColor: selected ? colors.goldMid : colors.border,
      shadows: selected
          ? [
              BoxShadow(
                color: colors.goldGlow,
                blurRadius: 24,
                spreadRadius: -6,
              ),
            ]
          : [
              BoxShadow(
                color: colors.shadow
                    .withValues(alpha: colors.isLight ? 0.12 : 0.36),
                blurRadius: 20,
                offset: const Offset(0, 10),
              ),
            ],
      child: child,
    );
  }
}

class StatusBadge extends StatelessWidget {
  final String label;
  final IconData? icon;
  final CoreStatusTone tone;

  const StatusBadge({
    super.key,
    required this.label,
    this.icon,
    this.tone = CoreStatusTone.neutral,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = switch (tone) {
      CoreStatusTone.success => colors.success,
      CoreStatusTone.warning => colors.goldMid,
      CoreStatusTone.info => colors.infoBlue,
      CoreStatusTone.danger => colors.danger,
      CoreStatusTone.neutral => colors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isLight ? 0.11 : 0.15),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
          ],
          Text(
            label,
            style: AppTextStyles.micro.copyWith(
              color: color,
              fontWeight: FontWeight.w900,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

enum CoreStatusTone { neutral, success, warning, info, danger }

/// A full-sentence contextual message (warning, info, mismatch notice).
///
/// Use this instead of [StatusBadge] for anything longer than a short
/// status word — StatusBadge is a pill sized for single-line labels and
/// visibly distorts when forced to wrap a sentence.
class InlineNotice extends StatelessWidget {
  final String message;
  final IconData icon;
  final CoreStatusTone tone;

  const InlineNotice({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.tone = CoreStatusTone.info,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = switch (tone) {
      CoreStatusTone.success => colors.success,
      CoreStatusTone.warning => colors.goldMid,
      CoreStatusTone.info => colors.infoBlue,
      CoreStatusTone.danger => colors.danger,
      CoreStatusTone.neutral => colors.textSecondary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: colors.isLight ? 0.08 : 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 17, color: color),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              message,
              style: AppTextStyles.caption.copyWith(
                color: colors.textPrimary,
                height: 1.3,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class CoreTextField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;
  final String? errorText;
  final bool obscureText;
  final TextInputType? keyboardType;
  final int maxLines;
  final Widget? suffix;
  final ValueChanged<String>? onChanged;

  const CoreTextField({
    super.key,
    required this.controller,
    required this.label,
    required this.icon,
    this.errorText,
    this.obscureText = false,
    this.keyboardType,
    this.maxLines = 1,
    this.suffix,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: maxLines > 1 ? 3 : 1,
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        errorText: errorText,
        prefixIcon: Icon(icon, color: colors.goldDark),
        suffixIcon: suffix,
        filled: true,
        fillColor:
            colors.surface.withValues(alpha: colors.isLight ? 0.74 : 0.36),
        labelStyle: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        errorStyle: AppTextStyles.caption.copyWith(color: colors.danger),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.goldMid, width: 1.3),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.danger),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.danger, width: 1.3),
        ),
      ),
    );
  }
}

class CoreDropdownField<T> extends StatelessWidget {
  final T value;
  final List<T> values;
  final String label;
  final IconData icon;
  final ValueChanged<T?> onChanged;

  const CoreDropdownField({
    super.key,
    required this.value,
    required this.values,
    required this.label,
    required this.icon,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DropdownButtonFormField<T>(
      initialValue: value,
      isExpanded: true,
      items: values
          .map(
            (item) => DropdownMenuItem<T>(
              value: item,
              child: Text(
                item.toString(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      dropdownColor: colors.surface,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: colors.goldDark),
        filled: true,
        fillColor:
            colors.surface.withValues(alpha: colors.isLight ? 0.74 : 0.36),
        labelStyle: AppTextStyles.caption.copyWith(color: colors.textSecondary),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(18),
          borderSide: BorderSide(color: colors.goldMid, width: 1.3),
        ),
      ),
    );
  }
}

class UploadCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool uploaded;
  final VoidCallback onTap;

  const UploadCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.uploaded,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: CoreGlassCard(
        selected: uploaded,
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: (uploaded ? colors.success : colors.goldMid)
                    .withValues(alpha: 0.12),
              ),
              child: Icon(
                uploaded
                    ? Icons.check_circle_outline
                    : Icons.cloud_upload_outlined,
                color: uploaded ? colors.success : colors.goldMid,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTextStyles.label.copyWith(
                      color: colors.textPrimary,
                      fontSize: 14.5,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    uploaded ? 'Uploaded' : subtitle,
                    style: AppTextStyles.caption.copyWith(
                      color: uploaded ? colors.success : colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: colors.iconMuted),
          ],
        ),
      ),
    );
  }
}

class StepWizardIndicator extends StatelessWidget {
  final int currentStep;
  final int totalSteps;

  const StepWizardIndicator({
    super.key,
    required this.currentStep,
    required this.totalSteps,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: List.generate(totalSteps, (index) {
        final active = index <= currentStep;
        return Expanded(
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            height: 6,
            margin: EdgeInsets.only(right: index == totalSteps - 1 ? 0 : 8),
            decoration: BoxDecoration(
              gradient: active ? colors.goldGradient : null,
              color: active ? null : colors.border,
              borderRadius: BorderRadius.circular(8),
            ),
          ),
        );
      }),
    );
  }
}

class OtpInputRow extends StatelessWidget {
  final TextEditingController controller;
  final String? errorText;

  const OtpInputRow({
    super.key,
    required this.controller,
    this.errorText,
  });

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      controller: controller,
      label: '6-digit OTP',
      icon: Icons.password_rounded,
      keyboardType: TextInputType.number,
      errorText: errorText,
      onChanged: (value) {
        if (value.length > 6) {
          controller.text = value.substring(0, 6);
          controller.selection =
              TextSelection.collapsed(offset: controller.text.length);
        }
      },
    );
  }
}

class RatingStars extends StatelessWidget {
  final int rating;
  final ValueChanged<int> onChanged;

  const RatingStars({
    super.key,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (index) {
        final active = index < rating;
        return IconButton(
          tooltip: '${index + 1} stars',
          onPressed: () => onChanged(index + 1),
          icon: Icon(
            active ? Icons.star_rounded : Icons.star_border_rounded,
            color: active ? colors.goldMid : colors.iconMuted,
            size: 34,
          ),
        );
      }),
    );
  }
}

class CoreEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final String? actionLabel;
  final VoidCallback? onAction;

  const CoreEmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreGlassCard(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: colors.goldMid.withValues(alpha: 0.12),
            ),
            child: Icon(icon, color: colors.goldMid, size: 30),
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: AppTextStyles.sectionTitle
                .copyWith(color: colors.textPrimary, fontSize: 19),
          ),
          const SizedBox(height: 8),
          Text(
            message,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMuted.copyWith(
              color: colors.textSecondary,
              height: 1.45,
            ),
          ),
          if (actionLabel != null) ...[
            const SizedBox(height: 20),
            CorePrimaryButton(
              icon: Icons.arrow_forward_rounded,
              label: actionLabel!,
              compact: true,
              onTap: onAction,
            ),
          ],
        ],
      ),
    );
  }
}

class SectionLabel extends StatelessWidget {
  final String text;
  final String? action;
  final VoidCallback? onAction;

  const SectionLabel({
    super.key,
    required this.text,
    this.action,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          text,
          style: AppTextStyles.label.copyWith(
            color: colors.textPrimary,
            fontSize: 15,
            fontWeight: FontWeight.w800,
          ),
        ),
        if (action != null)
          TextButton(
            onPressed: onAction,
            child: Text(
              action!,
              style: AppTextStyles.label.copyWith(color: colors.goldDark),
            ),
          ),
      ],
    );
  }
}

class CoreChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  final IconData? icon;

  const CoreChip({
    super.key,
    required this.label,
    this.selected = false,
    this.onTap,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
        decoration: BoxDecoration(
          gradient: selected
              ? colors.activeChipGradient
              : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? colors.goldMid : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon,
                  size: 16,
                  color: selected ? colors.goldDark : colors.iconMuted),
              const SizedBox(width: 7),
            ],
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 180),
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.caption.copyWith(
                  color: selected ? colors.goldDark : colors.textSecondary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<void> showCoreSuccessDialog(
  BuildContext context, {
  required String title,
  required String message,
  String buttonLabel = 'Done',
  VoidCallback? onDone,
}) {
  final colors = context.appColors;
  return showDialog<void>(
    context: context,
    builder: (context) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Icon(Icons.check_circle_outline_rounded,
          color: colors.success, size: 42),
      title: Text(title,
          style:
              AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary)),
      content: Text(message,
          style: AppTextStyles.bodyMuted.copyWith(color: colors.textSecondary)),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.pop(context);
            onDone?.call();
          },
          child: Text(buttonLabel,
              style: AppTextStyles.label.copyWith(color: colors.goldDark)),
        ),
      ],
    ),
  );
}

void showCoreSnack(BuildContext context, String message) {
  final colors = context.appColors;
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message,
          style: AppTextStyles.body.copyWith(color: colors.onGold)),
      backgroundColor: colors.goldDark,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
  );
}

String ledgerStatusLabel(LedgerStatus status) {
  return switch (status) {
    LedgerStatus.notPaid => 'Not paid',
    LedgerStatus.pendingVerification => 'Pending verification',
    LedgerStatus.verified => 'Verified',
    LedgerStatus.partiallyPaid => 'Partially paid',
    LedgerStatus.released => 'Released',
    LedgerStatus.refunded => 'Refunded',
    LedgerStatus.disputed => 'Disputed',
    LedgerStatus.closed => 'Closed',
  };
}

CoreStatusTone ledgerStatusTone(LedgerStatus status) {
  return switch (status) {
    LedgerStatus.verified ||
    LedgerStatus.released ||
    LedgerStatus.closed =>
      CoreStatusTone.success,
    LedgerStatus.pendingVerification ||
    LedgerStatus.partiallyPaid =>
      CoreStatusTone.warning,
    LedgerStatus.disputed => CoreStatusTone.danger,
    LedgerStatus.refunded => CoreStatusTone.info,
    LedgerStatus.notPaid => CoreStatusTone.neutral,
  };
}
