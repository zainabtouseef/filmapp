import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/actor_talent_models.dart';
import '../widgets/actor_talent_components.dart';

/// AT-10 Earnings & Payment Security
class AT10EarningsSecurityScreen extends StatefulWidget {
  const AT10EarningsSecurityScreen({super.key});

  @override
  State<AT10EarningsSecurityScreen> createState() =>
      _AT10EarningsSecurityScreenState();
}

class _AT10EarningsSecurityScreenState
    extends State<AT10EarningsSecurityScreen> {
  Future<PaymentDashboardDto>? _dashboardFuture;
  Future<List<PayoutAccountDto>>? _accountsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    if (payments != null) {
      _dashboardFuture ??= payments.dashboard(force: true);
      _accountsFuture ??= _safePayoutAccounts(payments);
    }
  }

  Future<List<PayoutAccountDto>> _safePayoutAccounts(
    PaymentsController payments,
  ) async {
    try {
      return await payments.payoutAccounts();
    } catch (_) {
      return const [];
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_dashboardFuture != null) {
      return FutureBuilder<PaymentDashboardDto>(
        future: _dashboardFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const CoreEmptyState(
              icon: Icons.hourglass_top_rounded,
              title: 'Loading earnings',
              message: 'Fetching protected payment balances.',
            );
          }
          if (!snapshot.hasError && snapshot.data != null) {
            return _LiveEarnings(
              dashboard: snapshot.data!,
              accountsFuture: _accountsFuture,
              onCreateAccount: _createPayoutAccount,
            );
          }
          return _EarningsLoadError(onRetry: _refresh);
        },
      );
    }
    return const ActorSectionCard(
      title: 'Earnings',
      icon: Icons.account_balance_wallet_outlined,
      tone: ActorTone.blue,
      child: CoreEmptyState(
        icon: Icons.lock_outline_rounded,
        title: 'Sign in to view live earnings',
        message:
            'Payment schedules, payout accounts, and ledger balances are loaded from the server.',
      ),
    );
  }

  Future<void> _createPayoutAccount() async {
    final payments = PaymentsScope.maybeOf(context);
    if (payments == null) return;
    final draft = await showDialog<_PayoutAccountDraft>(
      context: context,
      builder: (_) => const _PayoutAccountDialog(),
    );
    if (draft == null || !mounted) return;
    try {
      await payments.createPayoutAccount(
        provider: draft.provider,
        accountName: draft.accountName,
        accountIdentifier: draft.accountIdentifier,
      );
      if (!mounted) return;
      setState(() => _accountsFuture = _safePayoutAccounts(payments));
      actorSnack(context, 'Payout account submitted for verification');
    } catch (error) {
      if (!mounted) return;
      actorSnack(context, '$error');
    }
  }

  void _refresh() {
    final payments = PaymentsScope.maybeOf(context);
    if (payments == null) return;
    setState(() {
      _dashboardFuture = payments.dashboard(force: true);
      _accountsFuture = _safePayoutAccounts(payments);
    });
  }
}

class _LiveEarnings extends StatelessWidget {
  final PaymentDashboardDto dashboard;
  final Future<List<PayoutAccountDto>>? accountsFuture;
  final Future<void> Function() onCreateAccount;

  const _LiveEarnings({
    required this.dashboard,
    required this.accountsFuture,
    required this.onCreateAccount,
  });

