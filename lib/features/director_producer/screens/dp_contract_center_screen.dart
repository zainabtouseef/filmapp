import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPContractCenterScreen extends StatefulWidget {
  const DPContractCenterScreen({super.key});

  @override
  State<DPContractCenterScreen> createState() => _DPContractCenterScreenState();
}

class _DPContractCenterScreenState extends State<DPContractCenterScreen> {
  Future<List<CineContract>>? _future;
  bool _generating = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final contracts = ContractsScope.maybeOf(context);
    if (contracts != null) _future ??= contracts.contracts(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.article_outlined,
          label: _generating ? 'Preparing wizard...' : 'Open contract wizard',
          onTap: _generating ? () {} : _openContractWizard,
        ),
        const SizedBox(height: 8),
        if (future == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in required',
            message: 'Connect a live Director account to view contracts.',
          )
        else
          FutureBuilder<List<CineContract>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const CoreEmptyState(
                  icon: Icons.hourglass_top_rounded,
                  title: 'Loading contracts',
                  message: 'Fetching live agreement records.',
                );
              }
              if (snapshot.hasError) {
                return CoreEmptyState(
                  icon: Icons.cloud_off_rounded,
                  title: 'Contracts unavailable',
                  message:
                      'Could not load live agreement records from the database. Check the API connection and try again.',
                  actionLabel: 'Retry',
                  onAction: _reload,
                );
              }
              final contracts = snapshot.data ?? const [];
              if (contracts.isEmpty) {
                return const CoreEmptyState(
                  icon: Icons.article_outlined,
                  title: 'No contracts yet',
                  message:
                      'Accept a booking and generate a contract to populate this center from the database.',
                );
              }
              return DPResponsiveGrid(
                minWidth: 310,
                children: [
                  for (final contract in contracts)
                    _ContractCard(
                      title: contract.title,
                      project: contract.projectId,
                      stakeholder: contract.counterpartySummary,
                      value: contract.displayValue,
                      status: contract.statusLabel,
                      progress: contract.signatureProgress,
                      date: contract.effectiveDate ?? 'Draft',
                      contractId: contract.publicId,
                      onRequestReview: () => _requestReview(contract),
                    ),
                ],
              );
            },
          ),
      ],
    );
  }

  void _reload() {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    setState(() => _future = contracts.contracts(force: true));
  }

  Future<void> _openContractWizard() async {
    final bookings = BookingsScope.maybeOf(context);
    final contracts = ContractsScope.maybeOf(context);
    if (bookings == null || contracts == null) {
      dpSnack(context, 'Sign in to generate live contracts');
      return;
    }
    setState(() => _generating = true);
    try {
      final rows = await bookings.bookings(force: true);
      final accepted = rows
          .where((row) => row.status == 'accepted' || row.status == 'secured')
          .toList();
      if (!mounted) return;
      setState(() => _generating = false);
      if (accepted.isEmpty) {
        dpSnack(context, 'No accepted booking ready for contract yet');
        return;
      }
      final generated = await showModalBottomSheet<CineContract>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        backgroundColor: Colors.transparent,
        builder: (sheetContext) => _ContractWizardSheet(
          bookings: accepted,
          contracts: contracts,
        ),
      );
      if (!mounted || generated == null) return;
      setState(() {
        _future = contracts.contracts(force: true);
      });
      Navigator.pushNamed(
        context,
        CoreRoutes.contract,
        arguments: generated.publicId,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _generating = false);
      dpSnack(context, '$error');
    }
  }

  Future<void> _requestReview(CineContract contract) async {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return;
    try {
      await contracts.requestLegalReview(contractId: contract.publicId);
      if (!mounted) return;
      dpSnack(context, 'Legal review requested');
    } catch (error) {
      if (!mounted) return;
      dpSnack(context, '$error');
    }
  }
}

class _ContractWizardSheet extends StatefulWidget {
  final List<Booking> bookings;
  final ContractsController contracts;

