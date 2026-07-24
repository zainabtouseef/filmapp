import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO04PricingDepositScreen extends StatefulWidget {
  const LO04PricingDepositScreen({super.key});

  @override
  State<LO04PricingDepositScreen> createState() =>
      _LO04PricingDepositScreenState();
}

class _LO04PricingDepositScreenState extends State<LO04PricingDepositScreen> {
  OperationsController? _operations;
  Future<List<LocationPropertyDto>>? _future;
  LocationPropertyDto? _property;
  List<_RateDraft> _rates = const [];
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    if (operations == null || identical(operations, _operations)) return;
    _operations = operations;
    _future = _load();
  }

  Future<List<LocationPropertyDto>> _load({bool force = false}) async {
    final properties = await _operations!.locationProperties(force: force);
    final property = activeLocationProperty(properties);
    if (mounted) {
      setState(() {
        _property = property;
        _rates = _draftsFor(property);
      });
    }
    return properties;
  }

  List<_RateDraft> _draftsFor(LocationPropertyDto? property) {
    if (property == null) return const [];
    final existing = {
      for (final rate in property.pricing) rate.unit: rate,
    };
    return [
      _draftFrom(existing['hour'], 'Hourly', 'hour'),
      _draftFrom(existing['half_day'], 'Half-day', 'half_day'),
      _draftFrom(existing['day'], 'Full-day', 'day'),
      _draftFrom(existing['night'], 'Night shoot', 'night'),
      _draftFrom(existing['overtime'], 'Overtime hour', 'overtime'),
      _draftFrom(existing['cleaning'], 'Cleaning fee', 'cleaning'),
      _draftFrom(existing['deposit'], 'Security deposit', 'deposit'),
    ];
  }

  _RateDraft _draftFrom(
    LocationPricingDto? value,
    String label,
    String unit,
  ) {
    return _RateDraft(
      publicId: value?.publicId,
      label: value?.label ?? label,
      unit: unit,
      amount: (value?.amountMinor ?? 0) ~/ 100,
      enabled: value?.enabled ?? false,
      conditions: value?.conditions,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to manage rates',
        message:
            'Rate cards and deposits are loaded from backend property pricing records.',
      );
    }
    return FutureBuilder<List<LocationPropertyDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Rates unavailable',
            message: locationApiMessage(snapshot.error!),
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load(force: true)),
          );
        }
        if (_property == null) {
          return CoreEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: 'Create a property first',
            message: 'Rates and deposits are stored against a property.',
            actionLabel: 'Create property',
            onAction: () => Navigator.pushNamed(
              context,
              LocationOwnerRoutes.listing,
            ),
          );
        }
        return _buildRateCard();
      },
    );
  }

  Widget _buildRateCard() {
    final colors = context.appColors;
    final fullDay = _rate('day');
    final night = _rate('night');
    final deposit = _rate('deposit');
    final savedCount =
        _rates.where((rate) => rate.publicId?.isNotEmpty == true).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricActionRail(
          items: [
            MetricActionItem(
              value: _rateValue(fullDay),
              icon: Icons.today_outlined,
              title: 'Full-day rate',
              subtitle: fullDay.enabled ? 'Enabled' : 'Not published',
              accentColor: colors.goldMid,
            ),
            MetricActionItem(
              value: _rateValue(night),
              icon: Icons.nights_stay_outlined,
              title: 'Night shoot',
              subtitle: night.enabled ? 'Enabled' : 'Not published',
              accentColor: colors.infoPurple,
            ),
            MetricActionItem(
              value: _rateValue(deposit),
              icon: Icons.verified_user_outlined,
              title: 'Security deposit',
              subtitle: deposit.enabled ? 'Required' : 'Not set',
              accentColor: colors.success,
            ),
            MetricActionItem(
              value: '$savedCount/${_rates.length}',
              icon: Icons.cloud_done_outlined,
              title: 'Saved rate lines',
              subtitle: 'Live property data',
              accentColor: colors.infoBlue,
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
                for (var index = 0; index < _rates.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RateRow(
                      rate: _rates[index],
                      onMinus: () => _adjust(index, -5000),
                      onPlus: () => _adjust(index, 5000),
                      onEnabled: (value) => _setEnabled(index, value),
                    ),
                  ),
                if (_error != null) ...[
                  InlineNotice(
                    icon: Icons.error_outline_rounded,
                    message: 'Could not save rates: $_error',
                    tone: CoreStatusTone.danger,
                  ),
                  const SizedBox(height: 10),
                ],
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.receipt_long_outlined,
                        label: 'Receipts',
                        compact: true,
                        onTap: () =>
                            Navigator.pushNamed(context, CoreRoutes.ledger),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.save_outlined,
                        label: _saving ? 'Saving...' : 'Save rates',
                        compact: true,
                        onTap: _saving ? null : _saveRates,
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
                title: 'Booking protections',
                icon: Icons.security_outlined,
                tone: LocationTone.green,
                child: Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Deposit',
                      value: deposit.enabled
                          ? locationMoney(deposit.amount)
                          : 'Not required',
                    ),
                    LocationInfoRow(
                      icon: Icons.cleaning_services_outlined,
                      label: 'Cleaning fee',
                      value: _rate('cleaning').enabled
                          ? locationMoney(_rate('cleaning').amount)
                          : 'Not charged',
                    ),
                    LocationInfoRow(
                      icon: Icons.more_time_outlined,
                      label: 'Overtime',
                      value: _rate('overtime').enabled
                          ? locationMoney(_rate('overtime').amount)
                          : 'Not set',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These amounts become quote inputs. Payment verification and release remain part of the secured booking workflow.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LocationSectionCard(
                title: 'Rate guidance',
                icon: Icons.tips_and_updates_outlined,
                tone: LocationTone.blue,
                child: Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Hourly',
                      value: 'Short access or prep',
                    ),
                    LocationInfoRow(
                      icon: Icons.today_outlined,
                      label: 'Full-day',
                      value: 'Primary discovery price',
                    ),
                    LocationInfoRow(
                      icon: Icons.nights_stay_outlined,
                      label: 'Night',
                      value: 'Noise and access premium',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _adjust(int index, int delta) {
    final updated = List<_RateDraft>.of(_rates);
    final rate = updated[index];
    updated[index] = rate.copyWith(
      amount: (rate.amount + delta).clamp(0, 999999999),
    );
    setState(() => _rates = updated);
  }

  void _setEnabled(int index, bool enabled) {
    final updated = List<_RateDraft>.of(_rates);
    updated[index] = updated[index].copyWith(enabled: enabled);
    setState(() => _rates = updated);
  }

  Future<void> _saveRates() async {
    final operations = _operations;
    final property = _property;
    if (operations == null || property == null) return;
    final invalid = _rates.where((rate) => rate.enabled && rate.amount <= 0);
    if (invalid.isNotEmpty) {
      locationSnack(context, 'Enter an amount for every enabled rate');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      for (final rate in _rates) {
        final body = {
          'label': rate.label,
          'amount_minor': rate.amount * 100,
          'currency': 'PKR',
          'unit': rate.unit,
          'enabled': rate.enabled,
          if (rate.conditions != null) 'conditions': rate.conditions,
        };
        if (rate.publicId == null) {
          await operations.createLocationPricing(
            property.publicId,
            body,
            refresh: false,
          );
        } else {
          await operations.updateLocationPricing(
            rate.publicId!,
            body,
            refresh: false,
          );
        }
      }
      final properties = await operations.locationProperties(force: true);
      final active = activeLocationProperty(properties);
      if (!mounted) return;
      setState(() {
        _property = active;
        _rates = _draftsFor(active);
      });
      locationSnack(context, 'Rate card saved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  _RateDraft _rate(String unit) =>
      _rates.firstWhere((rate) => rate.unit == unit);

  String _rateValue(_RateDraft rate) {
    return rate.enabled && rate.amount > 0
        ? locationMoney(rate.amount)
        : 'Not set';
  }
}

class _RateRow extends StatelessWidget {
  final _RateDraft rate;
  final VoidCallback onMinus;
  final VoidCallback onPlus;
  final ValueChanged<bool> onEnabled;

  const _RateRow({
    required this.rate,
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
                  rate.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  rate.amount > 0 ? locationMoney(rate.amount) : 'No amount',
                  style: AppTextStyles.statusText.copyWith(
                    color:
                        rate.enabled ? colors.goldDark : colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Decrease',
            onPressed: onMinus,
            icon: Icon(Icons.remove_circle_outline, color: colors.iconMuted),
          ),
          IconButton(
            tooltip: 'Increase',
            onPressed: onPlus,
            icon: Icon(Icons.add_circle_outline, color: colors.goldDark),
          ),
          Switch.adaptive(value: rate.enabled, onChanged: onEnabled),
        ],
      ),
    );
  }
}

class _RateDraft {
  final String? publicId;
  final String label;
  final String unit;
  final int amount;
  final bool enabled;
  final String? conditions;

  const _RateDraft({
    required this.publicId,
    required this.label,
    required this.unit,
    required this.amount,
    required this.enabled,
    required this.conditions,
  });

  _RateDraft copyWith({int? amount, bool? enabled}) {
    return _RateDraft(
      publicId: publicId,
      label: label,
      unit: unit,
      amount: amount ?? this.amount,
      enabled: enabled ?? this.enabled,
      conditions: conditions,
    );
  }
}
