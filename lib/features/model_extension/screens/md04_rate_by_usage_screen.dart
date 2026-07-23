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
    if (_ratesFuture != null) return;
    final specialist = SpecialistScope.maybeOf(context);
    _ratesFuture = specialist?.modelUsageRates(force: true);
  }

  void _reload() {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    _ratesFuture = specialist.modelUsageRates(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSectionCard(
          title: 'Commercial Pricing Controls',
          icon: Icons.price_change_outlined,
          selected: true,
          child: const ActorResponsiveGrid(
            minWidth: 230,
            children: [
              ActorInfoRow(
                icon: Icons.link_outlined,
                label: 'Extends',
                value: 'Talent base rate card',
              ),
              ActorInfoRow(
                icon: Icons.description_outlined,
                label: 'Used by',
                value: 'Offers and model releases',
              ),
              ActorInfoRow(
                icon: Icons.verified_user_outlined,
                label: 'Protection',
                value: 'Review and negotiation flags',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Usage Rate Library',
          icon: Icons.payments_outlined,
          actionText: 'Add rate',
          onActionTap: _showAddRate,
          child: _ratesFuture == null
              ? const _PreviewRates()
              : FutureBuilder<List<ModelUsageRateDto>>(
                  future: _ratesFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const InlineNotice(
                        message: 'Loading live usage rates...',
                        icon: Icons.hourglass_top_rounded,
                      );
                    }
                    if (snapshot.hasError) {
                      return const Column(
                        children: [
                          InlineNotice(
                            message:
                                'Live rates are unavailable. Preview values are shown.',
                            icon: Icons.cloud_off_outlined,
                          ),
                          SizedBox(height: 10),
                          _PreviewRates(),
                        ],
                      );
                    }
                    final rows = snapshot.data ?? const [];
                    if (rows.isEmpty) {
                      return CoreEmptyState(
                        icon: Icons.price_change_outlined,
                        title: 'No usage rates',
                        message:
                            'Add shoot, media, territory, or exclusivity pricing.',
                        actionLabel: 'Add first rate',
                        onAction: _showAddRate,
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                '${rows.length} live rate(s) available to contract and offer workflows.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        ),
                        for (final rate in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LiveUsageRateRow(
                              rate: rate,
                              onChanged: (body) => _updateRate(rate, body),
                            ),
                          ),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _updateRate(
    ModelUsageRateDto rate,
    Map<String, dynamic> body,
  ) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    try {
      await specialist.updateModelUsageRate(rate.publicId, body);
      if (!mounted) return;
      setState(_reload);
      actorSnack(context, '${rate.label} updated');
    } catch (error) {
      if (mounted) actorSnack(context, 'Could not update rate: $error');
    }
  }

  void _showAddRate() {
    final label = TextEditingController();
    final scope = TextEditingController();
    final amount = TextEditingController();
    var requiresReview = true;
    var negotiable = true;
    showActorSheet(
      context,
      title: 'Add usage rate',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: label,
                label: 'Rate label',
                icon: Icons.sell_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: scope,
                label: 'Usage scope',
                icon: Icons.notes_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: amount,
                label: 'Amount in PKR',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require my review'),
                value: requiresReview,
                onChanged: (value) =>
                    setSheetState(() => requiresReview = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Negotiable'),
                value: negotiable,
                onChanged: (value) => setSheetState(() => negotiable = value),
              ),
              const SizedBox(height: 10),
              CorePrimaryButton(
                icon: Icons.add_rounded,
                label: 'Create rate',
                onTap: () async {
                  final amountPkr = int.tryParse(amount.text.trim());
                  if (label.text.trim().length < 2 ||
                      amountPkr == null ||
                      amountPkr <= 0) {
                    actorSnack(context, 'Enter a label and valid amount');
                    return;
                  }
                  final specialist = SpecialistScope.maybeOf(context);
                  if (specialist == null) {
                    Navigator.pop(context);
                    actorSnack(this.context, 'Preview mode only');
                    return;
                  }
                  try {
                    await specialist.createModelUsageRate({
                      'label': label.text.trim(),
                      'scope': scope.text.trim(),
                      'amount_minor': amountPkr * 100,
                      'currency': 'PKR',
                      'requires_review': requiresReview,
                      'negotiable': negotiable,
                    });
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    actorSnack(this.context, 'Usage rate created');
                  } catch (error) {
                    if (context.mounted) {
                      actorSnack(context, 'Could not create rate: $error');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      label.dispose();
      scope.dispose();
      amount.dispose();
    });
  }
}

class _LiveUsageRateRow extends StatelessWidget {
  final ModelUsageRateDto rate;
  final ValueChanged<Map<String, dynamic>> onChanged;

  const _LiveUsageRateRow({
    required this.rate,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final amountPkr = rate.amountMinor ~/ 100;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(8),
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
                modelMoney(amountPkr),
                style: AppTextStyles.smallMetricNumber.copyWith(
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            rate.scope?.trim().isNotEmpty == true
                ? rate.scope!
                : 'Custom commercial usage',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: rate.requiresReview ? 'Review required' : 'Auto quote',
                color: rate.requiresReview ? colors.goldMid : colors.success,
              ),
              StatusChip(
                label: rate.negotiable ? 'Negotiable' : 'Fixed rate',
                color: rate.negotiable ? colors.infoBlue : colors.infoPurple,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease by PKR 25,000',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => onChanged({
                  'amount_minor':
                      ((amountPkr - 25000).clamp(25000, 3000000)) * 100,
                }),
                icon:
                    Icon(Icons.remove_circle_outline, color: colors.iconMuted),
              ),
              IconButton(
                tooltip: 'Increase by PKR 25,000',
                constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
                onPressed: () => onChanged({
                  'amount_minor': (amountPkr + 25000) * 100,
                }),
                icon: Icon(Icons.add_circle_outline, color: colors.goldDark),
              ),
              const Spacer(),
              Tooltip(
                message: 'Require review',
                child: Switch(
                  value: rate.requiresReview,
                  onChanged: (value) => onChanged({'requires_review': value}),
                ),
              ),
              Tooltip(
                message: 'Negotiable',
                child: Switch(
                  value: rate.negotiable,
                  onChanged: (value) => onChanged({'negotiable': value}),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRates extends StatelessWidget {
  const _PreviewRates();

  @override
  Widget build(BuildContext context) {
    final store = ModelExtensionDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: InlineNotice(
                message: 'Preview mode. Sign in to manage live rates.',
                icon: Icons.visibility_outlined,
              ),
            ),
            for (final rate in store.rates)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PreviewRateRow(rate: rate),
              ),
          ],
        );
      },
    );
  }
}

class _PreviewRateRow extends StatelessWidget {
  final ModelUsageRate rate;

  const _PreviewRateRow({required this.rate});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rate.label,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  rate.scope,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            modelMoney(rate.amount),
            style: AppTextStyles.smallMetricNumber.copyWith(
              color: colors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
