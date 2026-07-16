import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../models/media_equipment_models.dart';
import '../routes/media_equipment_routes.dart';
import '../widgets/media_equipment_components.dart';

class ME08HandoverChecklistScreen extends StatelessWidget {
  const ME08HandoverChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final captured = store.handover
            .where((item) => item.stage != MediaInspectionStage.pending)
            .length;
        final total = store.handover.length;
        final progress = total == 0 ? 0.0 : captured / total;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: 'Handover evidence',
              icon: Icons.qr_code_scanner_rounded,
              selected: true,
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 8,
                          borderRadius: BorderRadius.circular(999),
                          backgroundColor: colors.border,
                          color:
                              progress == 1 ? colors.success : colors.goldMid,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '$captured/$total',
                        style: AppTextStyles.smallMetricNumber.copyWith(
                          color:
                              progress == 1 ? colors.success : colors.goldDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: store.handoverConfirmed
                            ? 'HANDOVER CONFIRMED'
                            : 'SERIAL SCAN REQUIRED',
                        icon: Icons.qr_code_scanner_rounded,
                        color: store.handoverConfirmed
                            ? colors.success
                            : colors.goldMid,
                      ),
                      StatusChip(
                        label: 'ACCESSORIES LISTED',
                        icon: Icons.list_alt_outlined,
                        color: colors.infoBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final item in store.handover)
                    _InspectionCard(
                      item: item,
                      before: true,
                      locked: store.handoverConfirmed,
                      onCapture: () {
                        store.captureHandover(item.id);
                        mediaSnack(context, '${item.itemName} serial captured');
                      },
                      onIssue: () {
                        store.captureHandover(item.id, issue: true);
                        mediaSnack(context, '${item.itemName} issue marked');
                      },
                    ),
                ],
              ),
              right: MediaSectionCard(
                title: 'Final handover',
                icon: Icons.draw_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaInfoRow(
                      icon: Icons.movie_creation_outlined,
                      label: 'Booking',
                      value:
                          store.activeBookingLabel ?? 'No booking accepted yet',
                    ),
                    MediaInfoRow(
                      icon: Icons.videocam_outlined,
                      label: 'Active item',
                      value: store.activeItem.modelName,
                    ),
                    MediaInfoRow(
                      icon: Icons.offline_bolt_outlined,
                      label: 'Offline safe',
                      value: 'Draft saved',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Both-party confirmation is blocked until all mandatory item photos and serial ticks are captured.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CorePrimaryButton(
                      icon: Icons.verified_outlined,
                      label: store.handoverConfirmed
                          ? 'Confirmed'
                          : 'Confirm handover',
                      compact: true,
                      onTap: () {
                        if (captured < total) {
                          mediaSnack(context, 'Capture all evidence first');
                          return;
                        }
                        store.confirmHandover();
                        showCoreSuccessDialog(
                          context,
                          title: 'Handover confirmed',
                          message:
                              'Serial evidence is attached to the contract and return checklist.',
                          buttonLabel: 'Open return',
                          onDone: () => Navigator.pushNamed(
                            context,
                            MediaEquipmentRoutes.returns,
                          ),
                        );
                      },
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
}

class _InspectionCard extends StatelessWidget {
  final MediaInspectionItem item;
  final bool before;
  final bool locked;
  final VoidCallback onCapture;
  final VoidCallback onIssue;

  const _InspectionCard({
    required this.item,
    required this.before,
    required this.locked,
    required this.onCapture,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = switch (item.stage) {
      MediaInspectionStage.pending => colors.goldMid,
      MediaInspectionStage.captured ||
      MediaInspectionStage.verified =>
        colors.success,
      MediaInspectionStage.issue ||
      MediaInspectionStage.missing =>
        colors.danger,
    };
    final label = switch (item.stage) {
      MediaInspectionStage.pending => 'PENDING',
      MediaInspectionStage.captured => 'CAPTURED',
      MediaInspectionStage.verified => 'VERIFIED',
      MediaInspectionStage.issue => 'ISSUE',
      MediaInspectionStage.missing => 'MISSING',
    };
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaFrame(
            imageUrl: before ? item.beforeImage : item.afterImage,
            title: item.itemName,
            badge: item.serial,
            fallbackIcon: Icons.videocam_outlined,
            aspectRatio: 16 / 8,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.itemName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(label: label, color: color),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${item.serial} - ${item.accessories}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Issue',
                  compact: true,
                  onTap: locked ? null : onIssue,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.qr_code_scanner_rounded,
                  label: 'Scan',
                  compact: true,
                  onTap: locked ? null : onCapture,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
