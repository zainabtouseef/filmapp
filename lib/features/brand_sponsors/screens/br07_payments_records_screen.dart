import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../models/brand_sponsor_models.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR07PaymentsRecordsScreen extends StatefulWidget {
  const BR07PaymentsRecordsScreen({super.key});

  @override
  State<BR07PaymentsRecordsScreen> createState() =>
      _BR07PaymentsRecordsScreenState();
}

class _BR07PaymentsRecordsScreenState extends State<BR07PaymentsRecordsScreen> {
  SpecialistController? _specialist;
  PaymentsController? _payments;
  BrandProfileDto? _profile;
  PaymentDashboardDto? _dashboard;
  List<LedgerEntryDto> _ledger = const [];
  List<BrandApplicationDto> _applications = const [];
  String _filter = 'All';
  String _query = '';
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    if (identical(specialist, _specialist) && identical(payments, _payments)) {
      return;
    }
    _specialist = specialist;
    _payments = payments;
    if (specialist != null || payments != null) _load();
  }

  Future<void> _load({bool force = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      BrandProfileDto? profile;
      List<BrandApplicationDto> applications = const [];
      if (_specialist != null) {
        profile = await _specialist!.brandProfile(force: force);
        if (profile != null) {
          applications =
              await _specialist!.ownerBrandApplications(force: force);
        }
      }
      PaymentDashboardDto? dashboard;
      List<LedgerEntryDto> ledger = const [];
      if (_payments != null) {
        final values = await Future.wait<Object>([
          _payments!.dashboard(force: force),
          _payments!.ledger(force: force),
        ]);
        dashboard = values[0] as PaymentDashboardDto;
        ledger = values[1] as List<LedgerEntryDto>;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _dashboard = dashboard;
        _ledger = ledger;
        _applications = applications;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_specialist == null && _payments == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load finance records',
        message:
            'Payment schedules, milestones, ledger entries and accepted rights records are loaded from the backend.',
      );
    }
    if (_loading && !_loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && !_loaded) {
      return CoreEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Finance records unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_specialist != null && _profile == null) {
      return CoreEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Brand profile required',
        message:
            'Create the organization profile before managing sponsorship finances.',
        actionLabel: 'Create profile',
        onAction: () => Navigator.pushNamed(context, '/brand/profile'),
      );
    }

    final milestones = _visibleMilestones();
    final allMilestones = _allMilestones;
    final pendingCount = allMilestones
        .where((item) => _pendingStatuses.contains(item.milestone.status))
        .length;
    final releasedCount = allMilestones
        .where((item) => _releasedStatuses.contains(item.milestone.status))
        .length;
    final accepted =
        _applications.where((item) => item.status == 'accepted').toList();
    final debit = _dashboard?.debitMinor ?? 0;
    final pendingRelease = _dashboard?.pendingReleaseMinor ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        MetricActionRail(
          items: [
            MetricActionItem(
              value: brandMoney(debit),
              icon: Icons.account_balance_wallet_outlined,
              title: 'Recorded spend',
              subtitle: '${_ledger.length} ledger entries',
              accentColor: context.appColors.success,
            ),
            MetricActionItem(
              value: brandMoney(pendingRelease),
              icon: Icons.pending_actions_outlined,
              title: 'Pending release',
              subtitle: '$pendingCount milestones',
              accentColor: context.appColors.goldDark,
            ),
            MetricActionItem(
              value: '$releasedCount',
              icon: Icons.verified_outlined,
              title: 'Released milestones',
              subtitle: '${allMilestones.length} total',
              accentColor: context.appColors.infoBlue,
            ),
            MetricActionItem(
              value: '${accepted.length}',
              icon: Icons.policy_outlined,
              title: 'Accepted deals',
              subtitle: 'Rights records',
              accentColor: context.appColors.infoPurple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        BrandTwoColumn(
          left: BrandSectionCard(
            title: 'Payment milestones',
            icon: Icons.account_tree_outlined,
            selected: true,
            actionText: _loading ? 'Loading' : 'Refresh',
            onActionTap: _loading ? null : _load,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                BrandSearchField(
                  hintText: 'Search milestone, booking or status',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in const [
                        'All',
                        'Due',
                        'Pending verification',
                        'Released',
                        'Issue',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CoreChip(
                            label: filter,
                            selected: _filter == filter,
                            onTap: () => setState(() => _filter = filter),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (milestones.isEmpty)
                  CoreEmptyState(
                    icon: allMilestones.isEmpty
                        ? Icons.payments_outlined
                        : Icons.search_off_rounded,
                    title: allMilestones.isEmpty
                        ? 'No payment schedules'
                        : 'No matching milestones',
                    message: allMilestones.isEmpty
                        ? 'Contract payment schedules will appear here.'
                        : 'Change the payment status or search filter.',
                    actionLabel:
                        allMilestones.isEmpty ? 'Open ledger' : 'Clear filters',
                    onAction: allMilestones.isEmpty
                        ? () => Navigator.pushNamed(context, CoreRoutes.ledger)
                        : () => setState(() {
                              _filter = 'All';
                              _query = '';
                            }),
                  )
                else
                  for (final row in milestones)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LivePaymentRow(
                        row: row,
                        onPay: _payableStatuses.contains(row.milestone.status)
                            ? () => Navigator.pushNamed(
                                  context,
                                  CoreRoutes.paymentProof,
                                  arguments: row.milestone.publicId,
                                )
                            : null,
                        onLedger: () =>
                            Navigator.pushNamed(context, CoreRoutes.ledger),
                        onIssue: () => Navigator.pushNamed(
                          context,
                          CoreRoutes.report,
                          arguments: {
                            'reason': 'Brand payment issue',
                            'entity_type': 'payment_milestone',
                            'entity_id': row.milestone.publicId,
                          },
                        ),
                      ),
                    ),
              ],
            ),
          ),
          right: Column(
            children: [
              BrandSectionCard(
                title: 'Accepted usage rights',
                icon: Icons.policy_outlined,
                tone: BrandTone.purple,
                child: accepted.isEmpty
                    ? Text(
                        'No accepted sponsorship terms are on record.',
                        style: AppTextStyles.body.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      )
                    : Column(
                        children: [
                          for (final application in accepted.take(4))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _UsageRightsRow(
                                application: application,
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Recent ledger',
                icon: Icons.receipt_long_outlined,
                tone: BrandTone.green,
                actionText: 'View all',
                onActionTap: () =>
                    Navigator.pushNamed(context, CoreRoutes.ledger),
                child: _ledger.isEmpty
                    ? Text(
                        'No ledger entries have been recorded.',
                        style: AppTextStyles.body.copyWith(
                          color: context.appColors.textSecondary,
                        ),
                      )
                    : Column(
                        children: [
                          for (final entry in _ledger.take(5))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _LedgerRow(entry: entry),
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

  static const _payableStatuses = {
    'due',
    'not_paid',
    'pending',
    'rejected',
  };
  static const _pendingStatuses = {
    'pending',
    'pending_verification',
    'pending_release',
  };
  static const _releasedStatuses = {
    'paid',
    'verified',
    'released',
    'completed',
  };
  static const _issueStatuses = {
    'disputed',
    'rejected',
    'failed',
  };

  List<_MilestoneRecord> get _allMilestones {
    final rows = <_MilestoneRecord>[];
    for (final schedule in _dashboard?.schedules ?? const []) {
      for (final milestone in schedule.milestones) {
        rows.add(_MilestoneRecord(schedule: schedule, milestone: milestone));
      }
    }
    rows.sort((a, b) {
      final left = a.milestone.dueAt ?? DateTime(9999);
      final right = b.milestone.dueAt ?? DateTime(9999);
      return left.compareTo(right);
    });
    return rows;
  }

  List<_MilestoneRecord> _visibleMilestones() {
    final lower = _query.trim().toLowerCase();
    return _allMilestones.where((row) {
      final status = row.milestone.status;
      final matchesFilter = switch (_filter) {
        'Due' => _payableStatuses.contains(status),
        'Pending verification' => _pendingStatuses.contains(status),
        'Released' => _releasedStatuses.contains(status),
        'Issue' => _issueStatuses.contains(status),
        _ => true,
      };
      final haystack = [
        row.milestone.name,
        row.schedule.bookingId,
        row.schedule.publicId,
        readableBrandStatus(status),
      ].join(' ').toLowerCase();
      return matchesFilter && (lower.isEmpty || haystack.contains(lower));
    }).toList();
  }
}

class _MilestoneRecord {
  final PaymentScheduleDto schedule;
  final PaymentMilestoneDto milestone;

  const _MilestoneRecord({
    required this.schedule,
    required this.milestone,
  });
}

class _LivePaymentRow extends StatelessWidget {
  final _MilestoneRecord row;
  final VoidCallback? onPay;
  final VoidCallback onLedger;
  final VoidCallback onIssue;

  const _LivePaymentRow({
    required this.row,
    this.onPay,
    required this.onLedger,
    required this.onIssue,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(11),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _statusColor(context).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(7),
                ),
                child: Icon(
                  Icons.payments_outlined,
                  color: _statusColor(context),
                  size: 20,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  row.milestone.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              CardMenu<String>(
                items: [
                  if (onPay != null)
                    const CardMenuItem(
                      value: 'pay',
                      label: 'Submit payment proof',
                      icon: Icons.upload_file_outlined,
                    ),
                  const CardMenuItem(
                    value: 'ledger',
                    label: 'Open ledger',
                    icon: Icons.receipt_long_outlined,
                  ),
                  const CardMenuItem(
                    value: 'issue',
                    label: 'Report issue',
                    icon: Icons.report_problem_outlined,
                  ),
                ],
                onSelected: (value) {
                  if (value == 'pay') onPay?.call();
                  if (value == 'ledger') onLedger();
                  if (value == 'issue') onIssue();
                },
              ),
            ],
          ),
          const SizedBox(height: 9),
          BrandInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Booking',
            value: row.schedule.bookingId,
          ),
          BrandInfoRow(
            icon: Icons.event_outlined,
            label: 'Due',
            value: brandDate(
              row.milestone.dueAt,
              fallback: 'No due date',
            ),
          ),
          BrandInfoRow(
            icon: Icons.payments_outlined,
            label: 'Amount',
            value: brandMoney(
              row.milestone.amountMinor,
              currency: row.schedule.currency,
            ),
          ),
          Align(
            alignment: Alignment.centerRight,
            child: BrandLiveStatusChip(status: row.milestone.status),
          ),
        ],
      ),
    );
  }

  Color _statusColor(BuildContext context) {
    final status = row.milestone.status;
    if (_BR07PaymentsRecordsScreenState._releasedStatuses.contains(status)) {
      return context.appColors.success;
    }
    if (_BR07PaymentsRecordsScreenState._issueStatuses.contains(status)) {
      return context.appColors.danger;
    }
    if (_BR07PaymentsRecordsScreenState._pendingStatuses.contains(status)) {
      return context.appColors.infoBlue;
    }
    return context.appColors.goldMid;
  }
}

class _UsageRightsRow extends StatelessWidget {
  final BrandApplicationDto application;

  const _UsageRightsRow({required this.application});

  @override
  Widget build(BuildContext context) {
    final term = application.terms.isEmpty ? null : application.terms.last;
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  application.opportunityTitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              BrandLiveStatusChip(status: term?.status ?? application.status),
            ],
          ),
          const SizedBox(height: 8),
          BrandInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Partner',
            value: application.applicant.displayName,
          ),
          BrandInfoRow(
            icon: Icons.lock_outline_rounded,
            label: 'Exclusivity',
            value: term?.exclusivity.isNotEmpty == true
                ? term!.exclusivity
                : 'Not specified',
          ),
          BrandInfoRow(
            icon: Icons.approval_outlined,
            label: 'Approvals',
            value: term?.approvalRights.isNotEmpty == true
                ? term!.approvalRights
                : 'Not specified',
          ),
        ],
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntryDto entry;

  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final incoming = entry.direction == 'credit';
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(10),
      child: Row(
        children: [
          Icon(
            incoming ? Icons.south_west_rounded : Icons.north_east_rounded,
            color: incoming
                ? context.appColors.success
                : context.appColors.goldDark,
            size: 19,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  brandDate(entry.occurredAt, fallback: 'Date not recorded'),
                  style: AppTextStyles.smallMeta.copyWith(
                    color: context.appColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            brandMoney(entry.amountMinor, currency: entry.currency),
            style: AppTextStyles.cardLabel.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
