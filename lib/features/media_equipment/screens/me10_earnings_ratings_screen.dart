import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/trust_safety/trust_safety_controller.dart';
import '../../../core/trust_safety/trust_safety_models.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/media_equipment_components.dart';

class ME10EarningsRatingsScreen extends StatefulWidget {
  const ME10EarningsRatingsScreen({super.key});

  @override
  State<ME10EarningsRatingsScreen> createState() =>
      _ME10EarningsRatingsScreenState();
}

class _ME10EarningsRatingsScreenState extends State<ME10EarningsRatingsScreen> {
  PaymentsController? _payments;
  OperationsController? _operations;
  BookingsController? _bookings;
  TrustSafetyController? _trust;
  Future<_EarningsData>? _future;
  String _filter = 'All';
  bool _addingAccount = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final payments = PaymentsScope.maybeOf(context);
    final operations = OperationsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final trust = TrustSafetyScope.maybeOf(context);
    if (payments == null || operations == null || bookings == null) return;
    if (identical(payments, _payments) &&
        identical(operations, _operations) &&
        identical(bookings, _bookings) &&
        identical(trust, _trust)) {
      return;
    }
    _payments = payments;
    _operations = operations;
    _bookings = bookings;
    _trust = trust;
    _future = _load();
  }

  Future<_EarningsData> _load({bool force = false}) async {
    final userId = AuthScope.maybeOf(context)?.user?.publicId;
    final dashboard = await _payments!.dashboard(force: force);
    final ledger = await _payments!.ledger(force: force);
    final accounts = await _payments!.payoutAccounts();
    final profile = await _operations!.equipmentProfile(force: force);
    final items = await _operations!.equipmentItems(force: force);
    final bookings = (await _bookings!.bookings(
      role: 'provider',
      force: force,
    ))
        .where((booking) => booking.category == 'equipment')
        .toList();

    UserReviewsDto? reviews;
    if (_trust != null && userId != null) {
      try {
        reviews = await _trust!.userReviews(userId);
      } catch (_) {
        reviews = null;
      }
    }
    return _EarningsData(
      dashboard: dashboard,
      ledger: ledger,
      accounts: accounts,
      profile: profile,
      items: items,
      bookings: bookings,
      reviews: reviews,
    );
  }

  void _reload() {
    if (_payments == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const InlineNotice(
        message: 'Preview mode. Sign in to load equipment earnings.',
        icon: Icons.visibility_outlined,
      );
    }
    return FutureBuilder<_EarningsData>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const InlineNotice(
            message: 'Loading earnings and ratings...',
            icon: Icons.hourglass_top_rounded,
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Earnings unavailable',
            message: '${snapshot.error}',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _buildWorkspace(snapshot.data!);
      },
    );
  }

  Widget _buildWorkspace(_EarningsData data) {
    final colors = context.appColors;
    final credits = data.ledger
        .where((entry) => entry.direction == 'credit')
        .fold<int>(0, (total, entry) => total + entry.amountMinor);
    final activeBookings = data.bookings
        .where(
          (booking) => {
            'accepted',
            'secured',
            'in_progress',
            'completed',
          }.contains(booking.status),
        )
        .length;
    final utilization = data.items.isEmpty
        ? 0
        : ((activeBookings / data.items.length) * 100).clamp(0, 100).round();
    final rating = data.reviews?.ratingAverage ??
        ((data.profile?.ratingAverage ?? 0) / 100);
    final reviewCount = data.reviews?.reviewCount ?? 0;
    final disputed = data.ledger
        .where((entry) => {'disputed', 'rejected'}.contains(entry.status))
        .length;
    final rows = _filteredRows(data.ledger);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricActionRail(
          items: [
            MetricActionItem(
              value: _minorMoney(credits),
              icon: Icons.payments_outlined,
              title: 'Revenue',
              subtitle: 'Incoming ledger',
              accentColor: colors.success,
            ),
            MetricActionItem(
              value: '$utilization%',
              icon: Icons.query_stats_outlined,
              title: 'Utilization',
              subtitle: '${data.items.length} inventory assets',
              accentColor: colors.infoBlue,
            ),
            MetricActionItem(
              value: rating.toStringAsFixed(1),
              icon: Icons.star_outline_rounded,
              title: 'Rating',
              subtitle: '$reviewCount verified reviews',
              accentColor: colors.infoPurple,
            ),
            MetricActionItem(
              value: '$disputed',
              icon: Icons.report_problem_outlined,
              title: 'Disputes',
              subtitle: 'Ledger exceptions',
              accentColor: disputed == 0 ? colors.goldMid : colors.danger,
            ),
          ],
        ),
        const SizedBox(height: 12),
        MediaTwoColumn(
          left: MediaSectionCard(
            title: 'Equipment ledger',
            icon: Icons.table_rows_outlined,
            selected: true,
            actionText: 'Refresh',
            onActionTap: _reload,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final filter in [
                        'All',
                        'Pending',
                        'Verified',
                        'Disputed',
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
                if (rows.isEmpty)
                  const CoreEmptyState(
                    icon: Icons.receipt_long_outlined,
                    title: 'No matching ledger entries',
                    message:
                        'Verified equipment booking payments and releases will appear here.',
                  )
                else
                  for (final row in rows)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _LedgerRow(item: row),
                    ),
              ],
            ),
          ),
          right: Column(
            children: [
              MediaSectionCard(
                title: 'Ratings & feedback',
                icon: Icons.stars_outlined,
                child: _RatingsPanel(
                  rating: rating,
                  reviews: data.reviews?.reviews ?? const [],
                  reviewCount: reviewCount,
                ),
              ),
              const SizedBox(height: 12),
              MediaSectionCard(
                title: 'Payout & records',
                icon: Icons.account_balance_outlined,
                child: Column(
                  children: [
                    MediaInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Pending release',
                      value: _minorMoney(data.dashboard.pendingReleaseMinor),
                    ),
                    if (data.accounts.isEmpty)
                      const MediaInfoRow(
                        icon: Icons.account_balance_outlined,
                        label: 'Payout account',
                        value: 'Not connected',
                      )
                    else
                      for (final account in data.accounts.take(2))
                        MediaInfoRow(
                          icon: Icons.account_balance_outlined,
                          label: account.accountName,
                          value:
                              '${account.accountMasked} · ${_title(account.status)}',
                        ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.science_outlined,
                      label: _addingAccount
                          ? 'Adding...'
                          : 'Add test payout account',
                      compact: true,
                      onTap: _addingAccount ? null : _addSandboxAccount,
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
                    ExportActionButton(
                      exportType: 'ledger',
                      label: 'Export ledger',
                      builder: (context, onTap, label) => CorePrimaryButton(
                        icon: Icons.file_download_outlined,
                        label: label,
                        compact: true,
                        onTap: onTap,
                      ),
                    ),
                  ],
                ),
              ),
              if (data.dashboard.schedules.isNotEmpty) ...[
                const SizedBox(height: 12),
                MediaSectionCard(
                  title: 'Payment schedules',
                  icon: Icons.account_tree_outlined,
                  child: Column(
                    children: [
                      for (final schedule in data.dashboard.schedules.take(3))
                        _ScheduleRow(schedule: schedule),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  List<LedgerEntryDto> _filteredRows(List<LedgerEntryDto> rows) {
    return rows.where((entry) {
      return switch (_filter) {
        'Pending' => {
            'pending',
            'pending_release',
            'pending_verification',
          }.contains(entry.status),
        'Verified' => {
            'verified',
            'posted',
            'released',
          }.contains(entry.status),
        'Disputed' => {
            'disputed',
            'rejected',
          }.contains(entry.status),
        _ => true,
      };
    }).toList();
  }

  Future<void> _addSandboxAccount() async {
    final accountName =
        AuthScope.maybeOf(context)?.user?.displayName ?? 'Equipment provider';
    setState(() => _addingAccount = true);
    try {
      await _payments!.createSandboxPayoutAccount(accountName: accountName);
      if (!mounted) return;
      mediaSnack(context, 'Test payout account added');
      _reload();
    } catch (error) {
      if (!mounted) return;
      mediaSnack(context, '$error');
    } finally {
      if (mounted) setState(() => _addingAccount = false);
    }
  }

  String _minorMoney(int amountMinor) {
    return '${amountMinor < 0 ? '-' : ''}'
        '${mediaMoney((amountMinor.abs() / 100).round())}';
  }
}

class _RatingsPanel extends StatelessWidget {
  final double rating;
  final int reviewCount;
  final List<ReviewDto> reviews;

  const _RatingsPanel({
    required this.rating,
    required this.reviewCount,
    required this.reviews,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              rating.toStringAsFixed(1),
              style: AppTextStyles.metricNumber.copyWith(
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _StarDisplay(rating: rating.round()),
                  const SizedBox(height: 3),
                  Text(
                    '$reviewCount verified booking reviews',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (reviews.isEmpty)
          const CoreEmptyState(
            icon: Icons.rate_review_outlined,
            title: 'No ratings yet',
            message:
                'Feedback appears after completed equipment bookings are reviewed.',
          )
        else
          for (final review in reviews.take(3))
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlassSectionCard(
                radius: 8,
                padding: const EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            review.reviewer.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardLabel.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        _StarDisplay(rating: review.rating),
                      ],
                    ),
                    if ((review.text ?? '').trim().isNotEmpty) ...[
                      const SizedBox(height: 5),
                      Text(
                        review.text!.trim(),
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        const SizedBox(height: 4),
        CoreSecondaryButton(
          icon: Icons.rate_review_outlined,
          label: 'Open review center',
          compact: true,
          onTap: () => Navigator.pushNamed(context, CoreRoutes.review),
        ),
      ],
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntryDto item;

  const _LedgerRow({required this.item});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(11),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.description,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.amountMinor < 0 ? '-' : ''}'
                  '${mediaMoney(item.amountMinor.abs() ~/ 100)} · '
                  '${item.bookingId ?? _title(item.entryType)}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          StatusChip(
            label: _title(item.status),
            color: _statusColor(context, item.status),
          ),
          CardMenu<String>(
            items: const [
              CardMenuItem(
                value: 'receipt',
                label: 'Receipt',
                icon: Icons.receipt_long_outlined,
              ),
              CardMenuItem(
                value: 'issue',
                label: 'Report issue',
                icon: Icons.report_problem_outlined,
              ),
            ],
            onSelected: (value) {
              if (value == 'receipt') {
                Navigator.pushNamed(context, CoreRoutes.ledger);
              } else {
                Navigator.pushNamed(
                  context,
                  CoreRoutes.report,
                  arguments: 'Equipment ledger issue ${item.publicId}',
                );
              }
            },
          ),
        ],
      ),
    );
  }

  static Color _statusColor(BuildContext context, String status) {
    final colors = context.appColors;
    return switch (status) {
      'verified' || 'posted' || 'released' => colors.success,
      'disputed' || 'rejected' => colors.danger,
      _ => colors.goldMid,
    };
  }
}

class _ScheduleRow extends StatelessWidget {
  final PaymentScheduleDto schedule;

  const _ScheduleRow({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GlassSectionCard(
        radius: 8,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Icon(Icons.event_note_outlined, color: colors.goldDark, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    schedule.bookingId,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${schedule.totalLabel} · '
                    '${schedule.milestones.length} milestones',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            StatusChip(
              label: _title(schedule.status),
              color: colors.infoBlue,
            ),
          ],
        ),
      ),
    );
  }
}

class _StarDisplay extends StatelessWidget {
  final int rating;

  const _StarDisplay({required this.rating});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        5,
        (index) => Icon(
          index < rating ? Icons.star_rounded : Icons.star_border_rounded,
          color: index < rating ? colors.goldMid : colors.iconMuted,
          size: 17,
        ),
      ),
    );
  }
}

class _EarningsData {
  final PaymentDashboardDto dashboard;
  final List<LedgerEntryDto> ledger;
  final List<PayoutAccountDto> accounts;
  final EquipmentProfileDto? profile;
  final List<EquipmentItemDto> items;
  final List<Booking> bookings;
  final UserReviewsDto? reviews;

  const _EarningsData({
    required this.dashboard,
    required this.ledger,
    required this.accounts,
    required this.profile,
    required this.items,
    required this.bookings,
    required this.reviews,
  });
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
