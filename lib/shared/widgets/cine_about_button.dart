import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import 'glass_card.dart';

const cineConnectReleaseLabel = 'CineConnect · 2026.09';

Future<void> showCineConnectAbout(
  BuildContext context, {
  VoidCallback? onStartTour,
}) {
  final colors = context.appColors;
  return showDialog<void>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: colors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      icon: Icon(Icons.movie_filter_rounded, color: colors.goldMid, size: 40),
      title: Text(
        'About CineConnect',
        style: AppTextStyles.sectionTitle.copyWith(color: colors.textPrimary),
      ),
      content: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 430),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'One connected production workspace for discovery, planning, deals, contracts, and payments.',
              style:
                  AppTextStyles.bodyMuted.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 16),
            _AboutRow(
              icon: Icons.verified_user_outlined,
              title: 'Account and privacy',
              body: 'Your portal only shows data allowed for your active role.',
            ),
            const SizedBox(height: 12),
            _AboutRow(
              icon: Icons.help_outline_rounded,
              title: 'Help',
              body:
                  'Use the guided tour or contact your CineConnect administrator.',
            ),
            const SizedBox(height: 12),
            Text(
              cineConnectReleaseLabel,
              style: AppTextStyles.caption.copyWith(
                color: colors.textTertiary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
      actions: [
        if (onStartTour != null)
          TextButton.icon(
            onPressed: () {
              Navigator.pop(dialogContext);
              onStartTour();
            },
            icon: const Icon(Icons.play_circle_outline_rounded),
            label: const Text('Guided tour'),
          ),
        FilledButton(
          onPressed: () => Navigator.pop(dialogContext),
          child: const Text('Done'),
        ),
      ],
    ),
  );
}

class CineAboutButton extends StatelessWidget {
  final double size;
  final VoidCallback? onStartTour;

  const CineAboutButton({
    super.key,
    this.size = 38,
    this.onStartTour,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Tooltip(
      message: 'About CineConnect',
      child: Semantics(
        button: true,
        label: 'About CineConnect',
        child: GestureDetector(
          onTap: () => showCineConnectAbout(
            context,
            onStartTour: onStartTour,
          ),
          child: GlassContainer(
            width: size,
            height: size,
            radius: size / 2,
            child: Icon(
              Icons.info_outline_rounded,
              color: colors.icon,
              size: size * 0.53,
            ),
          ),
        ),
      ),
    );
  }
}

class _AboutRow extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;

  const _AboutRow({
    required this.icon,
    required this.title,
    required this.body,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: colors.goldDark, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                body,
                style:
                    AppTextStyles.caption.copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
