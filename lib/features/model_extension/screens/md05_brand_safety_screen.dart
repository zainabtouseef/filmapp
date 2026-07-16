import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../data/model_extension_demo_data.dart';

/// MD-05 Brand Safety Preferences
class MD05BrandSafetyScreen extends StatelessWidget {
  const MD05BrandSafetyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModelExtensionDemoStore.instance,
      builder: (context, _) {
        final store = ModelExtensionDemoStore.instance;
        return Column(
          children: [
            ActorSectionCard(
              title: 'Offer Screening',
              icon: Icons.shield_outlined,
              selected: store.autoFlagViolations,
              child: Column(
                children: [
                  _ModelSafetySwitch(
                    label: 'Require my review',
                    subtitle:
                        'Sensitive campaigns pause before inbox delivery.',
                    value: store.requireReview,
                    onChanged: store.toggleRequireReview,
                  ),
                  _ModelSafetySwitch(
                    label: 'Auto-flag violations',
                    subtitle:
                        'Offers violating preferences are marked before inbox.',
                    value: store.autoFlagViolations,
                    onChanged: store.toggleAutoFlag,
                  ),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label:
                            '${store.restricted.where((item) => item.blocked).length} blocked',
                        color: context.appColors.danger,
                      ),
                      StatusChip(
                        label: 'Notifies counterparty',
                        color: context.appColors.infoBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Restricted Categories',
              icon: Icons.block_rounded,
              child: Column(
                children: [
                  for (final category in store.restricted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RestrictedRow(id: category.id),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Auto-Flag Preview',
              icon: Icons.flag_outlined,
              child: Builder(
                builder: (context) {
                  final blocked = store.restricted
                      .where((item) => item.blocked)
                      .map((item) => item.label)
                      .toList();
                  final previewText = blocked.isEmpty
                      ? 'No categories are currently blocked, so no campaigns will be auto-flagged.'
                      : 'A campaign tagged ${blocked.join(", ")} would be stopped before reaching the opportunity inbox.';
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        previewText,
                        style: AppTextStyles.body.copyWith(
                          color: context.appColors.textSecondary,
                          height: 1.35,
                        ),
                      ),
                      const SizedBox(height: 12),
                      CorePrimaryButton(
                        icon: Icons.report_gmailerrorred_outlined,
                        label: 'Simulate flagged offer',
                        compact: true,
                        onTap: () => actorSnack(
                          context,
                          blocked.isEmpty
                              ? 'No restricted categories active — nothing to flag'
                              : 'Offer tagged "${blocked.first}" auto-flagged and hidden from inbox',
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

class _ModelSafetySwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModelSafetySwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RestrictedRow extends StatelessWidget {
  final String id;

  const _RestrictedRow({required this.id});

  @override
  Widget build(BuildContext context) {
    final store = ModelExtensionDemoStore.instance;
    final item = store.restricted.firstWhere((entry) => entry.id == id);
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.blocked ? colors.danger : colors.border),
      ),
      child: Row(
        children: [
          Icon(
            item.blocked ? Icons.block_rounded : Icons.check_circle_outline,
            color: item.blocked ? colors.danger : colors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch(
            value: item.blocked,
            onChanged: (_) {
              store.toggleRestricted(item.id);
              actorSnack(context, '${item.label} preference updated');
            },
          ),
        ],
      ),
    );
  }
}
