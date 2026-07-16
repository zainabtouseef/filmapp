import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../widgets/location_owner_components.dart';

class LO08CheckOutDamageClaimScreen extends StatelessWidget {
  const LO08CheckOutDamageClaimScreen({super.key});

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
        final ready = captured == store.inspection.length;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LocationSectionCard(
              title: 'Check-out decision',
              icon: Icons.verified_user_outlined,
              selected: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: store.checkOutConfirmed
                            ? 'CHECK-OUT CLOSED'
                            : 'AFTER-PHOTOS REQUIRED',
                        icon: store.checkOutConfirmed
                            ? Icons.check_circle_outline
                            : Icons.camera_alt_outlined,
                        color: store.checkOutConfirmed
                            ? colors.success
                            : colors.goldMid,
                      ),
                      StatusChip(
                        label: store.damageClaimOpen
                            ? 'DAMAGE CLAIM OPEN'
                            : 'NO CLAIM FILED',
                        icon: Icons.report_problem_outlined,
                        color: store.damageClaimOpen
                            ? colors.danger
                            : colors.infoBlue,
                      ),
                      StatusChip(
                        label: ready ? 'EVIDENCE READY' : 'CHECK-IN INCOMPLETE',
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
                          onTap: () => _showDamageClaimSheet(context, store),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: CorePrimaryButton(
                          icon: Icons.lock_open_outlined,
                          label: 'Release deposit',
                          compact: true,
                          onTap: () {
                            if (!ready) {
                              locationSnack(
                                context,
                                'Complete check-in evidence before release',
                              );
                              return;
                            }
                            if (store.damageClaimOpen) {
                              locationSnack(
                                context,
                                'Resolve the open damage claim before releasing the deposit',
                              );
                              return;
                            }
                            store.confirmCheckOut();
                            showCoreSuccessDialog(
                              context,
                              title: 'Deposit release queued',
                              message:
                                  'Admin payment verification and producer notifications were updated.',
                              buttonLabel: 'View ledger',
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
            LocationTwoColumn(
              left: LocationResponsiveGrid(
                minWidth: 320,
                children: [
                  for (final item in store.inspection)
                    _ComparisonCard(item: item),
                ],
              ),
              right: LocationSectionCard(
                title: 'Deposit adjustment',
                icon: Icons.account_balance_wallet_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    LocationInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Deposit held',
                      value: locationMoney(store.depositHeldAmount),
                    ),
                    LocationInfoRow(
                      icon: Icons.receipt_long_outlined,
                      label: 'Claim amount',
                      value: locationMoney(store.depositClaimedAmount),
                    ),
                    LocationInfoRow(
                      icon: Icons.admin_panel_settings_outlined,
                      label: 'Admin review',
                      value: store.damageClaimOpen ? 'SA-12 queued' : 'None',
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Damage evidence is attached to the booking, deposit adjustment record and admin dispute queue.',
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
                        arguments: 'Location damage claim support',
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

  void _showDamageClaimSheet(
    BuildContext context,
    LocationOwnerDemoStore store,
  ) {
    final amount = TextEditingController(text: '45000');
    final note =
        TextEditingController(text: 'Floor scratch near lighting stand');
    showLocationSheet(
      context,
      title: 'File damage claim',
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
            label: 'Submit for admin review',
            onTap: () {
              final parsed = int.tryParse(amount.text.trim()) ?? 0;
              if (parsed <= 0) {
                locationSnack(context, 'Enter a valid claim amount');
                return;
              }
              store.fileDamageClaim(amount: parsed);
              Navigator.pop(context);
              locationSnack(context, 'Damage claim submitted to admin');
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

class _ComparisonCard extends StatelessWidget {
  final LocationInspectionItem item;

  const _ComparisonCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final issue = item.stage == LocationInspectionStage.issue;
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              final before = LocationMediaFrame(
                imageUrl: item.beforeImage,
                title: item.area,
                badge: 'Before',
                fallbackIcon: Icons.image_outlined,
                aspectRatio: 16 / 9,
                compact: true,
              );
              final after = LocationMediaFrame(
                imageUrl: item.afterImage,
                title: item.area,
                badge: 'After',
                fallbackIcon: Icons.image_outlined,
                aspectRatio: 16 / 9,
                compact: true,
              );
              if (constraints.maxWidth < 520) {
                return Column(
                  children: [
                    before,
                    const SizedBox(height: 8),
                    after,
                  ],
                );
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
                  item.area,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(
                label: issue ? 'REVIEW NEEDED' : 'MATCHED',
                color: issue ? colors.danger : colors.success,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            issue
                ? 'Condition mismatch is ready for admin review.'
                : 'Before and after condition appears consistent.',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
