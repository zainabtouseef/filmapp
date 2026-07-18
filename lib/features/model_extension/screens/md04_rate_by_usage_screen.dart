import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../data/model_extension_demo_data.dart';
import '../models/model_extension_models.dart';
import '../widgets/model_extension_components.dart';

/// MD-04 Rate by Usage
class MD04RateByUsageScreen extends StatefulWidget {
  const MD04RateByUsageScreen({super.key});

  @override
  State<MD04RateByUsageScreen> createState() => _MD04RateByUsageScreenState();
}

class _MD04RateByUsageScreenState extends State<MD04RateByUsageScreen> {
  Future<List<ModelUsageRateDto>>? _ratesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _ratesFuture ??= specialist?.modelUsageRates(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModelExtensionDemoStore.instance,
      builder: (context, _) {
        final store = ModelExtensionDemoStore.instance;
        return Column(
          children: [
            ActorSectionCard(
              title: 'Usage Pricing Rules',
              icon: Icons.price_change_outlined,
              actionText: 'Reset',
              onActionTap: () => _resetSheet(context),
              child: Column(
                children: [
                  const ActorInfoRow(
                    icon: Icons.link_outlined,
                    label: 'Extends',
                    value: 'AT-05 Rate Card',
                  ),
                  const ActorInfoRow(
                    icon: Icons.description_outlined,
                    label: 'Contract',
                    value: 'Prefills model release',
                  ),
                  ActorInfoRow(
                    icon: Icons.verified_user_outlined,
                    label: 'Review protected',
                    value:
                        '${store.rates.where((rate) => rate.requiresReview).length} rows',
                  ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: StatusChip(
                      label: store.ratesPublished ? 'Published' : 'Draft',
                      color: store.ratesPublished
                          ? context.appColors.success
                          : context.appColors.goldMid,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Usage Rates',
              icon: Icons.payments_outlined,
              child: Column(
                children: [
                  if (_ratesFuture != null)
                    FutureBuilder<List<ModelUsageRateDto>>(
                      future: _ratesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live model usage rates...',
                              icon: Icons.hourglass_top_rounded,
                            ),
                          );
                        }
                        final rows = snapshot.data ?? const [];
                        if (rows.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                'Live usage rates connected: ${rows.length} rate(s), latest ${rows.first.label}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  for (final rate in store.rates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _UsageRateRow(rate: rate),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            CorePrimaryButton(
              icon: Icons.security_rounded,
              label: 'OTP publish usage rates',
              compact: true,
              onTap: () => _otpSheet(context),
            ),
          ],
        );
      },
    );
  }

  void _resetSheet(BuildContext context) {
    showActorSheet(
      context,
      title: 'Reset model rates',
      child: CorePrimaryButton(
        icon: Icons.restore_rounded,
        label: 'Restore defaults',
        compact: true,
        onTap: () {
          ModelExtensionDemoStore.instance.resetRates();
          Navigator.pop(context);
          actorSnack(context, 'Model usage rates reset');
        },
      ),
    );
  }

  void _otpSheet(BuildContext context) {
    showActorSheet(
      context,
      title: 'Re-authenticate',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sensitive pricing updates require simulated OTP confirmation.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.verified_user_outlined,
            label: 'Confirm OTP',
            compact: true,
            onTap: () async {
              ModelExtensionDemoStore.instance.publishRates();
              final specialist = SpecialistScope.maybeOf(context);
              if (specialist != null) {
                try {
                  for (final rate in ModelExtensionDemoStore.instance.rates) {
                    await specialist.createModelUsageRate({
                      'label': rate.label,
                      'scope': rate.scope,
                      'amount_minor': rate.amount * 100,
                      'currency': 'PKR',
                      'requires_review': rate.requiresReview,
                      'negotiable': rate.negotiable,
                    });
                  }
                  if (!context.mounted) return;
                  setState(() =>
                      _ratesFuture = specialist.modelUsageRates(force: true));
                } catch (error) {
                  if (context.mounted) {
                    actorSnack(context, 'Live rate publish skipped: $error');
                  }
                }
              }
              if (!context.mounted) return;
              Navigator.pop(context);
              actorSnack(context, 'Usage rates published');
            },
          ),
        ],
      ),
    );
  }
}

class _UsageRateRow extends StatelessWidget {
  final ModelUsageRate rate;

  const _UsageRateRow({required this.rate});

  @override
  Widget build(BuildContext context) {
    final store = ModelExtensionDemoStore.instance;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  rate.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                modelMoney(rate.amount),
                style: AppTextStyles.smallMetricNumber.copyWith(
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            rate.scope,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => store.updateRate(
                  rate.id,
                  amount: (rate.amount - 25000).clamp(25000, 3000000).toInt(),
                ),
                icon:
                    Icon(Icons.remove_circle_outline, color: colors.iconMuted),
              ),
              IconButton(
                tooltip: 'Increase',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => store.updateRate(
                  rate.id,
                  amount: rate.amount + 25000,
                ),
                icon: Icon(Icons.add_circle_outline, color: colors.goldDark),
              ),
              const Spacer(),
              Text(
                'Review',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
              Switch(
                value: rate.requiresReview,
                onChanged: (value) =>
                    store.updateRate(rate.id, requiresReview: value),
              ),
            ],
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Negotiable',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Switch(
                value: rate.negotiable,
                onChanged: (value) =>
                    store.updateRate(rate.id, negotiable: value),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
