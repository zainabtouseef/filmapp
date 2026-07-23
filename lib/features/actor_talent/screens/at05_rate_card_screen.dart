import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-05 Rate Card
class AT05RateCardScreen extends StatefulWidget {
  const AT05RateCardScreen({super.key});

  @override
  State<AT05RateCardScreen> createState() => _AT05RateCardScreenState();
}

class _AT05RateCardScreenState extends State<AT05RateCardScreen> {
  bool _loaded = false;
  bool _loading = false;
  int? _publishedDayRateMinor;
  String? _loadError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loaded) {
      _loaded = true;
      _loadPublishedDayRate();
    }
  }

  Future<void> _loadPublishedDayRate() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) return;
    setState(() {
      _loading = true;
      _loadError = null;
    });
    try {
      final profile = await auth.talentProfile();
      if (!mounted) return;
      final dayRate = profile.dayRateMinor;
      if (dayRate != null) {
        ActorTalentDemoStore.instance.updateRate(
          'per-day',
          amount: dayRate ~/ 100,
        );
      }
      setState(() => _publishedDayRateMinor = dayRate);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadError = 'Could not load your published day rate.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

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
              title: 'Rate Settings',
              icon: Icons.price_change_outlined,
              actionText: 'Reset guide',
              onActionTap: () => _confirmReset(context),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: _publishedDayRateMinor == null
                        ? 'No published day rate'
                        : 'Published ${_moneyMinor(_publishedDayRateMinor!)}',
                    color: _publishedDayRateMinor == null
                        ? context.appColors.infoBlue
                        : context.appColors.success,
                  ),
                  StatusChip(
                      label: 'Quote guide stays private',
                      color: context.appColors.goldMid),
                  StatusChip(
                      label: 'Every offer remains negotiable',
                      color: context.appColors.success),
                  if (_loading)
                    StatusChip(
                      label: 'Loading published rate',
                      color: context.appColors.infoPurple,
                    ),
                ],
              ),
            ),
            if (_loadError != null) ...[
              const SizedBox(height: 12),
              InlineNotice(
                message: _loadError!,
                icon: Icons.cloud_off_outlined,
                tone: CoreStatusTone.warning,
              ),
            ],
            const SizedBox(height: 12),
            for (final category in categories) ...[
              _categoryCard(context, store, category),
              const SizedBox(height: 12),
            ],
            CorePrimaryButton(
              icon: Icons.publish_outlined,
              label: 'Publish standard day rate',
              compact: true,
              onTap: () => _publishRates(context),
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
            'Restore the private quote guide to its starting values. This does not change your published day rate.',
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

  void _publishRates(BuildContext context) {
    showActorSheet(
      context,
      title: 'Publish standard day rate',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'CineConnect publishes the standard per-day rate to your marketplace profile. Project, travel, usage and overtime quotes remain private negotiation guidance.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.publish_outlined,
            label: 'Publish day rate',
            compact: true,
            onTap: () async {
              final auth = AuthScope.maybeOf(context);
              if (auth == null || !auth.isAuthenticated) {
                Navigator.pop(context);
                actorSnack(context, 'Sign in to publish your day rate');
                return;
              }
              try {
                final profile = await auth.talentProfile();
                if (profile.screenName?.trim().isNotEmpty != true) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  actorSnack(
                    context,
                    'Complete your Casting Profile before publishing a rate',
                  );
                  return;
                }
                final dayRate = ActorTalentDemoStore.instance.rates
                    .firstWhere(
                      (rate) => rate.id == 'per-day',
                      orElse: () => ActorTalentDemoStore.instance.rates.first,
                    )
                    .amount;
                await auth.updateTalentProfile(
                  screenName: profile.screenName!.trim(),
                  languages: profile.languages,
                  dayRateMinor: dayRate * 100,
                  availabilityStatus: profile.availabilityStatus,
                  currency: profile.currency,
                );
              } catch (error) {
                if (!context.mounted) return;
                Navigator.pop(context);
                actorSnack(context, 'Could not publish day rate: $error');
                return;
              }
              if (!context.mounted) return;
              setState(() {
                _publishedDayRateMinor = ActorTalentDemoStore.instance.rates
                        .firstWhere((rate) => rate.id == 'per-day')
                        .amount *
                    100;
                _loadError = null;
              });
              Navigator.pop(context);
              actorSnack(context, 'Standard day rate published');
            },
          ),
        ],
      ),
    );
  }

  String _moneyMinor(int amountMinor) {
    final amount = amountMinor ~/ 100;
    if (amount >= 100000) return 'PKR ${(amount / 1000).round()}k';
    return 'PKR $amount';
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
    if (amount >= 1000) return 'PKR ${(amount / 1000).round()}k';
    return 'PKR $amount';
  }
}
