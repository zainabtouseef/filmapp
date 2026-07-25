import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_controller.dart';
import '../../../core/analytics/analytics_models.dart';
import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/analytics/csv_download.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPReportsExportScreen extends StatefulWidget {
  const DPReportsExportScreen({super.key});

  @override
  State<DPReportsExportScreen> createState() => _DPReportsExportScreenState();
}

class _DPReportsExportScreenState extends State<DPReportsExportScreen> {
  Future<List<ExportJobDto>>? _future;
  bool _generating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final analytics = AnalyticsScope.maybeOf(context);
    if (analytics != null) _future ??= analytics.exports(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.file_download_outlined,
          label: _generating ? 'Generating...' : 'Generate bookings export',
          onTap: _generating ? () {} : _generateBookingsExport,
        ),
        const SizedBox(height: 8),
        if (future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in required',
            message: 'Connect a live account to view export jobs.',
          )
        else
          FutureBuilder<List<ExportJobDto>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CoreEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Loading exports',
                  message: 'Fetching live report jobs from the database.',
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Reports unavailable',
                  message:
                      'Could not load live export jobs from the database. Check the API connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _reload,
                );
              }
              final reports = snapshot.data ?? const [];
              if (reports.isEmpty) {
                return const CoreEmptyState(
                  icon: Icons.file_download_outlined,
                  title: 'No exports yet',
                  message:
                      'Generate a bookings, ledger, or dispute export to populate this screen from the database.',
                );
              }
              return DPResponsiveGrid(
                minWidth: 320,
                children: reports.map((report) {
                  return _ReportCard(
                    title: '${_titleCase(report.exportType)} Export',
                    project: report.publicId,
                    sections: [
                      report.exportType.replaceAll('_', ' '),
                      '${report.rowCount} rows',
                    ],
                    date: report.completedAt ?? report.requestedAt,
                    status: _titleCase(report.status),
                    exportType: report.exportType,
                  );
                }).toList(),
              );
            },
          ),
        const SizedBox(height: 14),
        DPSectionCard(
          title: 'Export Builder',
          icon: Icons.ios_share_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              _BuilderExportChip(
                exportType: 'bookings',
                label: 'Bookings',
                tone: DpTone.info,
              ),
              _BuilderExportChip(
                exportType: 'contracts',
                label: 'Contracts',
                tone: DpTone.info,
              ),
              _BuilderExportChip(
                exportType: 'ledger',
                label: 'Payments',
                tone: DpTone.warning,
              ),
              _BuilderExportChip(
                exportType: 'schedule',
                label: 'Schedule',
                tone: DpTone.success,
              ),
              _BuilderExportChip(
                exportType: 'room_files',
                label: 'Room files',
                tone: DpTone.neutral,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Future<void> _generateBookingsExport() async {
    final analytics = AnalyticsScope.maybeOf(context);
    if (analytics == null) {
      dpSnack(context, 'Sign in to generate live exports');
      return;
    }
    setState(() => _generating = true);
    try {
      final job = await analytics.createExport('bookings');
      if (!mounted) return;
      final content = job.csvContent;
      final downloaded = content != null &&
          content.isNotEmpty &&
          downloadCsv('${job.exportType}_${job.publicId}.csv', content);
      dpSnack(
        context,
        downloaded
            ? 'Export ${job.publicId} downloaded (${job.rowCount} rows)'
            : 'Export ${job.publicId} ready with ${job.rowCount} rows',
      );
      setState(() => _future = analytics.exports(force: true));
    } catch (error) {
      if (!mounted) return;
      dpSnack(context, 'Could not generate live export right now');
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  void _reload() {
    final analytics = AnalyticsScope.maybeOf(context);
    if (analytics == null) return;
    setState(() => _future = analytics.exports(force: true));
  }

  String _titleCase(String value) {
    return value
        .split(RegExp(r'[_\\s-]+'))
        .where((part) => part.isNotEmpty)
        .map((part) => part[0].toUpperCase() + part.substring(1))
        .join(' ');
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String project;
  final List<String> sections;
  final String date;
  final String status;
  final String exportType;

  const _ReportCard({
    required this.title,
    required this.project,
    required this.sections,
    required this.date,
    required this.status,
    required this.exportType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = status == 'Ready'
        ? DpTone.success
        : status == 'Generating'
            ? DpTone.info
            : DpTone.warning;
    return DPGlassCard(
      selected: status == 'Ready',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: dpText(context, title, strong: true)),
              DPStatusChip(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          dpText(context, '$project - $date'),
          const SizedBox(height: 10),
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              for (final section in sections)
                DPStatusChip(label: section, tone: DpTone.neutral),
            ],
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Text(
                'PDF / CSV / XLS',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              const Spacer(),
              ExportActionButton(
                exportType: exportType,
                label: 'Export',
                builder: (context, onTap, label) => DPHolographicButton(
                  label: label,
                  icon: Icons.download_rounded,
                  onTap: onTap,
                  secondary: true,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _BuilderExportChip extends StatelessWidget {
  final String exportType;
  final String label;
  final DpTone tone;

  const _BuilderExportChip({
    required this.exportType,
    required this.label,
    required this.tone,
  });

  @override
  Widget build(BuildContext context) {
    return ExportActionButton(
      exportType: exportType,
      label: label,
      builder: (context, onTap, chipLabel) => GestureDetector(
        onTap: onTap,
        child: Opacity(
          opacity: onTap == null ? 0.6 : 1,
          child: DPStatusChip(
            label: chipLabel,
            tone: tone,
            icon: Icons.download_outlined,
          ),
        ),
      ),
    );
  }
}
