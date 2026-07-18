import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../widgets/location_owner_components.dart';

class LO05RulesRestrictionsScreen extends StatelessWidget {
  const LO05RulesRestrictionsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
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
                  value: '${store.rules.where((item) => item.allowed).length}',
                  icon: Icons.check_circle_outline,
                  title: 'Allowed rules',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.green),
                ),
                MetricActionItem(
                  value: '${store.rules.where((item) => !item.allowed).length}',
                  icon: Icons.block_rounded,
                  title: 'Restricted rules',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.gold),
                ),
                MetricActionItem(
                  value: store.contractRulesSynced ? 'Synced' : 'Draft',
                  icon: Icons.description_outlined,
                  title: 'Contract sync',
                  subtitle: 'Current',
                  accentColor: locationToneColor(
                    context,
                    store.contractRulesSynced
                        ? LocationTone.green
                        : LocationTone.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LocationTwoColumn(
              left: LocationSectionCard(
                title: 'Rules and restrictions',
                icon: Icons.rule_folder_outlined,
                selected: true,
                child: Column(
                  children: [
                    for (final rule in store.rules)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RuleRow(
                          rule: rule,
                          onChanged: () {
                            store.toggleRule(rule.id);
                            locationSnack(
                              context,
                              '${rule.label} updated for public listing',
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  LocationSectionCard(
                    title: 'Contract insert',
                    icon: Icons.draw_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Rules appear on the public property page and are inserted into the location contract before signature.',
                          style: AppTextStyles.smallMeta.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 12),
                        LocationInfoRow(
                          icon: Icons.policy_outlined,
                          label: 'Unsigned parties',
                          value: 'Producer + owner',
                        ),
                        LocationInfoRow(
                          icon: Icons.history_outlined,
                          label: 'Timeline event',
                          value: store.contractRulesSynced
                              ? 'Appended'
                              : 'Waiting',
                        ),
                        const SizedBox(height: 10),
                        CorePrimaryButton(
                          icon: Icons.lock_outline_rounded,
                          label: 'Sync to contract',
                          compact: true,
                          onTap: () => _showSyncOtp(context, store),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocationSectionCard(
                    title: 'Sensitive controls',
                    icon: Icons.admin_panel_settings_outlined,
                    child: Column(
                      children: [
                        CoreSecondaryButton(
                          icon: Icons.restart_alt_rounded,
                          label: 'Reset defaults',
                          compact: true,
                          onTap: () {
                            store.resetRules();
                            locationSnack(context, 'Rules reset to defaults');
                          },
                        ),
                        const SizedBox(height: 8),
                        CoreSecondaryButton(
                          icon: Icons.lock_person_outlined,
                          label: 'Request override',
                          compact: true,
                          onTap: () => locationSnack(
                            context,
                            'Override requires admin approval in demo mode',
                          ),
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

  void _showSyncOtp(BuildContext context, LocationOwnerDemoStore store) {
    final otp = TextEditingController();
    showLocationSheet(
      context,
      title: 'Re-authenticate',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OtpInputRow(controller: otp),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.sync_rounded,
            label: 'Sync rules',
            onTap: () async {
              if (otp.text.trim().length != 6) {
                locationSnack(context, 'Enter a 6-digit OTP');
                return;
              }
              final operations = OperationsScope.maybeOf(context);
              if (operations != null) {
                try {
                  final properties =
                      await operations.locationProperties(force: true);
                  final propertyId =
                      properties.isEmpty ? null : properties.first.publicId;
                  if (propertyId == null || propertyId.isEmpty) {
                    if (context.mounted) {
                      locationSnack(
                        context,
                        'Live rules skipped: create a location first',
                      );
                    }
                  } else {
                    for (final rule in store.rules) {
                      await operations.createLocationRule(propertyId, {
                        'rule_type': rule.id,
                        'label': rule.label,
                        'note': rule.note,
                        'allowed': rule.allowed,
                      });
                    }
                  }
                } catch (error) {
                  if (context.mounted) {
                    locationSnack(context, 'Live rules skipped: $error');
                  }
                }
              }
              store.syncRulesToContract();
              if (!context.mounted) return;
              Navigator.pop(context);
              locationSnack(context, 'Rules synced to contract');
            },
          ),
        ],
      ),
    ).whenComplete(otp.dispose);
  }
}

class _RuleRow extends StatelessWidget {
  final LocationRuleItem rule;
  final VoidCallback onChanged;

  const _RuleRow({
    required this.rule,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = rule.allowed ? colors.success : colors.goldMid;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(rule.icon, color: tone, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: rule.allowed ? 'ALLOWED' : 'RESTRICTED',
                      color: tone,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  rule.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(value: rule.allowed, onChanged: (_) => onChanged()),
        ],
      ),
    );
  }
}
