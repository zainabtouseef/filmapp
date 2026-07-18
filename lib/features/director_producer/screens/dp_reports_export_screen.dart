import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPReportsExportScreen extends StatelessWidget {
  const DPReportsExportScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reports = DirectorProducerDemoData.reports;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.file_download_outlined,
          label: 'Generate',
          onTap: () => dpSnack(context, 'Report generation started'),
        ),
        const SizedBox(height: 8),
        DPResponsiveGrid(
          minWidth: 320,
          children: reports
              .map(
                (report) => _ReportCard(
                  title: report.title,
                  project: report.project,
                  sections: report.sections,
                  date: report.generatedDate,
                  status: report.status,
                ),
              )
              .toList(),
        ),
        const SizedBox(height: 14),
        DPSectionCard(
          title: 'Export Builder',
          icon: Icons.ios_share_rounded,
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: const [
              DPStatusChip(label: 'Bookings', tone: DpTone.info),
              DPStatusChip(label: 'Contracts', tone: DpTone.info),
              DPStatusChip(label: 'Payments', tone: DpTone.warning),
              DPStatusChip(label: 'Schedule', tone: DpTone.success),
              DPStatusChip(label: 'Room files', tone: DpTone.neutral),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final String title;
  final String project;
  final List<String> sections;
  final String date;
  final String status;

  const _ReportCard({
    required this.title,
    required this.project,
    required this.sections,
    required this.date,
    required this.status,
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
                exportType: 'bookings',
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
