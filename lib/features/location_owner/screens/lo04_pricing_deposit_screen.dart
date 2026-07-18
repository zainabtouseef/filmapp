import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../data/location_owner_demo_data.dart';
import '../models/location_owner_models.dart';
import '../widgets/location_owner_components.dart';

class LO04PricingDepositScreen extends StatefulWidget {
  const LO04PricingDepositScreen({super.key});

  @override
  State<LO04PricingDepositScreen> createState() =>
      _LO04PricingDepositScreenState();
}

class _LO04PricingDepositScreenState extends State<LO04PricingDepositScreen> {
  String _ledgerFilter = 'All';

  @override
  Widget build(BuildContext context) {
    final store = LocationOwnerDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final deposit = store.prices.firstWhere((item) => item.id == 'deposit');
        final fullDay = store.prices.firstWhere((item) => item.id == 'full');
        final night = store.prices.firstWhere((item) => item.id == 'night');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: locationMoney(fullDay.amount),
                  icon: Icons.today_outlined,
                  title: 'Full-day rate',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.gold),
                ),
                MetricActionItem(
                  value: locationMoney(night.amount),
                  icon: Icons.nights_stay_outlined,
                  title: 'Night shoot',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.purple),
                ),
                MetricActionItem(
                  value: locationMoney(deposit.amount),
                  icon: Icons.verified_user_outlined,
                  title: 'Security deposit',
                  subtitle: 'Current',
                  accentColor: locationToneColor(context, LocationTone.green),
                ),
                MetricActionItem(
                  value: store.pricingPublished ? 'Published' : 'Draft',
                  icon: Icons.published_with_changes_outlined,
                  title: 'Pricing status',
                  subtitle: 'Current',
                  accentColor: locationToneColor(
                    context,
                    store.pricingPublished
                        ? LocationTone.green
                        : LocationTone.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            LocationTwoColumn(
              left: LocationSectionCard(
                title: 'Rate card',
                icon: Icons.price_change_outlined,
                selected: true,
                child: Column(
                  children: [
                    for (final price in store.prices)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _PriceRow(
                          price: price,
                          onMinus: () => store.updatePrice(
                            price.id,
                            amount: (price.amount - 5000).clamp(0, 9999999),
                          ),
                          onPlus: () => store.updatePrice(
                            price.id,
                            amount: price.amount + 5000,
                          ),
                          onEnabled: (value) => store.updatePrice(
                            price.id,
                            enabled: value,
                          ),
                        ),
                      ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Expanded(
                          child: CoreSecondaryButton(
                            icon: Icons.receipt_long_outlined,
                            label: 'Receipts',
                            compact: true,
                            onTap: () => Navigator.pushNamed(
                              context,
                              CoreRoutes.ledger,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: CorePrimaryButton(
                            icon: Icons.lock_outline_rounded,
                            label: 'Publish',
                            compact: true,
                            onTap: _showPublishOtp,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              right: Column(
                children: [
                  LocationSectionCard(
                    title: 'Deposit timeline',
                    icon: Icons.account_balance_wallet_outlined,
                    child: Column(
                      children: [
                        _TimelineRow(
                          label: 'Contract generated',
                          status: LocationBookingStatus.contractPending,
                        ),
                        _TimelineRow(
                          label: 'Deposit payment pending',
                          status: LocationBookingStatus.depositPending,
                        ),
                        _TimelineRow(
                          label: 'Admin verification',
                          status: LocationBookingStatus.secured,
                        ),
                        _TimelineRow(
                          label: 'Release or claim',
                          status: LocationBookingStatus.disputed,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  LocationSectionCard(
                    title: 'Ledger preview',
                    icon: Icons.table_rows_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: [
                              for (final filter in ['All', 'Held', 'Secured'])
                                Padding(
                                  padding: const EdgeInsets.only(right: 8),
                                  child: CoreChip(
                                    label: filter,
                                    selected: _ledgerFilter == filter,
                                    onTap: () {
                                      setState(() => _ledgerFilter = filter);
                                      locationSnack(
                                        context,
                                        '$filter ledger filter applied',
                                      );
                                    },
                                  ),
                                ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        for (final item in _filteredLedger(store))
                          Padding(
                            padding: const EdgeInsets.only(bottom: 9),
                            child: Row(
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        item.label,
                                        style: AppTextStyles.cardLabel.copyWith(
                                          color: colors.textPrimary,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                      const SizedBox(height: 3),
                                      Text(
                                        '${item.id == 'led-3' ? locationMoney(store.damageClaimAmount ?? 0) : item.amount} - ${item.dueDate}',
                                        style: AppTextStyles.smallMeta.copyWith(
                                          color: colors.textSecondary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                LocationBookingStatusChip(status: item.status),
                              ],
                            ),
                          ),
                        const SizedBox(height: 6),
                        CoreSecondaryButton(
                          icon: Icons.report_problem_outlined,
                          label: 'Raise issue',
                          compact: true,
                          onTap: () => Navigator.pushNamed(
                            context,
                            CoreRoutes.report,
                            arguments: 'Location pricing or deposit issue',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<LocationLedgerItem> _filteredLedger(LocationOwnerDemoStore store) {
    return store.visibleLedger.where((item) {
      return switch (_ledgerFilter) {
        'Held' => item.status == LocationBookingStatus.depositPending,
        'Secured' => item.status == LocationBookingStatus.secured,
        _ => true,
      };
    });
  }

  void _showPublishOtp() {
    final otp = TextEditingController();
    showLocationSheet(
      context,
      title: 'Publish pricing',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          OtpInputRow(controller: otp),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.verified_user_outlined,
            label: 'Confirm publish',
            onTap: () async {
              if (otp.text.trim().length != 6) {
                locationSnack(context, 'Enter a 6-digit OTP');
                return;
              }
              final operations = OperationsScope.maybeOf(context);
              if (operations != null) {
                try {
                  final properties =
                      await operations.locationProperties(force: true);
                  final propertyId =
                      properties.isEmpty ? null : properties.first.publicId;
                  if (propertyId == null || propertyId.isEmpty) {
                    if (mounted) {
                      locationSnack(
                        context,
                        'Live pricing skipped: create a location first',
                      );
                    }
                  } else {
                    for (final price
                        in LocationOwnerDemoStore.instance.prices) {
                      await operations.createLocationPricing(propertyId, {
                        'label': price.label,
                        'amount_minor': price.amount * 100,
                        'currency': 'PKR',
                        'unit': _pricingUnit(price.id),
                        'enabled': price.enabled,
                        'conditions': 'Published from LO-04 rate card',
                      });
                    }
                  }
                } catch (error) {
                  if (mounted) {
                    locationSnack(context, 'Live pricing skipped: $error');
                  }
                }
              }
              LocationOwnerDemoStore.instance.publishPricing();
              if (!mounted) return;
              Navigator.pop(context);
              locationSnack(context, 'Pricing published and synced');
            },
          ),
        ],
      ),
    ).whenComplete(otp.dispose);
  }

  String _pricingUnit(String priceId) {
    return switch (priceId) {
      'night' => 'night',
      'hourly' => 'hour',
      'deposit' => 'deposit',
      _ => 'day',
    };
  }
}

class _PriceRow extends StatelessWidget {
  final LocationPriceItem price;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<bool> onEnabled;

  const _PriceRow({
    required this.price,
    required this.onMinus,
    required this.onPlus,
    required this.onEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 10),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  price.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  locationMoney(price.amount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.statusText.copyWith(
                    color:
                        price.enabled ? colors.goldDark : colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decrease',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onMinus,
            icon: Icon(Icons.remove_circle_outline, color: colors.iconMuted),
          ),
          IconButton(
            tooltip: 'Increase',
            constraints: const BoxConstraints(minWidth: 44, minHeight: 44),
            onPressed: onPlus,
            icon: Icon(Icons.add_circle_outline, color: colors.goldDark),
          ),
          Switch.adaptive(
            value: price.enabled,
            onChanged: onEnabled,
          ),
        ],
      ),
    );
  }
}

class _TimelineRow extends StatelessWidget {
  final String label;
  final LocationBookingStatus status;

  const _TimelineRow({
    required this.label,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final color = locationStatusColor(context, status);
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: color.withValues(alpha: colors.isLight ? 0.12 : 0.18),
              border: Border.all(color: color.withValues(alpha: 0.38)),
            ),
            child: Icon(Icons.check_rounded, color: color, size: 15),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
