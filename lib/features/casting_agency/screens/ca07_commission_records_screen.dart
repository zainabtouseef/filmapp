import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/marketplace_pricing_preference_panel.dart';
import '../models/casting_agency_models.dart';
import '../widgets/casting_agency_components.dart';

class CA07CommissionRecordsScreen extends StatefulWidget {
  const CA07CommissionRecordsScreen({super.key});

  @override
  State<CA07CommissionRecordsScreen> createState() =>
      _CA07CommissionRecordsScreenState();
}

class _CA07CommissionRecordsScreenState
    extends State<CA07CommissionRecordsScreen> {
  String _filter = 'All';
  Future<List<AgencyCommissionDto>>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??=
        SpecialistScope.maybeOf(context)?.agencyCommissions(force: true);
  }

  void _refresh() {
    setState(() {
      _future =
          SpecialistScope.maybeOf(context)?.agencyCommissions(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const MarketplacePricingPreferencePanel(
          listingTypes: {'agency'},
          title: 'Agency marketplace pricing',
        ),
        const SizedBox(height: 12),
        if (_future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view commissions',
            message: 'Agency commission records are loaded from the server.',
          )
        else
          FutureBuilder<List<AgencyCommissionDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 420);
              }
              if (snapshot.hasError) {
                return _LoadError(
                  message: 'Could not load commission records',
                  onRetry: _refresh,
                );
              }
              final rows = snapshot.data ?? const [];
              final visible = _rows(rows);
              final paidMinor = rows
                  .where((item) => item.status == 'paid')
                  .fold<int>(0, (sum, item) => sum + item.commissionMinor);
              final pendingMinor = rows
                  .where((item) => item.status != 'paid')
                  .fold<int>(0, (sum, item) => sum + item.commissionMinor);
              return Column(
                children: [
                  MetricActionRail(
                    items: [
                      MetricActionItem(
                        value: _money(paidMinor),
                        icon: Icons.verified_outlined,
                        title: 'Verified',
                        subtitle: 'Live commission',
                        accentColor: agencyToneColor(context, AgencyTone.green),
                      ),
                      MetricActionItem(
                        value: _money(pendingMinor),
                        icon: Icons.pending_actions_outlined,
                        title: 'Pending',
                        subtitle: 'Live commission',
                        accentColor: agencyToneColor(context, AgencyTone.gold),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  AgencyTwoColumn(
                    left: AgencySectionCard(
                      title: 'Commission ledger',
                      icon: Icons.table_rows_outlined,
                      selected: true,
                      actionText: 'Refresh',
                      onActionTap: _refresh,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                for (final filter in ['All', 'pending', 'paid'])
                                  Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: CoreChip(
                                      label: filter == 'All'
                                          ? filter
                                          : filter.toUpperCase(),
                                      selected: _filter == filter,
                                      onTap: () =>
                                          setState(() => _filter = filter),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 12),
                          if (visible.isEmpty)
                            CoreEmptyState(
                              icon: Icons.receipt_long_outlined,
                              title: 'No live commission records',
                              message: 'Try another status filter.',
                              actionLabel: 'Clear',
                              onAction: () => setState(() => _filter = 'All'),
                            )
                          else
                            for (final row in visible)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _CommissionRow(item: row),
                              ),
                        ],
                      ),
                    ),
                    right: AgencySectionCard(
                      title: 'Payment actions',
                      icon: Icons.account_tree_outlined,
                      child: Column(
                        children: [
                          const AgencyInfoRow(
                            icon: Icons.cloud_done_outlined,
                            label: 'Source',
                            value: 'Live agency commissions',
                          ),
                          AgencyInfoRow(
                            icon: Icons.receipt_long_outlined,
                            label: 'Records',
                            value: '${rows.length}',
                          ),
                          const SizedBox(height: 8),
                          CoreSecondaryButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Open receipts',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              CoreRoutes.ledger,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
      ],
    );
  }

  List<AgencyCommissionDto> _rows(List<AgencyCommissionDto> rows) {
    return rows.where((item) {
      return _filter == 'All' || item.status == _filter;
    }).toList();
  }
}

class _CommissionRow extends StatelessWidget {
  final AgencyCommissionDto item;

  const _CommissionRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.bookingId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(item.commissionMinor),
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AgencyStatusChip(status: agencyStatusFromString(item.status)),
        ],
      ),
    );
  }
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: message,
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
    );
  }
}

String _money(int minor) {
  final whole = minor ~/ 100;
  if (whole >= 100000) return 'PKR ${(whole / 1000).round()}k';
  return 'PKR $whole';
}
