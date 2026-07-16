import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/casting_agency_demo_data.dart';
import '../models/casting_agency_models.dart';
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

  @override
  Widget build(BuildContext context) {
    final store = CastingAgencyDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final records = _records(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AgencySectionCard(
              title: 'Records command',
              icon: Icons.receipt_long_outlined,
              selected: true,
              child: Column(
                children: [
                  AgencySearchField(
                    hintText: 'Search bookings, talent, projects...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Booked',
                          'Closed',
                          'Payment Due',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: _filter == filter,
                              onTap: () {
                                setState(() => _filter = filter);
                                agencySnack(context, '$filter records shown');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            AgencyTwoColumn(
              left: AgencySectionCard(
                title: 'Booking records',
                icon: Icons.table_rows_outlined,
                child: records.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No booking records',
                        message: 'Clear filters or search another project.',
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
                                status: store.recordStatus(record),
                                onDetail: () => _showRecord(context, record),
                                onClose: () {
                                  store.closeRecord(record.id);
                                  agencySnack(context, 'Booking closed');
                                },
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
                      value: '${CastingAgencyDemoData.records.length}',
                    ),
                    AgencyInfoRow(
                      icon: Icons.percent_outlined,
                      label: 'Commission owed',
                      value: 'PKR 322K',
                    ),
                    AgencyInfoRow(
                      icon: Icons.verified_outlined,
                      label: 'Verified records',
                      value: '2 closed',
                    ),
                    const SizedBox(height: 10),
                    AgencyMiniBarChart(
                      values: const [4, 6, 7, 5, 9, 8],
                      colors: [
                        context.appColors.goldMid,
                        context.appColors.infoBlue,
                        context.appColors.success,
                      ],
                      height: 86,
                    ),
                    const SizedBox(height: 12),
                    CoreSecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Export records',
                      compact: true,
                      onTap: () => agencySnack(
                        context,
                        'Agency records export prepared',
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

  Iterable<AgencyBookingRecord> _records(CastingAgencyDemoStore store) {
    final lower = _query.trim().toLowerCase();
    return CastingAgencyDemoData.records.where((record) {
      final status = store.recordStatus(record);
      final matchesFilter = switch (_filter) {
        'Booked' => status == AgencyStatus.booked,
        'Closed' => status == AgencyStatus.closed,
        'Payment Due' => status == AgencyStatus.paymentPending,
        _ => true,
      };
      final haystack =
          '${record.talentName} ${record.project} ${record.value} ${record.commission}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    });
  }

  void _showRecord(BuildContext context, AgencyBookingRecord record) {
    showAgencySheet(
      context,
      title: record.project,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AgencyInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Talent',
            value: record.talentName,
          ),
          AgencyInfoRow(
            icon: Icons.payments_outlined,
            label: 'Value',
            value: record.value,
          ),
          AgencyInfoRow(
            icon: Icons.percent_outlined,
            label: 'Commission',
            value: record.commission,
          ),
          AgencyInfoRow(
            icon: Icons.calendar_today_outlined,
            label: 'Date',
            value: record.date,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Receipt',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, CoreRoutes.ledger);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Issue',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(
                      context,
                      CoreRoutes.report,
                      arguments: 'Agency booking record issue',
                    );
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _RecordRow extends StatelessWidget {
  final AgencyBookingRecord record;
  final AgencyStatus status;
  final VoidCallback onDetail;
  final VoidCallback onClose;

  const _RecordRow({
    required this.record,
    required this.status,
    required this.onDetail,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  record.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              AgencyStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${record.talentName} - ${record.value} - ${record.commission}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
              Text(
                record.date,
                style: AppTextStyles.micro.copyWith(
                  color: colors.textSecondary,
                  letterSpacing: 0,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Close',
                  compact: true,
                  onTap: onClose,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