  const _ContractWizardSheet({
    required this.bookings,
    required this.contracts,
  });

  @override
  State<_ContractWizardSheet> createState() => _ContractWizardSheetState();
}

class _ContractWizardSheetState extends State<_ContractWizardSheet> {
  late Booking _booking = widget.bookings.first;
  int _step = 0;
  bool _saving = false;
  _ClauseChoice _shootType = _shootTypeChoices.first;
  _ClauseChoice _usageRights = _usageChoices.first;
  _ClauseChoice _cancellation = _cancellationChoices.first;
  _ClauseChoice _overtime = _overtimeChoices.first;
  final TextEditingController _specialTerms = TextEditingController();

  @override
  void dispose() {
    _specialTerms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    return Padding(
      padding: EdgeInsets.fromLTRB(12, 12, 12, bottomInset + 12),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1040),
        child: Align(
          alignment: Alignment.bottomCenter,
          child: Material(
            color: Colors.transparent,
            child: DPGlassCard(
              padding: const EdgeInsets.all(18),
              child: SizedBox(
                height: MediaQuery.sizeOf(context).height * 0.86,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: colors.goldGradient,
                          ),
                          child: Icon(
                            Icons.edit_document,
                            color: colors.onGold,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'In-app contract wizard',
                                style: AppTextStyles.sectionTitle.copyWith(
                                  color: colors.textPrimary,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Generate the live booking contract and attach variable clauses for shoot type, usage rights, cancellation and overtime.',
                                style: AppTextStyles.caption.copyWith(
                                  color: colors.textSecondary,
                                  height: 1.35,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          onPressed:
                              _saving ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _WizardStepChip(
                          label: '1. Booking',
                          active: _step == 0,
                          done: _step > 0,
                          onTap: () => setState(() => _step = 0),
                        ),
                        _WizardStepChip(
                          label: '2. Clauses',
                          active: _step == 1,
                          done: _step > 1,
                          onTap: () => setState(() => _step = 1),
                        ),
                        _WizardStepChip(
                          label: '3. Preview',
                          active: _step == 2,
                          done: false,
                          onTap: () => setState(() => _step = 2),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Expanded(
                      child: SingleChildScrollView(
                        child: AnimatedSwitcher(
                          duration: const Duration(milliseconds: 180),
                          child: switch (_step) {
                            0 => _BookingStep(
                                key: const ValueKey('booking'),
                                bookings: widget.bookings,
                                selected: _booking,
                                onSelected: (booking) =>
                                    setState(() => _booking = booking),
                              ),
                            1 => _ClausesStep(
                                key: const ValueKey('clauses'),
                                shootType: _shootType,
                                usageRights: _usageRights,
                                cancellation: _cancellation,
                                overtime: _overtime,
                                specialTerms: _specialTerms,
                                onShootType: (value) =>
                                    setState(() => _shootType = value),
                                onUsageRights: (value) =>
                                    setState(() => _usageRights = value),
                                onCancellation: (value) =>
                                    setState(() => _cancellation = value),
                                onOvertime: (value) =>
                                    setState(() => _overtime = value),
                              ),
                            _ => _PreviewStep(
                                key: const ValueKey('preview'),
                                booking: _booking,
                                clauses: _selectedClauses,
                                specialTerms: _specialTerms.text.trim(),
                              ),
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: DPHolographicButton(
                            label: _step == 0 ? 'Cancel' : 'Back',
                            icon: _step == 0
                                ? Icons.close_rounded
                                : Icons.arrow_back_rounded,
                            secondary: true,
                            onTap: _saving
                                ? null
                                : () {
                                    if (_step == 0) {
                                      Navigator.pop(context);
                                    } else {
                                      setState(() => _step -= 1);
                                    }
                                  },
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          flex: 2,
                          child: DPHolographicButton(
                            label: _saving
                                ? 'Generating contract...'
                                : _step == 2
                                    ? 'Generate contract'
                                    : 'Continue',
                            icon: _step == 2
                                ? Icons.verified_user_outlined
                                : Icons.arrow_forward_rounded,
                            onTap: _saving
                                ? null
                                : _step == 2
                                    ? _generate
                                    : () => setState(() => _step += 1),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<_ClauseChoice> get _selectedClauses => [
        _shootType,
        _usageRights,
        _cancellation,
        _overtime,
      ];

  Future<void> _generate() async {
    setState(() => _saving = true);
    try {
      final contract = await widget.contracts.generateForBooking(
        _booking.publicId,
      );
      await widget.contracts.createAddendum(
        contractId: contract.publicId,
        reason: 'Contract wizard variable clauses',
        content: _clausePack(contract),
      );
      if (!mounted) return;
      Navigator.pop(context, contract);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      dpSnack(context, '$error');
    }
  }

  String _clausePack(CineContract contract) {
    final terms = _specialTerms.text.trim();
    return [
      'CineConnect contract wizard clause pack',
      '',
      'Contract: ${contract.publicId}',
      'Booking: ${_booking.publicId}',
      'Project: ${_booking.projectTitle}',
      'Provider: ${_booking.provider.displayName}',
      'Booking value: ${_booking.currency} ${_shortMoney(_booking.agreedAmountMinor ?? 0)}',
      'Dates: ${_shortDate(_booking.startAt)} to ${_shortDate(_booking.endAt)}',
      '',
      for (final clause in _selectedClauses) ...[
        '${clause.title}: ${clause.label}',
        clause.body,
        '',
      ],
      if (terms.isNotEmpty) ...[
        'Special production terms:',
        terms,
        '',
      ],
      'This addendum was generated inside CineConnect and queued for legal review before final signature/reliance.',
    ].join('\n');
  }
}

class _WizardStepChip extends StatelessWidget {
  final String label;
  final bool active;
  final bool done;
  final VoidCallback onTap;

  const _WizardStepChip({
    required this.label,
    required this.active,
    required this.done,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 13),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(18),
          gradient: active ? colors.goldGradient : null,
          color: active
              ? null
              : colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.24),
          border: Border.all(color: active ? colors.goldMid : colors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              done ? Icons.check_circle_rounded : Icons.circle,
              size: done ? 16 : 7,
              color: active ? colors.onGold : colors.goldDark,
            ),
            const SizedBox(width: 7),
            Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: active ? colors.onGold : colors.textSecondary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BookingStep extends StatelessWidget {
  final List<Booking> bookings;
  final Booking selected;
  final ValueChanged<Booking> onSelected;

  const _BookingStep({
    super.key,
    required this.bookings,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DPResponsiveGrid(
      minWidth: 300,
      children: [
        for (final booking in bookings)
          _SelectableCard(
            selected: booking.publicId == selected.publicId,
            icon: Icons.movie_creation_outlined,
            title: booking.projectTitle,
            subtitle:
                '${booking.provider.displayName} • ${booking.category.replaceAll('_', ' ')}',
            body:
                '${booking.projectCity ?? 'City TBD'} • ${_shortDate(booking.startAt)} → ${_shortDate(booking.endAt)}',
            footer:
                '${booking.currency} ${_shortMoney(booking.agreedAmountMinor ?? 0)}',
            onTap: () => onSelected(booking),
          ),
      ],
    );
  }
}

class _ClausesStep extends StatelessWidget {
  final _ClauseChoice shootType;
  final _ClauseChoice usageRights;
  final _ClauseChoice cancellation;
  final _ClauseChoice overtime;
  final TextEditingController specialTerms;
  final ValueChanged<_ClauseChoice> onShootType;
  final ValueChanged<_ClauseChoice> onUsageRights;
  final ValueChanged<_ClauseChoice> onCancellation;
  final ValueChanged<_ClauseChoice> onOvertime;

  const _ClausesStep({
    super.key,
    required this.shootType,
    required this.usageRights,
    required this.cancellation,
    required this.overtime,
    required this.specialTerms,
    required this.onShootType,
    required this.onUsageRights,
    required this.onCancellation,
    required this.onOvertime,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        DPTwoColumn(
          left: Column(
            children: [
              _ChoiceGroup(
                title: 'Shoot type',
                icon: Icons.local_movies_outlined,
                choices: _shootTypeChoices,
                selected: shootType,
                onSelected: onShootType,
              ),
              const SizedBox(height: 12),
              _ChoiceGroup(
                title: 'Usage rights',
                icon: Icons.policy_outlined,
                choices: _usageChoices,
                selected: usageRights,
                onSelected: onUsageRights,
              ),
            ],
          ),
          right: Column(
            children: [
              _ChoiceGroup(
                title: 'Cancellation',
                icon: Icons.event_busy_outlined,
                choices: _cancellationChoices,
                selected: cancellation,
                onSelected: onCancellation,
              ),
              const SizedBox(height: 12),
              _ChoiceGroup(
                title: 'Overtime',
                icon: Icons.more_time_outlined,
                choices: _overtimeChoices,
                selected: overtime,
                onSelected: onOvertime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        TextField(
          controller: specialTerms,
          minLines: 3,
          maxLines: 5,
          decoration: InputDecoration(
            labelText: 'Special terms optional',
            hintText:
                'Example: wardrobe arrival time, product exclusivity, location confidentiality...',
            alignLabelWithHint: true,
            filled: true,
            fillColor:
                colors.surface.withValues(alpha: colors.isLight ? 0.72 : 0.22),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(18),
              borderSide: BorderSide(color: colors.border),
            ),
          ),
        ),
      ],
    );
  }
}

class _ChoiceGroup extends StatelessWidget {
  final String title;
  final IconData icon;
  final List<_ClauseChoice> choices;
  final _ClauseChoice selected;
  final ValueChanged<_ClauseChoice> onSelected;

  const _ChoiceGroup({
    required this.title,
    required this.icon,
    required this.choices,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return DPGlassCard(
      showAccent: false,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 18, color: context.appColors.goldDark),
              const SizedBox(width: 8),
              Text(
                title,
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final choice in choices) ...[
            _ChoiceTile(
              choice: choice,
              selected: choice.id == selected.id,
              onTap: () => onSelected(choice),
            ),
            if (choice != choices.last) const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }
}

class _ChoiceTile extends StatelessWidget {
  final _ClauseChoice choice;
  final bool selected;
  final VoidCallback onTap;

  const _ChoiceTile({
    required this.choice,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: selected
              ? colors.goldMid.withValues(alpha: 0.14)
              : colors.surface.withValues(alpha: colors.isLight ? 0.68 : 0.18),
          border: Border.all(
            color: selected ? colors.goldMid : colors.border,
          ),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(
              selected
                  ? Icons.radio_button_checked_rounded
                  : Icons.radio_button_unchecked_rounded,
              color: selected ? colors.goldDark : colors.textTertiary,
              size: 20,
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    choice.label,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    choice.body,
                    style: AppTextStyles.caption.copyWith(
                      color: colors.textSecondary,
                      height: 1.28,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PreviewStep extends StatelessWidget {
  final Booking booking;
  final List<_ClauseChoice> clauses;
  final String specialTerms;

  const _PreviewStep({
    super.key,
    required this.booking,
    required this.clauses,
    required this.specialTerms,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPTwoColumn(
      left: DPGlassCard(
        showAccent: false,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contract snapshot',
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            _PreviewRow(label: 'Project', value: booking.projectTitle),
            _PreviewRow(label: 'Provider', value: booking.provider.displayName),
            _PreviewRow(
              label: 'Type',
              value: booking.category.replaceAll('_', ' '),
            ),
            _PreviewRow(
              label: 'Dates',
              value:
                  '${_shortDate(booking.startAt)} → ${_shortDate(booking.endAt)}',
            ),
            _PreviewRow(
              label: 'Value',
              value:
                  '${booking.currency} ${_shortMoney(booking.agreedAmountMinor ?? 0)}',
            ),
            const SizedBox(height: 8),
            DPStatusChip(
              label: 'Legal review queued after generation',
              tone: DpTone.info,
              icon: Icons.gavel_outlined,
            ),
          ],
        ),
      ),
      right: DPGlassCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variable clauses',
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: 12),
            for (final clause in clauses) ...[
              _ClausePreview(choice: clause),
              if (clause != clauses.last) const SizedBox(height: 10),
            ],
            if (specialTerms.isNotEmpty) ...[
              const SizedBox(height: 10),
              _ClausePreview(
                choice: _ClauseChoice(
                  id: 'special_terms',
                  title: 'Special terms',
                  label: 'Custom producer note',
                  body: specialTerms,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _PreviewRow extends StatelessWidget {
  final String label;
  final String value;

  const _PreviewRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: AppTextStyles.caption.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: AppTextStyles.caption.copyWith(
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

class _ClausePreview extends StatelessWidget {
  final _ClauseChoice choice;

  const _ClausePreview({required this.choice});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        color: colors.surface.withValues(alpha: colors.isLight ? 0.7 : 0.18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            choice.title,
            style: AppTextStyles.micro.copyWith(color: colors.goldDark),
          ),
          const SizedBox(height: 4),
          Text(
            choice.label,
            style: AppTextStyles.caption.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            choice.body,
            style: AppTextStyles.caption.copyWith(
              color: colors.textSecondary,
              height: 1.28,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectableCard extends StatelessWidget {
  final bool selected;
  final IconData icon;
  final String title;
  final String subtitle;
  final String body;
  final String footer;
  final VoidCallback onTap;

  const _SelectableCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.body,
    required this.footer,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      selected: selected,
      onTap: onTap,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: colors.goldDark, size: 22),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              Icon(
                selected
                    ? Icons.check_circle_rounded
                    : Icons.radio_button_unchecked_rounded,
                color: selected ? colors.success : colors.textTertiary,
              ),
            ],
          ),
          const SizedBox(height: 7),
          Text(
            subtitle,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 4),
          Text(
            body,
            style: AppTextStyles.caption.copyWith(color: colors.textSecondary),
          ),
          const SizedBox(height: 10),
          DPStatusChip(label: footer, tone: DpTone.warning),
        ],
      ),
    );
  }
}

class _ClauseChoice {
  final String id;
  final String title;
  final String label;
  final String body;

  const _ClauseChoice({
    required this.id,
    required this.title,
    required this.label,
    required this.body,
  });
}

const _shootTypeChoices = [
  _ClauseChoice(
    id: 'shoot_tvc',
    title: 'Shoot type',
    label: 'TVC / digital commercial',
    body:
        'Provider attends scheduled commercial shoot days, rehearsals and brand-approved call times for the campaign.',
  ),
  _ClauseChoice(
    id: 'shoot_film_drama',
    title: 'Shoot type',
    label: 'Film / drama scene work',
    body:
        'Provider performs production scenes under director supervision, including continuity requirements and call-sheet updates.',
  ),
  _ClauseChoice(
    id: 'shoot_social',
    title: 'Shoot type',
    label: 'Social content / reels',
    body:
        'Provider creates short-form campaign content with agreed deliverables, posting windows and approval checkpoints.',
  ),
];

const _usageChoices = [
  _ClauseChoice(
    id: 'usage_3_months_pk',
    title: 'Usage rights',
    label: 'Pakistan digital, 3 months',
    body:
        'Usage is limited to Pakistan digital/social channels for three months from first publication unless extended in writing.',
  ),
  _ClauseChoice(
    id: 'usage_1_year_all_media_pk',
    title: 'Usage rights',
    label: 'Pakistan all-media, 1 year',
    body:
        'Usage is allowed across TV, digital, outdoor and print in Pakistan for one year from first release.',
  ),
  _ClauseChoice(
    id: 'usage_global_buyout',
    title: 'Usage rights',
    label: 'Global digital buyout',
    body:
        'Usage is granted for global digital campaign distribution, subject to agreed fee and brand/category exclusivity terms.',
  ),
];

const _cancellationChoices = [
  _ClauseChoice(
    id: 'cancel_48h',
    title: 'Cancellation',
    label: '48-hour producer cancellation window',
    body:
        'Producer may cancel or reschedule up to 48 hours before call time without penalty; late cancellation triggers a 50% fee.',
  ),
  _ClauseChoice(
    id: 'cancel_7_days',
    title: 'Cancellation',
    label: '7-day protected booking',
    body:
        'Cancellation inside seven days of the first shoot day triggers a 50% fee; cancellation inside 24 hours triggers full day fee.',
  ),
  _ClauseChoice(
    id: 'cancel_weather',
    title: 'Cancellation',
    label: 'Weather / force majeure reschedule',
    body:
        'Weather, permits, safety or force majeure events allow one no-penalty reschedule within the agreed production window.',
  ),
];

const _overtimeChoices = [
  _ClauseChoice(
    id: 'ot_hourly_15',
    title: 'Overtime',
    label: '1.5x hourly after agreed day',
    body:
        'Overtime begins after the agreed call duration and is billed at 1.5x the equivalent hourly booking rate.',
  ),
  _ClauseChoice(
    id: 'ot_fixed_25',
    title: 'Overtime',
    label: '25% half-day extension',
    body:
        'A production extension up to four hours is billed as 25% of the booking fee and requires provider confirmation.',
  ),
  _ClauseChoice(
    id: 'ot_preapproval',
    title: 'Overtime',
    label: 'Written pre-approval required',
    body:
        'No overtime is billable unless approved in writing by producer and provider before the scheduled wrap time.',
  ),
];

String _shortDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

String _shortMoney(int minor) {
  final amount = minor / 100;
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return amount.toStringAsFixed(0);
}

class _ContractCard extends StatelessWidget {
  final String title;
  final String project;
  final String stakeholder;
  final String value;
  final String status;
  final double progress;
  final String date;
  final String? contractId;
  final VoidCallback? onRequestReview;

  const _ContractCard({
    required this.title,
    required this.project,
    required this.stakeholder,
    required this.value,
    required this.status,
    required this.progress,
    required this.date,
    required this.contractId,
    required this.onRequestReview,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = status == 'Signed'
        ? DpTone.success
        : status == 'Cancelled'
            ? DpTone.danger
            : status == 'Addendums'
                ? DpTone.info
                : DpTone.warning;
    return DPGlassCard(
      selected: status == 'Pending Signature',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: dpText(context, title, strong: true)),
              DPStatusChip(label: status, tone: tone),
            ],
          ),
          const SizedBox(height: 6),
          dpText(context, '$project - $stakeholder'),
          const SizedBox(height: 9),
          LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            borderRadius: BorderRadius.circular(99),
            backgroundColor: colors.surface.withValues(alpha: 0.28),
            valueColor: AlwaysStoppedAnimation<Color>(colors.goldMid),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text(
                value,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              DPStatusChip(label: date, tone: DpTone.neutral),
            ],
          ),
          const SizedBox(height: 9),
          DPHolographicButton(
            label: 'Open Contract',
            icon: Icons.open_in_new_rounded,
            onTap: () => Navigator.pushNamed(
              context,
              CoreRoutes.contract,
              arguments: contractId,
            ),
            secondary: true,
          ),
          if (contractId != null) ...[
            const SizedBox(height: 8),
            DPHolographicButton(
              label: 'Request Legal Review',
              icon: Icons.gavel_outlined,
              onTap: onRequestReview,
              secondary: true,
            ),
          ],
        ],
      ),
    );
  }
}
