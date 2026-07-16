import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/core_safety/screens/report_block_screen.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../widgets/actor_talent_components.dart';

/// AT-12 Safety Controls
class AT12SafetyControlsScreen extends StatelessWidget {
  const AT12SafetyControlsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        final blockedUsers = store.blockedUsers.toList();
        return Column(
          children: [
            ActorSectionCard(
              title: 'Privacy & Boundaries',
              icon: Icons.health_and_safety_outlined,
              child: Column(
                children: [
                  _SafetySwitch(
                    label: 'Phone number hidden',
                    subtitle: 'Directors contact you through CineConnect chat.',
                    value: store.phoneHidden,
                    onChanged: store.togglePhoneHidden,
                  ),
                  _SafetySwitch(
                    label: 'Adult content boundary',
                    subtitle: 'Blocks unsafe or mismatched content offers.',
                    value: store.adultContentBoundary,
                    onChanged: store.toggleAdultContentBoundary,
                  ),
                  _SafetySwitch(
                    label: 'Travel consent required',
                    subtitle: 'Outstation requests need explicit confirmation.',
                    value: store.travelConsentRequired,
                    onChanged: store.toggleTravelConsent,
                  ),
                  _SafetySwitch(
                    label: 'Emergency support on shoot days',
                    subtitle: 'Shows safety contact during active bookings.',
                    value: store.emergencySupport,
                    onChanged: store.toggleEmergencySupport,
                    showDivider: false,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorTwoColumn(
              left: ActorSectionCard(
                title: 'Blocked Users',
                icon: Icons.block_rounded,
                child: Column(
                  children: [
                    if (blockedUsers.isEmpty)
                      StatusChip(
                        label: 'No blocked users',
                        color: context.appColors.success,
                      )
                    else
                      for (var i = 0; i < blockedUsers.length; i++)
                        _BlockedUserRow(
                          name: blockedUsers[i],
                          showDivider: i != blockedUsers.length - 1,
                        ),
                  ],
                ),
              ),
              right: ActorSectionCard(
                title: 'Report & Support',
                icon: Icons.support_agent_outlined,
                child: Column(
                  children: [
                    CorePrimaryButton(
                      icon: Icons.report_gmailerrorred_outlined,
                      label: 'Report suspicious offer',
                      compact: true,
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute<void>(
                          builder: (_) => ReportBlockScreen(
                            onBlock: () =>
                                store.block('Ali Khan (TVC Shoot — Lahore)'),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.call_outlined,
                      label: 'Emergency contact',
                      compact: true,
                      onTap: () async {
                        await Clipboard.setData(
                          const ClipboardData(text: '+92 300 0000000'),
                        );
                        if (!context.mounted) return;
                        actorSnack(
                          context,
                          'Emergency support number copied: +92 300 0000000',
                        );
                      },
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Safety reports route to SC-16 and Super Admin support queue.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: context.appColors.textSecondary,
                        height: 1.3,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _SafetySwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final bool showDivider;

  const _SafetySwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
    this.showDivider = true,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
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
                const SizedBox(height: 3),
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

class _BlockedUserRow extends StatelessWidget {
  final String name;
  final bool showDivider;

  const _BlockedUserRow({required this.name, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Row(
        children: [
          Icon(Icons.person_off_outlined, color: colors.danger, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          TextButton(
            onPressed: () {
              ActorTalentDemoStore.instance.unblock(name);
              actorSnack(context, '$name unblocked');
            },
            child: const Text('Unblock'),
          ),
        ],
      ),
    );
  }
}
