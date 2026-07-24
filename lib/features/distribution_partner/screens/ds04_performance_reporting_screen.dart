import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../widgets/distribution_partner_components.dart';

class DS04PerformanceReportingScreen extends StatefulWidget {
  const DS04PerformanceReportingScreen({super.key});

  @override
  State<DS04PerformanceReportingScreen> createState() =>
      _DS04PerformanceReportingScreenState();
}

class _DS04PerformanceReportingScreenState
    extends State<DS04PerformanceReportingScreen> {
  String _query = '';
  String _channel = 'All';
  Future<List<DistributionReportDto>>? _reportsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reportsFuture ??=
        SpecialistScope.maybeOf(context)?.distributionReports(force: true);
  }

  void _refresh() {
    setState(() {
      _reportsFuture =
          SpecialistScope.maybeOf(context)?.distributionReports(force: true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return DistributionSectionCard(
      title: 'Reporting command',
      icon: Icons.analytics_outlined,
      selected: true,
      actionText: _reportsFuture == null ? null : 'Refresh',
      onActionTap: _refresh,
      child: _reportsFuture == null
          ? const CoreEmptyState(
              icon: Icons.lock_outline_rounded,
              title: 'Sign in to view reports',
              message:
                  'Distribution performance rows are loaded from the server.',
            )
          : FutureBuilder<List<DistributionReportDto>>(
              future: _reportsFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const SkeletonCard(height: 520);
                }
                if (snapshot.hasError) {
                  return _LoadError(
                    message: 'Could not load distribution reports',
                    onRetry: _refresh,
                  );
                }
                final liveRows = snapshot.data ?? const [];
                final rows = _rows(liveRows).toList();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DistributionSearchField(
                      hintText: 'Search territory, channel, status...',
                      onChanged: (value) => setState(() => _query = value),
                    ),
                    const SizedBox(height: 10),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          for (final channel in _channels(liveRows))
                            Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: CoreChip(
                                label: channel,
                                selected: _channel == channel,
                                onTap: () => setState(() => _channel = channel),
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    DistributionTwoColumn(
                      left: Column(
                        children: [
                          _AnalyticsCard(rows: rows, allRows: liveRows),
                          const SizedBox(height: 12),
                          DistributionSectionCard(
                            title: 'Report records',
                            icon: Icons.table_rows_outlined,
                            child: rows.isEmpty
                                ? CoreEmptyState(
                                    icon: Icons.search_off_rounded,
                                    title: liveRows.isEmpty
                                        ? 'No live report records'
                                        : 'No report records match filters',
                                    message: liveRows.isEmpty
                                        ? 'Distribution performance reports will appear here after backend ingestion.'
                                        : 'Clear filters or search another territory/channel.',
                                    actionLabel:
                                        liveRows.isEmpty ? null : 'Clear',
                                    onAction: liveRows.isEmpty
                                        ? null
                                        : () {
                                            setState(() {
                                              _query = '';
                                              _channel = 'All';
                                            });
                                          },
                                  )
                                : Column(
                                    children: [
                                      for (final row in rows)
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(bottom: 10),
                                          child: _ReportRow(
                                            row: row,
                                            onDetail: () =>
                                                _showReport(context, row),
                                          ),
                                        ),
                                    ],
                                  ),
                          ),
                        ],
                      ),
                      right: _RevenueSupportCard(rows: liveRows),
                    ),
                  ],
                );
              },
            ),
    );
  }

  Iterable<DistributionReportDto> _rows(List<DistributionReportDto> rows) {
    final lower = _query.trim().toLowerCase();
    return rows.where((row) {
      final matchesChannel = _channel == 'All' || row.channel == _channel;
      final haystack =
          '${row.publicId} ${row.territory} ${row.channel} ${row.currency} ${row.status}'
              .toLowerCase();
      return matchesChannel && haystack.contains(lower);
    });
  }

  List<String> _channels(List<DistributionReportDto> rows) {
    final channels = rows
        .map((row) => row.channel.trim())
        .where((channel) => channel.isNotEmpty)
        .toSet()
        .toList()
      ..sort();
    return ['All', ...channels];
  }

  void _showReport(BuildContext context, DistributionReportDto row) {
    showDistributionSheet(
      context,
      title: row.publicId,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DistributionInfoRow(
            icon: Icons.public_outlined,
            label: 'Territory',
            value: row.territory,
          ),
          DistributionInfoRow(
            icon: Icons.live_tv_outlined,
            label: 'Channel',
            value: row.channel,
          ),
          DistributionInfoRow(
            icon: Icons.visibility_outlined,
            label: 'Audience',
            value: _compactNumber(row.audienceCount),
          ),
          DistributionInfoRow(
            icon: Icons.payments_outlined,
            label: 'Revenue',
            value: _money(row),
          ),
          DistributionInfoRow(
            icon: Icons.flag_outlined,
            label: 'Status',
            value: row.status,
          ),
        ],
      ),
    );
  }
}

class _AnalyticsCard extends StatelessWidget {
  final List<DistributionReportDto> rows;
  final List<DistributionReportDto> allRows;

  const _AnalyticsCard({required this.rows, required this.allRows});

