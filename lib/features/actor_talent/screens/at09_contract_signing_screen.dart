import 'package:flutter/material.dart';

import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_contract/screens/contract_viewer_screen.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-09 Contract Signing (uses SC-12)
class AT09ContractSigningScreen extends StatefulWidget {
  const AT09ContractSigningScreen({super.key});

  @override
  State<AT09ContractSigningScreen> createState() =>
      _AT09ContractSigningScreenState();
}

class _AT09ContractSigningScreenState extends State<AT09ContractSigningScreen> {
  Future<List<CineContract>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contracts = ContractsScope.maybeOf(context);
    if (contracts != null) _future ??= contracts.contracts(force: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_future != null) {
      return FutureBuilder<List<CineContract>>(
        future: _future,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoreEmptyState(
              icon: Icons.hourglass_top_rounded,
              title: 'Loading contracts',
              message: 'Fetching agreements ready for signature.',
            );
          }
          final rows = snapshot.data ?? const [];
          if (!snapshot.hasError && rows.isNotEmpty) {
            return _LiveContracts(rows: rows, onRefresh: _refresh);
          }
          if (snapshot.hasError) {
            return _ContractLoadError(onRetry: _refresh);
          }
          return const CoreEmptyState(
            icon: Icons.article_outlined,
            title: 'No contracts yet',
            message:
                'Accepted booking terms will appear here when a producer issues a contract.',
          );
        },
      );
    }
    return _DemoContracts();
  }

  void _refresh() {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    setState(() => _future = contracts.contracts(force: true));
  }
}

class _LiveContracts extends StatelessWidget {
  final List<CineContract> rows;
  final VoidCallback onRefresh;

  const _LiveContracts({required this.rows, required this.onRefresh});

  @override
  Widget build(BuildContext context) {
    final primary = rows.first;
    return ActorTwoColumn(
      left: ActorSectionCard(
        title: 'Live Contract Queue',
        icon: Icons.draw_outlined,
        selected: !primary.isSigned,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                StatusChip(
                  label: primary.bookingId,
                  color: context.appColors.infoBlue,
                ),
                StatusChip(
                  label: primary.statusLabel,
                  color: primary.isSigned
                      ? context.appColors.success
                      : context.appColors.goldMid,
                ),
                StatusChip(
                  label: 'Version ${primary.versionNumber}',
                  color: context.appColors.infoPurple,
                ),
              ],
            ),
            const SizedBox(height: 12),
            _LiveContractPreview(contract: primary),
            const SizedBox(height: 12),
            Text(
              'Review every clause before signing. Corrections stay attached to the same booking and contract history.',
              style: AppTextStyles.body.copyWith(
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
            if (rows.length > 1) ...[
              const SizedBox(height: 14),
              for (final contract in rows.skip(1).take(4))
                _ContractQueueRow(contract: contract),
            ],
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
                  primary.isSigned ? 'Signature captured' : 'Signature due',
                  primary.isSigned
                      ? ActorBookingStatus.paymentPending
                      : ActorBookingStatus.contractPending,
                ),
              ],
            ),
            const SizedBox(height: 10),
            CorePrimaryButton(
              icon: Icons.draw_outlined,
              label: primary.isSigned ? 'Signed' : 'Sign contract',
              compact: true,
              onTap: primary.isSigned
                  ? null
                  : () => Navigator.pushNamed(
                        context,
                        CoreRoutes.contract,
                        arguments: primary.publicId,
                      ).then((_) => onRefresh()),
            ),
            const SizedBox(height: 8),
            CoreSecondaryButton(
              icon: Icons.edit_note_outlined,
              label: 'Request correction',
              compact: true,
              onTap: () => Navigator.pushNamed(
                context,
                CoreRoutes.contract,
                arguments: {'contract_id': primary.publicId, 'addendum': true},
              ).then((_) => onRefresh()),
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoContracts extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Talent Agreement',
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

class _ContractQueueRow extends StatelessWidget {
  final CineContract contract;

  const _ContractQueueRow({required this.contract});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.borderMuted)),
      ),
      child: Row(
        children: [
          Icon(Icons.article_outlined, color: colors.goldDark, size: 18),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              contract.title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: () => Navigator.pushNamed(
              context,
              CoreRoutes.contract,
              arguments: contract.publicId,
            ),
            child: Text(contract.isSigned ? 'View' : 'Review'),
          ),
        ],
      ),
    );
  }
}

class _ContractLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _ContractLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Contracts unavailable',
      icon: Icons.cloud_off_outlined,
      tone: ActorTone.danger,
      child: Column(
        children: [
          const CoreEmptyState(
            icon: Icons.sync_problem_outlined,
            title: 'Could not load contracts',
            message: 'Check your connection and try again.',
          ),
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: Icons.refresh_rounded,
            label: 'Try again',
            compact: true,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}

class _LiveContractPreview extends StatelessWidget {
  final CineContract contract;

  const _LiveContractPreview({required this.contract});

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
            contract.title.toUpperCase(),
            style: AppTextStyles.panelLabel.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          ActorInfoRow(
            icon: Icons.movie_filter_outlined,
            label: 'Project',
            value: contract.projectId,
          ),
          ActorInfoRow(
            icon: Icons.payments_outlined,
            label: 'Talent fee',
            value: contract.displayValue,
          ),
          ActorInfoRow(
            icon: Icons.date_range_outlined,
            label: 'Effective',
            value: contract.effectiveDate ?? 'On signature',
          ),
          ActorInfoRow(
            icon: Icons.draw_outlined,
            label: 'Signature',
            value: contract.signatureProgressPercent,
          ),
        ],
      ),
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
