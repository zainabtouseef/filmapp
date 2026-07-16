import 'package:flutter/material.dart';

import '../../../core/core_contract/screens/contract_viewer_screen.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-09 Contract Signing (uses SC-12)
class AT09ContractSigningScreen extends StatelessWidget {
  const AT09ContractSigningScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return ActorTwoColumn(
          left: ActorSectionCard(
            title: 'SC-12 Stakeholder Contract',
            icon: Icons.draw_outlined,
            selected: !store.contractSigned,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                        label: 'BK-2048', color: context.appColors.infoBlue),
                    StatusChip(
                      label:
                          store.contractSigned ? 'SIGNED' : 'ACTION REQUIRED',
                      color: store.contractSigned
                          ? context.appColors.success
                          : context.appColors.goldMid,
                    ),
                    StatusChip(
                        label: 'Version 2.1',
                        color: context.appColors.infoPurple),
                  ],
                ),
                const SizedBox(height: 12),
                _ContractPreview(signed: store.contractSigned),
                const SizedBox(height: 12),
                Text(
                  'Talent fee, shoot dates, usage limits, payment security and correction history are locked to the shared booking object.',
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          right: ActorSectionCard(
            title: 'Contract Actions',
            icon: Icons.route_outlined,
            child: Column(
              children: [
                ActorTimeline(
                  items: [
                    ('Terms approved', ActorBookingStatus.termsApproved),
                    ('Contract issued', ActorBookingStatus.contractPending),
                    (
                      store.contractSigned
                          ? 'Signature captured'
                          : 'Signature due',
                      store.contractSigned
                          ? ActorBookingStatus.paymentPending
                          : ActorBookingStatus.contractPending,
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CorePrimaryButton(
                  icon: Icons.draw_outlined,
                  label: store.contractSigned ? 'Signed' : 'Sign contract',
                  compact: true,
                  onTap: store.contractSigned
                      ? null
                      : () => Navigator.push(
                            context,
                            MaterialPageRoute<void>(
                              builder: (_) => ContractViewerScreen(
                                onSigned: () {
                                  store.signContract();
                                  actorSnack(context,
                                      'Contract signed. Payment pending.');
                                },
                              ),
                            ),
                          ),
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.edit_note_outlined,
                  label: 'Request correction',
                  compact: true,
                  onTap: () {
                    actorSnack(
                        context, 'Correction request routed to negotiation');
                    Navigator.pushNamed(
                        context, ActorTalentRoutes.counteroffer);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _ContractPreview extends StatelessWidget {
  final bool signed;

  const _ContractPreview({required this.signed});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderMuted)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'CINECONNECT TALENT AGREEMENT',
            style: AppTextStyles.panelLabel.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          const ActorInfoRow(
            icon: Icons.movie_filter_outlined,
            label: 'Project',
            value: 'River Lights',
          ),
          const ActorInfoRow(
            icon: Icons.payments_outlined,
            label: 'Talent fee',
            value: 'PKR 420,000',
          ),
          const ActorInfoRow(
            icon: Icons.date_range_outlined,
            label: 'Dates',
            value: 'Jul 20 - Jul 24',
          ),
          ActorInfoRow(
            icon: Icons.draw_outlined,
            label: 'Signature',
            value: signed ? 'Ali Raza signed' : 'Awaiting talent',
          ),
        ],
      ),
    );
  }
}
