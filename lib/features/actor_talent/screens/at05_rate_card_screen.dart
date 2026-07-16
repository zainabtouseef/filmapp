import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-05 Rate Card
class AT05RateCardScreen extends StatelessWidget {
  const AT05RateCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        final categories = store.rates.map((rate) => rate.category).toSet();
        return Column(
          children: [
            ActorSectionCard(
              title: 'Rate Summary',
              icon: Icons.price_change_outlined,
              actionText: 'Reset',
              onActionTap: () => _confirmReset(context),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                      label: 'Displayed on DP-08',
                      color: context.appColors.infoBlue),
                  StatusChip(
                      label: 'Prefills negotiation',
                      color: context.appColors.goldMid),
                  StatusChip(
                      label: 'OTP protected', color: context.appColors.success),
                ],
              ),
            ),
            const SizedBox(height: 12),
            for (final category in categories) ...[
              _categoryCard(context, store, category),
              const SizedBox(height: 12),
            ],
            CorePrimaryButton(
              icon: Icons.security_rounded,
              label: 'Verify and publish rates',
              compact: true,
              onTap: () => _reauth(context),
            ),
          ],
        );
      },
    );
  }

  Widget _categoryCard(
      BuildContext context, ActorTalentDemoStore store, String category) {
    final rates = store.rates.where((r) => r.category == category).toList();
    return ActorSectionCard(
      title: category,
      icon: Icons.tune_rounded,
      child: Column(
        children: [
          for (var i = 0; i < rates.length; i++)
            _RateRow(rate: rates[i], showDivider: i != rates.length - 1),
        ],
      ),
    );
  }

  void _confirmReset(BuildContext context) {
    showActorSheet(
      context,
      title: 'Reset rates',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Restore default demo rate card values.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.restore_rounded,
            label: 'Reset defaults',
            compact: true,
            onTap: () {
              ActorTalentDemoStore.instance.resetRates();
              Navigator.pop(context);
              actorSnack(context, 'Rate card reset');
            },
          ),
        ],
      ),
    );
  }

  void _reauth(BuildContext context) {
    showActorSheet(
      context,
      title: 'OTP confirmation',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Sensitive rate changes require a simulated OTP confirmation.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.verified_user_outlined,
            label: 'Confirm OTP',
            compact: true,
            onTap: () {
              Navigator.pop(context);
              actorSnack(context, 'Rates published and linked to negotiations');
            },
          ),
        ],
      ),
    );
  }
}

class _RateRow extends StatelessWidget {
  final ActorRateItem rate;
  final bool showDivider;

  const _RateRow({required this.rate, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final store = ActorTalentDemoStore.instance;
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
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
                _money(rate.amount),
                style: AppTextStyles.smallMetricNumber.copyWith(
                  color: colors.textPrimary,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              IconButton(
                tooltip: 'Decrease',
                visualDensity: VisualDensity.compact,
                onPressed: () => store.updateRate(
                  rate.id,
                  amount: (rate.amount - 5000).clamp(5000, 2000000).toInt(),
                ),
                icon:
                    Icon(Icons.remove_circle_outline, color: colors.iconMuted),
              ),
              IconButton(
                tooltip: 'Increase',
                visualDensity: VisualDensity.compact,
                onPressed: () => store.updateRate(
                  rate.id,
                  amount: rate.amount + 5000,
                ),
                icon: Icon(Icons.add_circle_outline, color: colors.goldDark),
              ),
              const Spacer(),
              Text(
                'Negotiable',
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
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

  String _money(int amount) {
    if (amount >= 100000) return 'PKR ${(amount / 1000).round()}k';
    return 'PKR $amount';
  }
}