  @override
  Widget build(BuildContext context) {
    final pending = dashboard.pendingReleaseMinor ~/ 100;
    final received = dashboard.creditMinor ~/ 100;
    return Column(
      children: [
        ActorSectionCard(
          title: 'Money Safe Summary',
          icon: Icons.account_balance_wallet_outlined,
          selected: pending > 0,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'PKR $received',
                style: AppTextStyles.metricNumber.copyWith(
                  color: context.appColors.textPrimary,
                  fontSize: 34,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Verified talent ledger credits from CineConnect.',
                style: AppTextStyles.smallMeta.copyWith(
                  color: context.appColors.textSecondary,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: 'Pending release PKR $pending',
                    color: pending > 0
                        ? context.appColors.goldMid
                        : context.appColors.success,
                  ),
                  StatusChip(
                    label: '${dashboard.schedules.length} schedules',
                    color: context.appColors.infoBlue,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        ActorTwoColumn(
          left: ActorSectionCard(
            title: 'Payment Timeline',
            icon: Icons.timeline_outlined,
            child: Column(
              children: [
                if (dashboard.schedules.isEmpty)
                  const CoreEmptyState(
                    icon: Icons.payments_outlined,
                    title: 'No payment schedule',
                    message:
                        'Payment milestones appear after a contract is secured.',
                  )
                else
                  for (final schedule in dashboard.schedules)
                    for (final milestone in schedule.milestones)
                      ActorInfoRow(
                        icon: Icons.payments_outlined,
                        label: milestone.status,
                        value:
                            '${schedule.bookingId} • ${milestone.name} • ${milestone.amountLabel}',
                      ),
              ],
            ),
          ),
          right: ActorSectionCard(
            title: 'Security Actions',
            icon: Icons.verified_user_outlined,
            child: Column(
              children: [
                FutureBuilder<List<PayoutAccountDto>>(
                  future: accountsFuture,
                  builder: (context, snapshot) {
                    final accounts = snapshot.data ?? const [];
                    return ActorInfoRow(
                      icon: Icons.account_balance_outlined,
                      label: 'Payout account',
                      value: accounts.isEmpty
                          ? 'None'
                          : '${accounts.first.accountName} ${accounts.first.accountMasked}',
                    );
                  },
                ),
                const SizedBox(height: 8),
                CorePrimaryButton(
                  icon: Icons.account_balance_outlined,
                  label: 'Add payout account',
                  compact: true,
                  onTap: () => onCreateAccount(),
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.receipt_long_outlined,
                  label: 'Open receipts',
                  compact: true,
                  onTap: () => Navigator.pushNamed(context, CoreRoutes.ledger),
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.report_gmailerrorred_outlined,
                  label: 'Raise issue',
                  compact: true,
                  onTap: () => Navigator.pushNamed(context, CoreRoutes.report),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _PayoutAccountDraft {
  final String provider;
  final String accountName;
  final String accountIdentifier;

  const _PayoutAccountDraft({
    required this.provider,
    required this.accountName,
    required this.accountIdentifier,
  });
}

class _PayoutAccountDialog extends StatefulWidget {
  const _PayoutAccountDialog();

  @override
  State<_PayoutAccountDialog> createState() => _PayoutAccountDialogState();
}

class _PayoutAccountDialogState extends State<_PayoutAccountDialog> {
  final _formKey = GlobalKey<FormState>();
  final _accountName = TextEditingController();
  final _identifier = TextEditingController();
  String _provider = 'bank';

  @override
  void dispose() {
    _accountName.dispose();
    _identifier.dispose();
    super.dispose();
  }

  void _save() {
    if (!_formKey.currentState!.validate()) return;
    Navigator.pop(
      context,
      _PayoutAccountDraft(
        provider: _provider,
        accountName: _accountName.text.trim(),
        accountIdentifier: _identifier.text.trim(),
      ),
    );
  }

  String? _validateIdentifier(String? value) {
    final compact = (value ?? '').replaceAll(
      RegExp(r'[^A-Za-z0-9]'),
      '',
    );
    return compact.length < 4 ? 'Enter a valid account identifier' : null;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add payout account'),
      content: SizedBox(
        width: 460,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: _provider,
                decoration: const InputDecoration(
                  labelText: 'Account type',
                  prefixIcon: Icon(Icons.account_balance_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'bank',
                    child: Text('Bank account'),
                  ),
                  DropdownMenuItem(
                    value: 'wallet',
                    child: Text('Mobile wallet'),
                  ),
                ],
                onChanged: (value) {
                  if (value != null) setState(() => _provider = value);
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _accountName,
                decoration: const InputDecoration(
                  labelText: 'Account holder name',
                  prefixIcon: Icon(Icons.person_outline_rounded),
                ),
                validator: (value) => (value?.trim().length ?? 0) < 2
                    ? 'Enter the account holder name'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifier,
                decoration: InputDecoration(
                  labelText: _provider == 'bank'
                      ? 'IBAN / account number'
                      : 'Wallet number',
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  helperText:
                      'Stored encrypted. Only the final four characters are displayed.',
                ),
                validator: _validateIdentifier,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton.icon(
          onPressed: _save,
          icon: const Icon(Icons.verified_user_outlined),
          label: const Text('Submit account'),
        ),
      ],
    );
  }
}

class _EarningsLoadError extends StatelessWidget {
  final VoidCallback onRetry;

  const _EarningsLoadError({required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Earnings unavailable',
      icon: Icons.cloud_off_outlined,
      tone: ActorTone.danger,
      child: Column(
        children: [
          const CoreEmptyState(
            icon: Icons.sync_problem_outlined,
            title: 'Could not load payment records',
            message: 'Check your connection and try again.',
          ),
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: Icons.refresh_rounded,
            label: 'Try again',
            compact: true,
            onTap: onRetry,
          ),
        ],
      ),
    );
  }
}
