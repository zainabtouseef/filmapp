import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';

class BR05NegotiationTermsScreen extends StatelessWidget {
  const BR05NegotiationTermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final term = store.activeTerm;
        return BrandTwoColumn(
          left: BrandSectionCard(
            title: 'Sponsorship terms',
            icon: Icons.handshake_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        term.applicant,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metricNumberCompact.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    BrandStatusChip(status: term.status),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Version ${store.termVersion} - shared negotiation scope for placement, usage rights, exclusivity, approvals and payments.',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                BrandInfoRow(
                  icon: Icons.campaign_outlined,
                  label: 'Scope',
                  value: term.scope,
                ),
                BrandInfoRow(
                  icon: Icons.lock_outline_rounded,
                  label: 'Exclusivity',
                  value: term.exclusivity,
                ),
                BrandInfoRow(
                  icon: Icons.fact_check_outlined,
                  label: 'Approval rights',
                  value: term.approvalRights,
                ),
                BrandInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Payment',
                  value: term.paymentSchedule,
                ),
                const SizedBox(height: 12),
                BrandResponsiveGrid(
                  minWidth: 180,
                  children: const [
                    _TermChip(label: 'Usage: 9 months'),
                    _TermChip(label: 'Territory: Pakistan'),
                    _TermChip(label: 'Approval: brand'),
                    _TermChip(label: 'Content: BTS + stills'),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.chat_bubble_outline_rounded,
                        label: 'Open chat',
                        compact: true,
                        onTap: () =>
                            Navigator.pushNamed(context, CoreRoutes.chat),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.edit_note_outlined,
                        label: 'Counter',
                        compact: true,
                        onTap: () {
                          store.counterTerms();
                          brandSnack(context, 'Counter terms drafted');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.check_circle_outline,
                        label: 'Accept',
                        compact: true,
                        onTap: () {
                          store.acceptTerms();
                          Navigator.pushNamed(
                            context,
                            BrandSponsorRoutes.tracker,
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              BrandSectionCard(
                title: 'Payment schedule',
                icon: Icons.account_tree_outlined,
                child: Column(
                  children: const [
                    _TimelineRow(
                      label: 'Advance',
                      value: '40%',
                      status: BrandStatus.paymentPending,
                    ),
                    _TimelineRow(
                      label: 'Proof approval',
                      value: '40%',
                      status: BrandStatus.reviewing,
                    ),
                    _TimelineRow(
                      label: 'Completion',
                      value: '20%',
                      status: BrandStatus.approved,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Connected records',
                icon: Icons.link_outlined,
                child: Column(
                  children: [
                    BrandInfoRow(
                      icon: Icons.inbox_outlined,
                      label: 'Application',
                      value: 'Maha Productions',
                    ),
                    BrandInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Contract',
                      value: 'Sponsor agreement',
                    ),
                    BrandInfoRow(
                      icon: Icons.track_changes_outlined,
                      label: 'Campaign',
                      value: 'River Lights proof',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.description_outlined,
                      label: 'Open contract',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.contract),
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
}

class _TermChip extends StatelessWidget {
  final String label;

  const _TermChip({required this.label});

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: label,
      icon: Icons.check_circle_outline,
      child: const SizedBox.shrink(),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final String value;
  final BrandStatus status;

  const _TimelineRow({
    required this.label,
    required this.value,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = brandStatusColor(context, status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(Icons.check_circle_outline, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value,
            style: AppTextStyles.smallMeta.copyWith(color: color),
          ),
        ],
      ),
    );
  }
}
