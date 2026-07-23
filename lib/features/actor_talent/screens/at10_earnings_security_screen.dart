import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
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
    return _DemoEarnings();
  }

  Future<void> _createPayoutAccount() async {
    final payments = PaymentsScope.maybeOf(context);
    if (payments == null) return;
    try {
      await payments.createSandboxPayoutAccount(
        accountName: 'CineConnect test account',
      );
      if (!mounted) return;
      setState(() => _accountsFuture = _safePayoutAccounts(payments));
      actorSnack(context, 'Test payout account added');
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
                  label: 'Add test payout account',
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

class _DemoEarnings extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        return Column(
          children: [
            ActorSectionCard(
              title: 'Money Safe Summary',
              icon: Icons.account_balance_wallet_outlined,
              selected: !store.receiptConfirmed,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'PKR 1,240,000',
                    style: AppTextStyles.metricNumber.copyWith(
                      color: context.appColors.textPrimary,
                      fontSize: 34,
                      fontFeatures: const [FontFeature.tabularFigures()],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Total protected talent earnings in demo state.',
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
                        label: store.receiptConfirmed
                            ? 'Receipt confirmed'
                            : 'Confirm deposit',
                        color: store.receiptConfirmed
                            ? context.appColors.success
                            : context.appColors.goldMid,
                      ),
                      StatusChip(
                        label:
                            store.paymentIssueOpen ? 'Issue open' : 'No issue',
                        color: store.paymentIssueOpen
                            ? context.appColors.danger
                            : context.appColors.infoBlue,
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
                    for (final (i, item)
                        in ActorTalentDemoData.payments.indexed)
                      _PaymentRow(
                        item: item,
                        showDivider:
                            i != ActorTalentDemoData.payments.length - 1,
                      ),
                  ],
                ),
              ),
              right: ActorSectionCard(
                title: 'Security Actions',
                icon: Icons.verified_user_outlined,
                child: Column(
                  children: [
                    CorePrimaryButton(
                      icon: Icons.check_circle_outline,
                      label: 'I received payment',
                      compact: true,
                      onTap: store.receiptConfirmed
                          ? null
                          : () {
                              store.confirmReceipt();
                              actorSnack(context, 'Receipt confirmation saved');
                            },
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Open receipts',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.ledger),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.report_gmailerrorred_outlined,
                      label: 'Raise issue',
                      compact: true,
                      onTap: () => _issueSheet(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  void _issueSheet(BuildContext context) {
    showActorSheet(
      context,
      title: 'Raise payment issue',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'This opens a demo dispute and notifies admin payment verification.',
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.report_outlined,
            label: 'Open dispute',
            compact: true,
            onTap: () {
              ActorTalentDemoStore.instance.raisePaymentIssue();
              Navigator.pop(context);
              Navigator.pushNamed(context, CoreRoutes.report);
            },
          ),
        ],
      ),
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

class _PaymentRow extends StatelessWidget {
  final ActorPaymentMilestone item;
  final bool showDivider;

  const _PaymentRow({required this.item, this.showDivider = true});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 9),
      decoration: BoxDecoration(
        border: showDivider
            ? Border(bottom: BorderSide(color: colors.borderMuted))
            : null,
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              Text(
                item.amount,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w900,
                  fontFeatures: const [FontFeature.tabularFigures()],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Due ${item.dueDate}',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ),
              Flexible(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: StatusChip(
                    label: ActorTalentDemoData.statusLabel(item.status),
                    color: actorStatusColor(context, item.status),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
