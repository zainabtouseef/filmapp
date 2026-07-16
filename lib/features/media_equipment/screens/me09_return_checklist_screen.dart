import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../models/media_equipment_models.dart';
import '../widgets/media_equipment_components.dart';

class ME09ReturnChecklistScreen extends StatelessWidget {
  const ME09ReturnChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final captured = store.returns
            .where((item) => item.stage != MediaInspectionStage.pending)
            .length;
        final ready = captured == store.returns.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: 'Return decision',
              icon: Icons.assignment_return_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: store.returnConfirmed
                            ? 'RETURN CLOSED'
                            : 'RETURN CHECK REQUIRED',
                        icon: store.returnConfirmed
                            ? Icons.check_circle_outline
                            : Icons.assignment_return_outlined,
                        color: store.returnConfirmed
                            ? colors.success
                            : colors.goldMid,
                      ),
                      StatusChip(
                        label: store.damageClaimOpen
                            ? 'DEPOSIT CLAIM OPEN'
                            : 'NO CLAIM FILED',
                        icon: Icons.report_problem_outlined,
                        color: store.damageClaimOpen
                            ? colors.danger
                            : colors.infoBlue,
                      ),
                      StatusChip(
                        label: ready ? 'EVIDENCE READY' : 'EVIDENCE PENDING',
                        icon: ready
                            ? Icons.verified_outlined
                            : Icons.warning_amber_outlined,
                        color: ready ? colors.success : colors.goldMid,
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: CoreSecondaryButton(
                          icon: Icons.report_problem_outlined,
                          label: 'File claim',
                          compact: true,
                          onTap: () => _showClaimSheet(context, store),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CorePrimaryButton(
                          icon: Icons.lock_open_outlined,
                          label: 'Close return',
                          compact: true,
                          onTap: () {
                            if (!ready) {
                              mediaSnack(
                                  context, 'Complete return evidence first');
                              return;
                            }
                            if (store.damageClaimOpen) {
                              mediaSnack(
                                context,
                                'Resolve the open deposit claim before closing the return',
                              );
                              return;
                            }
                            store.confirmReturn();
                            showCoreSuccessDialog(
                              context,
                              title: 'Return closed',
                              message:
                                  'Deposit release and equipment availability were updated.',
                              buttonLabel: 'Open earnings',
                              onDone: () => Navigator.pushNamed(
                                context,
                                CoreRoutes.ledger,
                              ),
                            );
                          },
                        ),
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
                  for (final item in store.returns)
                    _ReturnCard(
                      item: item,
                      locked: store.returnConfirmed,
                      onVerified: () {
                        store.captureReturn(item.id);
                        mediaSnack(context, '${item.itemName} return verified');
                      },
                      onMissing: () {
                        store.captureReturn(item.id, missing: true);
                        mediaSnack(
                            context, '${item.itemName} missing/damage flagged');
                      },
                    ),
                ],
              ),
              right: MediaSectionCard(
                title: 'Deposit adjustment',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    MediaInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Deposit held',
                      value: mediaMoney(store.depositHeldAmount),
                    ),
                    MediaInfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Claim amount',
                      value: mediaMoney(store.depositClaimedAmount),
                    ),
                    MediaInfoRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin review',
                      value: store.damageClaimOpen ? 'Queued' : 'None',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Return evidence links to the booking, deposit adjustment and admin dispute queue.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CoreSecondaryButton(
                      icon: Icons.support_agent_outlined,
                      label: 'Open support case',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        CoreRoutes.report,
                        arguments: 'Equipment return claim support',
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

  void _showClaimSheet(BuildContext context, MediaEquipmentDemoStore store) {
    final amount = TextEditingController(text: '32000');
    final note = TextEditingController(text: 'One V-mount battery missing');
    showMediaSheet(
      context,
      title: 'Deposit claim',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: amount,
            label: 'Claim amount',
            icon: Icons.payments_outlined,
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 10),
          CoreTextField(
            controller: note,
            label: 'Evidence note',
            icon: Icons.edit_note_outlined,
            maxLines: 2,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.gavel_outlined,
            label: 'Submit claim',
            onTap: () {
              final parsed = int.tryParse(amount.text.trim()) ?? 0;
              if (parsed <= 0) {
                mediaSnack(context, 'Enter a valid claim amount');
                return;
              }
              store.fileDamageClaim(amount: parsed);
              Navigator.pop(context);
              mediaSnack(context, 'Deposit claim sent to admin review');
            },
          ),
        ],
      ),
    ).whenComplete(() {
      amount.dispose();
      note.dispose();
    });
  }
}

class _ReturnCard extends StatelessWidget {
  final MediaInspectionItem item;
  final bool locked;
  final VoidCallback onVerified;
  final VoidCallback onMissing;

  const _ReturnCard({
    required this.item,
    required this.locked,
    required this.onVerified,
    required this.onMissing,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final issue = item.stage == MediaInspectionStage.missing ||
        item.stage == MediaInspectionStage.issue;
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final before = MediaFrame(
                imageUrl: item.beforeImage,
                title: item.itemName,
                badge: 'Out',
                fallbackIcon: Icons.image_outlined,
                aspectRatio: 16 / 9,
                compact: true,
              );
              final after = MediaFrame(
                imageUrl: item.afterImage,
                title: item.itemName,
                badge: 'Return',
                fallbackIcon: Icons.image_outlined,
                aspectRatio: 16 / 9,
                compact: true,
              );
              if (constraints.maxWidth < 520) {
                return Column(
                    children: [before, const SizedBox(height: 8), after]);
              }
              return Row(
                children: [
                  Expanded(child: before),
                  const SizedBox(width: 8),
                  Expanded(child: after),
                ],
              );
            },
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
              StatusChip(
                label: issue ? 'CLAIM REVIEW' : 'MATCHED',
                color: issue ? colors.danger : colors.success,
              ),
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
                  label: 'Missing',
                  compact: true,
                  onTap: locked ? null : onMissing,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Verify',
                  compact: true,
                  onTap: locked ? null : onVerified,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
