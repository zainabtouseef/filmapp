import 'package:flutter/material.dart';

import '../../../core/bookings/bookings_controller.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPContractCenterScreen extends StatefulWidget {
  const DPContractCenterScreen({super.key});

  @override
  State<DPContractCenterScreen> createState() => _DPContractCenterScreenState();
}

class _DPContractCenterScreenState extends State<DPContractCenterScreen> {
  Future<List<CineContract>>? _future;
  bool _generating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contracts = ContractsScope.maybeOf(context);
    if (contracts != null) _future ??= contracts.contracts(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.article_outlined,
          label:
              _generating ? 'Generating...' : 'Generate from accepted booking',
          onTap: _generating ? () {} : _generateFromAcceptedBooking,
        ),
        const SizedBox(height: 8),
        if (future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in required',
            message: 'Connect a live Director account to view contracts.',
          )
        else
          FutureBuilder<List<CineContract>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CoreEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Loading contracts',
                  message: 'Fetching live agreement records.',
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Contracts unavailable',
                  message:
                      'Could not load live agreement records from the database. Check the API connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _reload,
                );
              }
              final contracts = snapshot.data ?? const [];
              if (contracts.isEmpty) {
                return const CoreEmptyState(
                  icon: Icons.article_outlined,
                  title: 'No contracts yet',
                  message:
                      'Accept a booking and generate a contract to populate this center from the database.',
                );
              }
              return DPResponsiveGrid(
                minWidth: 310,
                children: [
                  for (final contract in contracts)
                    _ContractCard(
                      title: contract.title,
                      project: contract.projectId,
                      stakeholder: contract.counterpartySummary,
                      value: contract.displayValue,
                      status: contract.statusLabel,
                      progress: contract.signatureProgress,
                      date: contract.effectiveDate ?? 'Draft',
                      contractId: contract.publicId,
                      onRequestReview: () => _requestReview(contract),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _reload() {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    setState(() => _future = contracts.contracts(force: true));
  }

  Future<void> _generateFromAcceptedBooking() async {
    final bookings = BookingsScope.maybeOf(context);
    final contracts = ContractsScope.maybeOf(context);
    if (bookings == null || contracts == null) {
      dpSnack(context, 'Sign in to generate live contracts');
      return;
    }
    setState(() => _generating = true);
    try {
      final rows = await bookings.bookings(force: true);
      final accepted = rows.firstWhere((row) => row.status == 'accepted');
      final contract = await contracts.generateForBooking(accepted.publicId);
      if (!mounted) return;
      setState(() {
        _future = contracts.contracts(force: true);
        _generating = false;
      });
      Navigator.pushNamed(context, CoreRoutes.contract,
          arguments: contract.publicId);
    } catch (error) {
      if (!mounted) return;
      setState(() => _generating = false);
      dpSnack(context, 'No accepted booking ready for contract yet');
    }
  }

  Future<void> _requestReview(CineContract contract) async {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    try {
      await contracts.requestLegalReview(contractId: contract.publicId);
      if (!mounted) return;
      dpSnack(context, 'Legal review requested');
    } catch (error) {
      if (!mounted) return;
      dpSnack(context, '$error');
    }
  }
}

class _ContractCard extends StatelessWidget {
  final String title;
  final String project;
  final String stakeholder;
  final String value;
  final String status;
  final double progress;
  final String date;
  final String? contractId;
  final VoidCallback? onRequestReview;

  const _ContractCard({
    required this.title,
    required this.project,
    required this.stakeholder,
    required this.value,
    required this.status,
    required this.progress,
    required this.date,
    required this.contractId,
    required this.onRequestReview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = status == 'Signed'
        ? DpTone.success
        : status == 'Cancelled'
            ? DpTone.danger
            : status == 'Addendums'
                ? DpTone.info
                : DpTone.warning;
    return DPGlassCard(
      selected: status == 'Pending Signature',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dpText(context, title, strong: true)),
              DPStatusChip(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          dpText(context, '$project - $stakeholder'),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: colors.surface.withValues(alpha: 0.28),
            valueColor: AlwaysStoppedAnimation<Color>(colors.goldMid),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                value,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              DPStatusChip(label: date, tone: DpTone.neutral),
            ],
          ),
          const SizedBox(height: 9),
          DPHolographicButton(
            label: 'Open Contract',
            icon: Icons.open_in_new_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              CoreRoutes.contract,
              arguments: contractId,
            ),
            secondary: true,
          ),
          if (contractId != null) ...[
            const SizedBox(height: 8),
            DPHolographicButton(
              label: 'Request Legal Review',
              icon: Icons.gavel_outlined,
              onTap: onRequestReview,
              secondary: true,
            ),
          ],
        ],
      ),
    );
  }
}
