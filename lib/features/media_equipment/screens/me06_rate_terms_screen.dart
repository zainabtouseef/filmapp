import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/media_equipment_demo_data.dart';
import '../models/media_equipment_models.dart';
import '../widgets/media_equipment_components.dart';

class ME06RateTermsScreen extends StatelessWidget {
  const ME06RateTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: '${store.terms.where((item) => item.enabled).length}',
                  icon: Icons.check_circle_outline,
                  title: 'Enabled rates',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(context, MediaTone.green),
                ),
                MetricActionItem(
                  value: store.terms
                          .firstWhere((item) => item.id == 'deposit')
                          .enabled
                      ? mediaMoney(
                          store.terms
                              .firstWhere((item) => item.id == 'deposit')
                              .amount,
                        )
                      : 'Not required',
                  icon: Icons.verified_user_outlined,
                  title: 'Deposit',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(context, MediaTone.gold),
                ),
                MetricActionItem(
                  value: store.termsPublished ? 'Published' : 'Draft',
                  icon: Icons.rule_folder_outlined,
                  title: 'Sync status',
                  subtitle: 'Current',
                  accentColor: mediaToneColor(
                    context,
                    store.termsPublished ? MediaTone.green : MediaTone.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Rates and terms',
                icon: Icons.rule_folder_outlined,
                selected: true,
                child: Column(
                  children: [
                    for (final term in store.terms)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TermRow(
                          term: term,
                          onMinus: () => store.updateTerm(
                            term.id,
                            amount: (term.amount - 5000).clamp(0, 9999999),
                          ),
                          onPlus: () => store.updateTerm(
                            term.id,
                            amount: term.amount + 5000,
                          ),
                          onEnabled: (value) => store.updateTerm(
                            term.id,
                            enabled: value,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  MediaSectionCard(
                    title: 'Booking rules',
                    icon: Icons.policy_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Damage responsibility, pickup/drop, fuel, weather and cancellation terms attach to every equipment rental contract.',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        MediaInfoRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Pickup/drop',
                          value: 'Client pickup or paid delivery',
                        ),
                        MediaInfoRow(
                          icon: Icons.cloudy_snowing,
                          label: 'Weather clause',
                          value: 'Drone delays allowed',
                        ),
                        MediaInfoRow(
                          icon: Icons.cancel_outlined,
                          label: 'Cancellation',
                          value: '24h fee applies',
                        ),
                        const SizedBox(height: 10),
                        CorePrimaryButton(
                          icon: Icons.lock_outline_rounded,
                          label: 'Publish terms',
                          compact: true,
                          onTap: () => _showPublishOtp(context, store),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MediaSectionCard(
                    title: 'Sensitive controls',
                    icon: Icons.admin_panel_settings_outlined,
                    child: Column(
                      children: [
                        CoreSecondaryButton(
                          icon: Icons.restart_alt_rounded,
                          label: 'Reset defaults',
                          compact: true,
                          onTap: () {
                            store.resetTerms();
                            mediaSnack(context, 'Terms reset to defaults');
                          },
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.lock_person_outlined,
                          label: 'Permission check',
                          compact: true,
                          onTap: () {
                            final verified = MediaEquipmentDemoData
                                .profile.verification
                                .contains('verified');
                            mediaSnack(
                              context,
                              verified
                                  ? 'Permission verified - ${MediaEquipmentDemoData.profile.verification}'
                                  : 'Permission denied - provider not verified',
                            );
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  void _showPublishOtp(BuildContext context, MediaEquipmentDemoStore store) {
    final otp = TextEditingController();
    showMediaSheet(
      context,
      title: 'Publish terms',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OtpInputRow(controller: otp),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.sync_rounded,
            label: 'Confirm publish',
            onTap: () async {
              if (otp.text.trim().length != 6) {
                mediaSnack(context, 'Enter a 6-digit OTP');
                return;
              }
              final operations = OperationsScope.maybeOf(context);
              if (operations != null) {
                try {
                  for (final term in store.terms) {
                    await operations.createEquipmentTerm({
                      'label': term.label,
                      'note': term.note,
                      'amount_minor': term.amount * 100,
                      'currency': 'PKR',
                      'enabled': term.enabled,
                      'term_type': term.id,
                    });
                  }
                } catch (error) {
                  if (context.mounted) {
                    mediaSnack(context, 'Live terms publish skipped: $error');
                  }
                }
              }
              store.publishTerms();
              if (!context.mounted) return;
              Navigator.pop(context);
              mediaSnack(context, 'Terms published to contracts');
            },
          ),
        ],
      ),
    ).whenComplete(otp.dispose);
  }
}

class _TermRow extends StatelessWidget {
  final MediaTermItem term;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<bool> onEnabled;

  const _TermRow({
    required this.term,
    required this.onMinus,
    required this.onPlus,
    required this.onEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(term.icon, color: colors.goldDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  term.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${mediaMoney(term.amount)} - ${term.note}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.statusText.copyWith(
                    color:
                        term.enabled ? colors.goldDark : colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decrease',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onMinus,
            icon: Icon(Icons.remove_circle_outline, color: colors.iconMuted),
          ),
          IconButton(
            tooltip: 'Increase',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onPlus,
            icon: Icon(Icons.add_circle_outline, color: colors.goldDark),
          ),
          Switch.adaptive(value: term.enabled, onChanged: onEnabled),
        ],
      ),
    );
  }
}