  @override
  Widget build(BuildContext context) {
    final audience =
        rows.fold<int>(0, (total, row) => total + row.audienceCount);
    final revenue = rows.fold<int>(0, (total, row) => total + row.revenueMinor);
    final ottCount =
        rows.where((row) => row.channel.toLowerCase().contains('ott')).length;
    return DistributionSectionCard(
      title: 'Performance analytics',
      icon: Icons.stacked_bar_chart_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MetricActionRail(
            items: [
              MetricActionItem(
                icon: Icons.analytics_outlined,
                value: '${rows.length}',
                title: 'Reports',
                subtitle: allRows.length == rows.length
                    ? 'Live records'
                    : 'Filtered live',
                accentColor: context.appColors.goldDark,
              ),
              MetricActionItem(
                icon: Icons.visibility_outlined,
                value: _compactNumber(audience),
                title: 'Audience',
                subtitle: 'Live total',
                accentColor: context.appColors.infoBlue,
              ),
              MetricActionItem(
                icon: Icons.payments_outlined,
                value: _compactMinor(revenue),
                title: 'Revenue',
                subtitle: 'Live total',
                accentColor: context.appColors.success,
              ),
              MetricActionItem(
                icon: Icons.live_tv_outlined,
                value: '$ottCount',
                title: 'OTT rows',
                subtitle: 'Live records',
                accentColor: context.appColors.infoPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (rows.isEmpty)
            Text(
              'No chart is shown until live report rows are available for the selected filter.',
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
              ),
            )
          else
            for (final entry in _channelTotals(rows).entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _ChartBar(
                  label: entry.key,
                  value: entry.value,
                  maxValue: _maxChannelTotal(rows),
                ),
              ),
        ],
      ),
    );
  }

  Map<String, int> _channelTotals(List<DistributionReportDto> rows) {
    final totals = <String, int>{};
    for (final row in rows) {
      totals.update(
        row.channel.isEmpty ? 'Unknown' : row.channel,
        (value) => value + row.audienceCount,
        ifAbsent: () => row.audienceCount,
      );
    }
    return totals;
  }

  int _maxChannelTotal(List<DistributionReportDto> rows) {
    final values = _channelTotals(rows).values;
    if (values.isEmpty) return 1;
    return values.reduce((a, b) => a > b ? a : b).clamp(1, 1 << 62);
  }
}

class _RevenueSupportCard extends StatelessWidget {
  final List<DistributionReportDto> rows;

  const _RevenueSupportCard({required this.rows});

  @override
  Widget build(BuildContext context) {
    final revenue = rows.fold<int>(0, (total, row) => total + row.revenueMinor);
    final territories = rows
        .map((row) => row.territory)
        .where((value) => value.isNotEmpty)
        .toSet();
    final audience =
        rows.fold<int>(0, (total, row) => total + row.audienceCount);
    return DistributionSectionCard(
      title: 'Revenue support',
      icon: Icons.receipt_long_outlined,
      child: Column(
        children: [
          DistributionInfoRow(
            icon: Icons.payments_outlined,
            label: 'Submitted revenue',
            value: _compactMinor(revenue),
          ),
          DistributionInfoRow(
            icon: Icons.public_outlined,
            label: 'Territories',
            value: '${territories.length} active',
          ),
          DistributionInfoRow(
            icon: Icons.visibility_outlined,
            label: 'Audience reach',
            value: _compactNumber(audience),
          ),
          DistributionInfoRow(
            icon: Icons.table_rows_outlined,
            label: 'Report rows',
            value: '${rows.length}',
          ),
          const SizedBox(height: 10),
          const InlineNotice(
            message:
                'Exports are disabled until the backend exposes a real statement export endpoint.',
            icon: Icons.info_outline_rounded,
          ),
        ],
      ),
    );
  }
}

class _ChartBar extends StatelessWidget {
  final String label;
  final int value;
  final int maxValue;

  const _ChartBar({
    required this.label,
    required this.value,
    required this.maxValue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final widthFactor = (value / maxValue).clamp(0.08, 1.0);
    return Tooltip(
      message: '$label: ${_compactNumber(value)} audience',
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(999),
              child: LinearProgressIndicator(
                minHeight: 10,
                value: widthFactor,
                backgroundColor: colors.border,
                valueColor: AlwaysStoppedAnimation<Color>(colors.goldMid),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            _compactNumber(value),
            style: AppTextStyles.statusText.copyWith(color: colors.textPrimary),
          ),
        ],
      ),
    );
  }
}

class _ReportRow extends StatelessWidget {
  final DistributionReportDto row;
  final VoidCallback onDetail;

  const _ReportRow({required this.row, required this.onDetail});

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
                  row.territory.isEmpty ? row.publicId : row.territory,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              DistributionStatusChip(
                status: distributionStatusFromString(row.status),
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${row.channel} • ${_compactNumber(row.audienceCount)} audience • ${_money(row)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Align(
            alignment: Alignment.centerLeft,
            child: CoreSecondaryButton(
              icon: Icons.info_outline_rounded,
              label: 'Detail',
              compact: true,
              onTap: onDetail,
            ),
          ),
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

String _money(DistributionReportDto row) {
  final major = row.revenueMinor / 100;
  final currency = row.currency.isEmpty ? 'PKR' : row.currency;
  return '$currency ${major.toStringAsFixed(0)}';
}

String _compactMinor(int minor) => _compactNumber((minor / 100).round());

String _compactNumber(num value) {
  final abs = value.abs();
  if (abs >= 1000000000) return '${(value / 1000000000).toStringAsFixed(1)}B';
  if (abs >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
  if (abs >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
  return value.round().toString();
}
