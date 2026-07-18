import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/insurance_partner_demo_data.dart';
import '../widgets/insurance_partner_components.dart';

class IN03ClaimSupportScreen extends StatefulWidget {
  const IN03ClaimSupportScreen({super.key});

  @override
  State<IN03ClaimSupportScreen> createState() => _IN03ClaimSupportScreenState();
}

class _IN03ClaimSupportScreenState extends State<IN03ClaimSupportScreen> {
  final _notes = TextEditingController(
    text: 'Impact mark visible on front element; awaiting serial confirmation.',
  );
  String? _error;
  Future<List<InsuranceClaimDto>>? _claimsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final insurance = InsuranceScope.maybeOf(context);
    _claimsFuture ??= insurance?.claims(force: true);
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = InsurancePartnerDemoStore.instance;
    final claim = store.primaryClaim;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return InsuranceTwoColumn(
          left: InsuranceSectionCard(
            title: 'Claim inspection',
            icon: Icons.assignment_late_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_claimsFuture != null)
                  FutureBuilder<List<InsuranceClaimDto>>(
                    future: _claimsFuture,
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Padding(
                          padding: EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message: 'Loading live insurance claims...',
                            icon: Icons.hourglass_top_rounded,
                          ),
                        );
                      }
                      final rows = snapshot.data ?? const [];
                      if (rows.isEmpty) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: InlineNotice(
                          message:
                              'Live claims connected: ${rows.length} claim(s), latest ${rows.first.publicId} is ${rows.first.status}.',
                          icon: Icons.cloud_done_outlined,
                          tone: CoreStatusTone.success,
                        ),
                      );
                    },
                  ),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        claim.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metricNumberCompact.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    InsuranceStatusChip(status: store.claimStatus(claim)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  '${claim.source} - ${claim.itemOrRoom} - estimate ${claim.estimate}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.35,
                  ),
                ),
                const SizedBox(height: 12),
                InsuranceProgressMeter(
                  label: 'Evidence completion',
                  percent: store.claimProgress,
                ),
                const SizedBox(height: 12),
                InsuranceResponsiveGrid(
                  minWidth: 210,
                  children: [
                    InsuranceMediaFrame(
                      imageUrl: claim.beforeImageUrl,
                      title: 'Before evidence',
                      badge: 'Handover',
                      fallbackIcon: Icons.photo_outlined,
                      compact: true,
                    ),
                    InsuranceMediaFrame(
                      imageUrl: claim.afterImageUrl,
                      title: 'After evidence',
                      badge: 'Return',
                      fallbackIcon: Icons.photo_camera_outlined,
                      compact: true,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                for (final item in InsurancePartnerDemoData.claimEvidence)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: InsuranceChecklistTile(
                      title: item.label,
                      subtitle: item.detail,
                      checked: store.completedEvidence.contains(item.id),
                      mandatory: item.mandatory,
                      onTap: () => store.toggleEvidence(item.id),
                    ),
                  ),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Adjuster notes',
                    hintText: 'Add evidence notes and decision context',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
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
                          store.saveClaimDraft();
                          insuranceSnack(context, 'Claim draft saved');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.fact_check_outlined,
                        label: 'Finalize',
                        compact: true,
                        onTap: () => _finalize(context, store),
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
                title: 'Policy checks',
                icon: Icons.shield_outlined,
                child: Column(
                  children: [
                    InsuranceInfoRow(
                      icon: Icons.policy_outlined,
                      label: 'Policy',
                      value: claim.policyId.toUpperCase(),
                    ),
                    InsuranceInfoRow(
                      icon: Icons.person_outline_rounded,
                      label: 'Adjuster',
                      value: claim.adjuster,
                    ),
                    InsuranceInfoRow(
                      icon: Icons.timer_outlined,
                      label: 'Due',
                      value: claim.due,
                    ),
                    InsuranceInfoRow(
                      icon: Icons.notes_outlined,
                      label: 'Notes',
                      value: '${store.claimNotes}',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Open claim chat',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.chat),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.report_problem_outlined,
                      label: 'Escalate to dispute',
                      compact: true,
                      onTap: () {
                        store.escalateClaim(claim.id);
                        Navigator.pushNamed(
                          context,
                          CoreRoutes.report,
                          arguments: 'Insurance claim escalation',
                        );
                      },
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              InsuranceSectionCard(
                title: 'Other open claims',
                icon: Icons.assignment_outlined,
                child: Column(
                  children: [
                    for (final item in InsurancePartnerDemoData.claims.where(
                      (item) => item.id != claim.id,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ClaimMiniRow(
                          title: item.title,
                          estimate: item.estimate,
                          status: store.claimStatus(item),
                          onResolve: () {
                            store.resolveClaim(item.id);
                            insuranceSnack(context, 'Claim marked resolved');
                          },
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

  void _finalize(BuildContext context, InsurancePartnerDemoStore store) {
    if (!store.claimReady || _notes.text.trim().length < 12) {
      setState(
        () => _error =
            'Complete required evidence and add adjuster notes before final review.',
      );
      return;
    }
    setState(() => _error = null);
    final insurance = InsuranceScope.maybeOf(context);
    final liveClaims = _claimsFuture;
    if (insurance != null && liveClaims != null) {
      () async {
        try {
          final claims = await liveClaims;
          if (claims.isEmpty) return;
          await insurance.decideClaim(
            claimId: claims.first.publicId,
            status: 'approved',
            estimateMinor: 8500000,
          );
          if (!mounted) return;
          setState(() => _claimsFuture = insurance.claims(force: true));
        } catch (error) {
          if (!context.mounted) return;
          insuranceSnack(context, 'Live claim decision skipped: $error');
        }
      }();
    }
    store.finalizeClaim();
    insuranceSnack(context, 'Claim evidence finalized');
  }
}

class _ClaimMiniRow extends StatelessWidget {
  final String title;
  final String estimate;
  final dynamic status;
  final VoidCallback onResolve;

  const _ClaimMiniRow({
    required this.title,
    required this.estimate,
    required this.status,
    required this.onResolve,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
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
                estimate,
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
        IconButton(
          tooltip: 'Resolve',
          visualDensity: VisualDensity.compact,
          onPressed: onResolve,
          icon: Icon(Icons.check_circle_outline, color: colors.success),
        ),
      ],
    );
  }
}
