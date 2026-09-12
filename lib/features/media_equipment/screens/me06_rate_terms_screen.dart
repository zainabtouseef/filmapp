import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../../shared/widgets/marketplace_pricing_preference_panel.dart';
import '../widgets/media_equipment_components.dart';

class ME06RateTermsScreen extends StatefulWidget {
  const ME06RateTermsScreen({super.key});

  @override
  State<ME06RateTermsScreen> createState() => _ME06RateTermsScreenState();
}

class _ME06RateTermsScreenState extends State<ME06RateTermsScreen> {
  Future<List<EquipmentTermDto>>? _termsFuture;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_termsFuture != null) return;
    _reload();
  }

  void _reload() {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    _termsFuture = operations.equipmentTerms(force: true);
  }

  @override
  Widget build(BuildContext context) {
    if (_termsFuture == null) {
      return const InlineNotice(
        message: 'Preview mode. Sign in to manage rental terms.',
        icon: Icons.visibility_outlined,
      );
    }
    return FutureBuilder<List<EquipmentTermDto>>(
      future: _termsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const InlineNotice(
            message: 'Loading rates and rental terms...',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return InlineNotice(
            message: 'Could not load rental terms: ${snapshot.error}',
            icon: Icons.cloud_off_outlined,
          );
        }
        final terms = snapshot.data ?? const [];
        final deposit = _firstOfType(terms, 'deposit');
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const MarketplacePricingPreferencePanel(
              listingTypes: {'equipment'},
              title: 'Equipment marketplace pricing',
            ),
            const SizedBox(height: 12),
            MetricActionRail(
              items: [
                MetricActionItem(
                  value: '${terms.where((item) => item.enabled).length}',
                  icon: Icons.check_circle_outline,
                  title: 'Enabled terms',
                  subtitle: 'Live',
                  accentColor: context.appColors.success,
                ),
                MetricActionItem(
                  value: deposit == null
                      ? 'Not set'
                      : mediaMoney(deposit.amountMinor ~/ 100),
                  icon: Icons.verified_user_outlined,
                  title: 'Deposit',
                  subtitle: deposit?.enabled == true ? 'Required' : 'Disabled',
                  accentColor: context.appColors.goldMid,
                ),
                MetricActionItem(
                  value: terms.isEmpty ? 'Setup' : 'Synced',
                  icon: Icons.rule_folder_outlined,
                  title: 'Contract rules',
                  subtitle: 'Live',
                  accentColor: context.appColors.infoBlue,
                ),
              ],
            ),
            const SizedBox(height: 12),
            MediaTwoColumn(
              left: MediaSectionCard(
                title: 'Rates & Terms',
                icon: Icons.rule_folder_outlined,
                selected: true,
                child: terms.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.rule_folder_outlined,
                        title: 'No rental terms',
                        message:
                            'Add daily rates, deposits, overtime, transport, cancellation, and late return rules.',
                        actionLabel: 'Add first term',
                        onAction: _showEditor,
                      )
                    : Column(
                        children: [
                          for (final term in terms)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _LiveTermRow(
                                term: term,
                                busy: _busyId == term.publicId,
                                onAmount: (amountMinor) => _update(
                                  term,
                                  {'amount_minor': amountMinor},
                                ),
                                onEnabled: (enabled) =>
                                    _update(term, {'enabled': enabled}),
                                onEdit: () => _showEditor(term),
                              ),
                            ),
                        ],
                      ),
              ),
              right: Column(
                children: [
                  MediaSectionCard(
                    title: 'Contract Coverage',
                    icon: Icons.policy_outlined,
                    child: const Column(
                      children: [
                        MediaInfoRow(
                          icon: Icons.schedule_outlined,
                          label: 'Rental duration',
                          value: 'Define day and overtime rules',
                        ),
                        MediaInfoRow(
                          icon: Icons.local_shipping_outlined,
                          label: 'Logistics',
                          value: 'Clarify pickup, delivery, and fuel',
                        ),
                        MediaInfoRow(
                          icon: Icons.health_and_safety_outlined,
                          label: 'Liability',
                          value: 'Deposit and damage inspection',
                        ),
                        MediaInfoRow(
                          icon: Icons.cancel_outlined,
                          label: 'Cancellation',
                          value: 'Set notice and applicable fee',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  MediaSectionCard(
                    title: 'Term Actions',
                    icon: Icons.tune_outlined,
                    child: Column(
                      children: [
                        CorePrimaryButton(
                          icon: Icons.add_rounded,
                          label: 'Add rental term',
                          compact: true,
                          onTap: _showEditor,
                        ),
                        const SizedBox(height: 8),
                        const InlineNotice(
                          message:
                              'Enabled terms are attached to new equipment negotiations and contract drafts.',
                          icon: Icons.info_outline,
                          tone: CoreStatusTone.info,
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

  EquipmentTermDto? _firstOfType(
    List<EquipmentTermDto> values,
    String type,
  ) {
    for (final term in values) {
      if (term.termType == type) return term;
    }
    return null;
  }

  Future<void> _update(
    EquipmentTermDto term,
    Map<String, dynamic> body,
  ) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    setState(() => _busyId = term.publicId);
    try {
      await operations.updateEquipmentTerm(term.publicId, body);
      if (!mounted) return;
      setState(_reload);
      mediaSnack(context, '${term.label} updated');
    } catch (error) {
      if (mounted) mediaSnack(context, 'Could not update term: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showEditor([EquipmentTermDto? term]) {
    final label = TextEditingController(text: term?.label ?? '');
    final note = TextEditingController(text: term?.note ?? '');
    final amount = TextEditingController(
      text: term == null ? '' : '${term.amountMinor ~/ 100}',
    );
    var type = term?.termType ?? 'daily_rate';
    var enabled = term?.enabled ?? true;
    showMediaSheet(
      context,
      title: term == null ? 'Add rental term' : 'Edit rental term',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoreTextField(
                controller: label,
                label: 'Term label',
                icon: Icons.sell_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: note,
                label: 'Contract explanation',
                icon: Icons.notes_outlined,
                maxLines: 3,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: amount,
                label: 'Amount in PKR',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text(
                'Term type',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    'daily_rate',
                    'operator',
                    'assistant',
                    'transport',
                    'overtime',
                    'deposit',
                    'late_fee',
                    'cancellation',
                  ])
                    CoreChip(
                      label: _title(value),
                      selected: type == value,
                      onTap: () => setSheetState(() => type = value),
                    ),
                ],
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enabled for new bookings'),
                value: enabled,
                onChanged: (value) => setSheetState(() => enabled = value),
              ),
              const SizedBox(height: 10),
              CorePrimaryButton(
                icon: Icons.save_outlined,
                label: 'Save rental term',
                onTap: () async {
                  final amountPkr = int.tryParse(amount.text.trim());
                  if (label.text.trim().length < 2 ||
                      amountPkr == null ||
                      amountPkr < 0) {
                    mediaSnack(context, 'Enter a label and valid amount');
                    return;
                  }
                  final operations = OperationsScope.maybeOf(context);
                  if (operations == null) return;
                  final body = {
                    'label': label.text.trim(),
                    'note': note.text.trim(),
                    'amount_minor': amountPkr * 100,
                    'currency': 'PKR',
                    'enabled': enabled,
                    'term_type': type,
                  };
                  try {
                    if (term == null) {
                      await operations.createEquipmentTerm(body);
                    } else {
                      await operations.updateEquipmentTerm(
                        term.publicId,
                        body,
                      );
                    }
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    mediaSnack(this.context, 'Rental term saved');
                  } catch (error) {
                    if (context.mounted) {
                      mediaSnack(context, 'Could not save term: $error');
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
      note.dispose();
      amount.dispose();
    });
  }
}

class _LiveTermRow extends StatelessWidget {
  final EquipmentTermDto term;
  final bool busy;
  final ValueChanged<int> onAmount;
  final ValueChanged<bool> onEnabled;
  final VoidCallback onEdit;

  const _LiveTermRow({
    required this.term,
    required this.busy,
    required this.onAmount,
    required this.onEnabled,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final amountPkr = term.amountMinor ~/ 100;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(_termIcon(term.termType), color: colors.goldDark, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      term.label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      term.note.isEmpty ? _title(term.termType) : term.note,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: term.enabled,
                onChanged: busy ? null : onEnabled,
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              StatusChip(
                label: mediaMoney(amountPkr),
                color: term.enabled ? colors.goldMid : colors.textSecondary,
              ),
              const Spacer(),
              IconButton(
                tooltip: 'Decrease by PKR 5,000',
                onPressed: busy
                    ? null
                    : () => onAmount(
                          ((amountPkr - 5000).clamp(0, 9999999)) * 100,
                        ),
                icon: const Icon(Icons.remove_circle_outline),
              ),
              IconButton(
                tooltip: 'Increase by PKR 5,000',
                onPressed:
                    busy ? null : () => onAmount((amountPkr + 5000) * 100),
                icon: const Icon(Icons.add_circle_outline),
              ),
              IconButton(
                tooltip: 'Edit term',
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _termIcon(String type) {
  return switch (type) {
    'operator' || 'assistant' => Icons.engineering_outlined,
    'transport' => Icons.local_shipping_outlined,
    'overtime' => Icons.more_time_outlined,
    'deposit' => Icons.verified_user_outlined,
    'cancellation' => Icons.cancel_outlined,
    _ => Icons.receipt_long_outlined,
  };
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
