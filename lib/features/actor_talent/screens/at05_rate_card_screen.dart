import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
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
  final _dayRate = TextEditingController();

  @override
  void dispose() {
    _dayRate.dispose();
    super.dispose();
  }

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
      if (dayRate != null) _dayRate.text = (dayRate ~/ 100).toString();
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
    final auth = AuthScope.maybeOf(context);
    final signedIn = auth?.isAuthenticated == true;
    return Column(
      children: [
        ActorSectionCard(
          title: 'Rate Settings',
          icon: Icons.price_change_outlined,
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
                label: 'Offers remain negotiable',
                color: context.appColors.success,
              ),
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
        ActorSectionCard(
          title: 'Published Marketplace Rate',
          icon: Icons.public_outlined,
          selected: signedIn,
          child: signedIn
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'This is the only Actor/Talent rate field currently backed by the server profile.',
                      style: AppTextStyles.body.copyWith(
                        color: context.appColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CoreTextField(
                      controller: _dayRate,
                      label: 'Standard day rate (PKR)',
                      icon: Icons.payments_outlined,
                      keyboardType: TextInputType.number,
                    ),
                    const SizedBox(height: 12),
                    CorePrimaryButton(
                      icon: Icons.publish_outlined,
                      label: 'Publish standard day rate',
                      compact: true,
                      loading: _loading,
                      onTap: _loading ? null : () => _publishRates(context),
                    ),
                  ],
                )
              : const CoreEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to manage rates',
                  message:
                      'The published day rate is saved to your live talent profile.',
                ),
        ),
      ],
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
                final dayRate = int.tryParse(
                  _dayRate.text.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                if (dayRate == null || dayRate <= 0) {
                  if (!context.mounted) return;
                  Navigator.pop(context);
                  actorSnack(context, 'Enter a valid day rate');
                  return;
                }
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
                final dayRate = int.parse(
                  _dayRate.text.replaceAll(RegExp(r'[^0-9]'), ''),
                );
                _publishedDayRateMinor = dayRate * 100;
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
