import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';

class LO07CheckInInspectionScreen extends StatelessWidget {
  const LO07CheckInInspectionScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final captured = store.inspection
            .where((item) => item.stage != LocationInspectionStage.pending)
            .length;
        final total = store.inspection.length;
        final progress = total == 0 ? 0.0 : captured / total;
        final meter =
            store.inspection.where((item) => item.id == 'meter').toList();
        final meterStage = meter.isNotEmpty
            ? meter.first.stage
            : LocationInspectionStage.pending;
        final meterLabel = switch (meterStage) {
          LocationInspectionStage.pending => 'METER READING PENDING',
          LocationInspectionStage.captured => 'METER READING CAPTURED',
          LocationInspectionStage.confirmed => 'METER READING CONFIRMED',
          LocationInspectionStage.issue => 'METER READING ISSUE',
        };
        final meterColor = switch (meterStage) {
          LocationInspectionStage.pending => colors.goldMid,
          LocationInspectionStage.captured ||
          LocationInspectionStage.confirmed =>
            colors.success,
          LocationInspectionStage.issue => colors.danger,
        };
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationSectionCard(
              title: 'Check-in progress',
              icon: Icons.fact_check_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
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
                        label: store.checkInConfirmed
                            ? 'HANDOVER CONFIRMED'
                            : 'EVIDENCE REQUIRED',
                        icon: store.checkInConfirmed
                            ? Icons.verified_outlined
                            : Icons.camera_alt_outlined,
                        color: store.checkInConfirmed
                            ? colors.success
                            : colors.goldMid,
                      ),
                      StatusChip(
                        label: 'CREW 28 CONFIRMED',
                        icon: Icons.groups_2_outlined,
                        color: colors.infoBlue,
                      ),
                      StatusChip(
                        label: meterLabel,
                        icon: Icons.electric_meter_outlined,
                        color: meterColor,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            LocationTwoColumn(
              left: LocationResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final item in store.inspection)
                    _InspectionCaptureCard(
                      item: item,
                      locked: store.checkInConfirmed,
                      onCapture: () {
                        store.captureInspection(item.id);
                        locationSnack(
                          context,
                          '${item.area} before-photo captured',
                        );
                      },
                      onIssue: () {
                        store.captureInspection(item.id, issue: true);
                        locationSnack(context, '${item.area} issue marked');
                      },
                    ),
                ],
              ),
              right: LocationSectionCard(
                title: 'Final review',
                icon: Icons.draw_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationInfoRow(
                      icon: Icons.movie_creation_outlined,
                      label: 'Booking',
                      value:
                          store.activeBookingLabel ?? 'No booking accepted yet',
                    ),
                    LocationInfoRow(
                      icon: Icons.location_city_outlined,
                      label: 'Property',
                      value: store.activeProperty.name,
                    ),
                    LocationInfoRow(
                      icon: Icons.offline_bolt_outlined,
                      label: 'Offline safe',
                      value: 'Draft saved',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Both-party handover can be confirmed only after every required evidence card is captured or marked as an issue.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CorePrimaryButton(
                      icon: Icons.verified_outlined,
                      label: store.checkInConfirmed
                          ? 'Confirmed'
                          : 'Confirm handover',
                      compact: true,
                      onTap: store.checkInConfirmed
                          ? () => locationSnack(
                                context,
                                'Check-in already confirmed',
                              )
                          : () {
                              if (captured < total) {
                                locationSnack(
                                  context,
                                  'Capture all required evidence first',
                                );
                                return;
                              }
                              store.confirmCheckIn();
                              showCoreSuccessDialog(
                                context,
                                title: 'Check-in confirmed',
                                message:
                                    'Evidence is attached to the booking and deposit timeline.',
                                buttonLabel: 'Open check-out',
                                onDone: () => Navigator.pushNamed(
                                  context,
                                  LocationOwnerRoutes.checkOut,
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

class _InspectionCaptureCard extends StatelessWidget {
  final LocationInspectionItem item;
  final bool locked;
  final VoidCallback onCapture;
  final VoidCallback onIssue;

  const _InspectionCaptureCard({
    required this.item,
    required this.locked,
    required this.onCapture,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = switch (item.stage) {
      LocationInspectionStage.pending => colors.goldMid,
      LocationInspectionStage.captured => colors.success,
      LocationInspectionStage.confirmed => colors.success,
      LocationInspectionStage.issue => colors.danger,
    };
    final statusLabel = switch (item.stage) {
      LocationInspectionStage.pending => 'PENDING',
      LocationInspectionStage.captured => 'CAPTURED',
      LocationInspectionStage.confirmed => 'CONFIRMED',
      LocationInspectionStage.issue => 'ISSUE',
    };
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LocationMediaFrame(
            imageUrl: item.beforeImage,
            title: item.area,
            badge: 'Before',
            fallbackIcon: Icons.image_outlined,
            aspectRatio: 16 / 8,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(label: statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            item.note,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
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
                  icon: Icons.camera_alt_outlined,
                  label: 'Capture',
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
