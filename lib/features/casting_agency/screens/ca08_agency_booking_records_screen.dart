import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../widgets/casting_agency_components.dart';

class CA08AgencyBookingRecordsScreen extends StatefulWidget {
  const CA08AgencyBookingRecordsScreen({super.key});

  @override
  State<CA08AgencyBookingRecordsScreen> createState() =>
      _CA08AgencyBookingRecordsScreenState();
}

class _CA08AgencyBookingRecordsScreenState
    extends State<CA08AgencyBookingRecordsScreen> {
  String _query = '';
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
        AgencySectionCard(
          title: 'Records command',
          icon: Icons.receipt_long_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: Column(
            children: [
              AgencySearchField(
                hintText: 'Search live booking IDs...',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in ['All', 'pending', 'paid'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label:
                              filter == 'All' ? filter : filter.toUpperCase(),
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view agency records',
            message:
                'Agency booking records are represented by live commission rows.',
          )
        else
          FutureBuilder<List<AgencyCommissionDto>>(
            future: _future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonCard(height: 360);
              }
              if (snapshot.hasError) {
                return _LoadError(
                  message: 'Could not load agency records',
                  onRetry: _refresh,
                );
              }
              final records = _records(snapshot.data ?? const []);
              return AgencyTwoColumn(
                left: AgencySectionCard(
                  title: 'Booking records',
                  icon: Icons.table_rows_outlined,
                  child: records.isEmpty
                      ? CoreEmptyState(
                          icon: Icons.search_off_rounded,
                          title: 'No live booking records',
                          message: 'Clear filters or wait for commissions.',
                          actionLabel: 'Clear',
                          onAction: () => setState(() {
                            _query = '';
                            _filter = 'All';
                          }),
                        )
                      : Column(
                          children: [
                            for (final record in records)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _RecordRow(
                                  record: record,
                                  onDetail: () => _showRecord(context, record),
                                ),
                              ),
                          ],
                        ),
                ),
                right: AgencySectionCard(
                  title: 'Record health',
                  icon: Icons.analytics_outlined,
                  child: Column(
                    children: [
                      AgencyInfoRow(
                        icon: Icons.business_center_outlined,
                        label: 'Agency bookings',
                        value: '${records.length}',
                      ),
                      AgencyInfoRow(
                        icon: Icons.percent_outlined,
                        label: 'Commission owed',
                        value: _money(
                          records.fold<int>(
                            0,
                            (sum, item) => sum + item.commissionMinor,
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
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
              );
            },
          ),
      ],
    );
  }

  List<AgencyCommissionDto> _records(List<AgencyCommissionDto> rows) {
    final lower = _query.trim().toLowerCase();
    return rows.where((record) {
      final matchesFilter = _filter == 'All' || record.status == _filter;
      final haystack = '${record.bookingId} ${record.status}'.toLowerCase();
      return matchesFilter && (lower.isEmpty || haystack.contains(lower));
    }).toList();
  }

  void _showRecord(BuildContext context, AgencyCommissionDto record) {
    showAgencySheet(
      context,
      title: record.bookingId,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Booking',
            value: record.bookingId,
          ),
          AgencyInfoRow(
            icon: Icons.percent_outlined,
            label: 'Commission',
            value: _money(record.commissionMinor),
          ),
          AgencyInfoRow(
            icon: Icons.verified_outlined,
            label: 'Status',
            value: record.status,
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AgencyCommissionDto record;
  final VoidCallback onDetail;

  const _RecordRow({required this.record, required this.onDetail});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Icon(Icons.business_center_outlined,
              color: colors.goldDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  record.bookingId,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _money(record.commissionMinor),
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          AgencyStatusChip(status: agencyStatusFromString(record.status)),
          const SizedBox(width: 8),
          TextButton(onPressed: onDetail, child: const Text('Details')),
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
