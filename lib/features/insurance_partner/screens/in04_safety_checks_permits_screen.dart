import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/insurance_partner_demo_data.dart';
import '../widgets/insurance_partner_components.dart';

class IN04SafetyChecksPermitsScreen extends StatefulWidget {
  const IN04SafetyChecksPermitsScreen({super.key});

  @override
  State<IN04SafetyChecksPermitsScreen> createState() =>
      _IN04SafetyChecksPermitsScreenState();
}

class _IN04SafetyChecksPermitsScreenState
    extends State<IN04SafetyChecksPermitsScreen> {
  String? _error;

  @override
  Widget build(BuildContext context) {
    final store = InsurancePartnerDemoStore.instance;
    final check = store.primarySafety;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return InsuranceTwoColumn(
          left: InsuranceSectionCard(
            title: 'Safety checklist',
            icon: Icons.fact_check_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                InsuranceMediaFrame(
                  imageUrl: check.imageUrl,
                  title: check.shoot,
                  badge: check.dueDate,
                  fallbackIcon: Icons.health_and_safety_outlined,
                  aspectRatio: 16 / 8.5,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        check.shoot,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metricNumberCompact.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    InsuranceStatusChip(status: store.safetyStatus(check)),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${check.location} - ${check.risk}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                InsuranceProgressMeter(
                  label: 'Permit and safety readiness',
                  percent: store.safetyProgress,
                ),
                const SizedBox(height: 12),
                for (final step in InsurancePartnerDemoData.safetySteps)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InsuranceChecklistTile(
                      title: step.label,
                      subtitle: step.detail,
                      checked: store.completedSafetySteps.contains(step.id),
                      mandatory: step.mandatory,
                      onTap: () => store.toggleSafetyStep(step.id),
                    ),
                  ),
                if (_error != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    _error!,
                    style: AppTextStyles.statusText.copyWith(
                      color: colors.infoPurple,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.save_outlined,
                        label: 'Save draft',
                        compact: true,
                        onTap: () {
                          setState(() => _error = null);
                          store.saveSafetyDraft();
                          insuranceSnack(context, 'Safety draft saved');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.verified_user_outlined,
                        label: 'Complete',
                        compact: true,
                        onTap: () => _complete(context, store),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              InsuranceSectionCard(
                title: 'Permit support',
                icon: Icons.description_outlined,
                child: Column(
                  children: [
                    InsuranceInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Responsible',
                      value: check.responsible,
                    ),
                    InsuranceInfoRow(
                      icon: Icons.calendar_month_outlined,
                      label: 'Due date',
                      value: check.dueDate,
                    ),
                    InsuranceInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Permit',
                      value: check.permit,
                    ),
                    InsuranceInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Open safety chat',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.chat),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InsuranceSectionCard(
                title: 'Upcoming checks',
                icon: Icons.event_note_outlined,
                child: Column(
                  children: [
                    for (final item
                        in InsurancePartnerDemoData.safetyChecks.where(
                      (item) => item.id != check.id,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _SafetyMiniRow(
                          title: item.shoot,
                          subtitle: '${item.location} - ${item.dueDate}',
                          status: store.safetyStatus(item),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _complete(BuildContext context, InsurancePartnerDemoStore store) {
    if (!store.safetyReady) {
      setState(
        () => _error =
            'Complete required permit, risk, evidence and signoff steps.',
      );
      return;
    }
    setState(() => _error = null);
    store.completeSafetyCheck();
    insuranceSnack(context, 'Safety check completed');
  }
}

class _SafetyMiniRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic status;

  const _SafetyMiniRow({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.health_and_safety_outlined,
            color: colors.goldDark, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        InsuranceStatusChip(status: status),
      ],
    );
  }
}
