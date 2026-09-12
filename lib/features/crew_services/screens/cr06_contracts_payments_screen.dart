import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/payments/payment_models.dart';
import '../../../core/payments/payments_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/crew_services_models.dart';
import '../routes/crew_services_routes.dart';
import '../widgets/crew_services_components.dart';

class CR06ContractsPaymentsScreen extends StatefulWidget {
  const CR06ContractsPaymentsScreen({super.key});

  @override
  State<CR06ContractsPaymentsScreen> createState() =>
      _CR06ContractsPaymentsScreenState();
}

class _CR06ContractsPaymentsScreenState
    extends State<CR06ContractsPaymentsScreen> {
  BookingsController? _bookings;
  ContractsController? _contracts;
  PaymentsController? _payments;
  Future<_ContractsData>? _future;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookings = BookingsScope.maybeOf(context);
    final contracts = ContractsScope.maybeOf(context);
    final payments = PaymentsScope.maybeOf(context);
    if (bookings == null || contracts == null || payments == null) return;
    if (identical(bookings, _bookings) &&
        identical(contracts, _contracts) &&
        identical(payments, _payments)) {
      return;
    }
    _bookings = bookings;
    _contracts = contracts;
    _payments = payments;
    _future = _load();
  }

  Future<_ContractsData> _load({bool force = false}) async {
    final values = await Future.wait([
      _bookings!.bookings(role: 'provider', force: force),
      _contracts!.contracts(force: force),
      _payments!.dashboard(force: force),
      _payments!.ledger(force: force),
    ]);
    final bookings = (values[0] as List<Booking>)
        .where((booking) => booking.category == 'crew')
        .toList();
    final bookingIds = bookings.map((booking) => booking.publicId).toSet();
    return _ContractsData(
      bookings: bookings,
      contracts: (values[1] as List<CineContract>)
          .where((contract) => bookingIds.contains(contract.bookingId))
          .toList(),
      schedules: (values[2] as PaymentDashboardDto)
          .schedules
          .where((schedule) => bookingIds.contains(schedule.bookingId))
          .toList(),
      ledger: (values[3] as List<LedgerEntryDto>)
          .where((entry) => bookingIds.contains(entry.bookingId))
          .toList(),
    );
  }

  void _reload() {
    if (_bookings == null) return;
    setState(() => _future = _load(force: true));
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load contracts',
        message: 'Crew contracts and payments are stored in the backend.',
      );
    }
    return FutureBuilder<_ContractsData>(
      future: future,
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
            title: 'Contracts unavailable',
            message: 'Could not load contracts and payment records.',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        return _buildData(snapshot.data!);
      },
    );
  }

  Widget _buildData(_ContractsData data) {
    final signed = data.contracts.where((item) => item.isSigned).length;
    final credits = data.ledger
        .where((entry) => entry.direction == 'credit')
        .fold<int>(0, (sum, entry) => sum + entry.amountMinor);
    final pending = data.schedules
        .expand((schedule) => schedule.milestones)
        .where((milestone) => !{'released', 'paid'}.contains(milestone.status))
        .fold<int>(0, (sum, milestone) => sum + milestone.amountMinor);
    final contractedBookingIds =
        data.contracts.map((contract) => contract.bookingId).toSet();
    final readyForContract = data.bookings
        .where((booking) =>
            {'accepted', 'secured', 'in_progress'}.contains(booking.status) &&
            !contractedBookingIds.contains(booking.publicId))
        .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        CrewKpiRail(
          metrics: [
            CrewMetric(
              label: 'Contracts',
              value: '${data.contracts.length}',
              delta: '$signed fully signed',
              icon: Icons.description_outlined,
              tone: CrewTone.purple,
              route: CrewServicesRoutes.contracts,
            ),
            CrewMetric(
              label: 'Earned',
              value: crewMoney(credits ~/ 100),
              delta: 'Backend ledger credits',
              icon: Icons.account_balance_wallet_outlined,
              tone: CrewTone.green,
              route: CrewServicesRoutes.contracts,
            ),
            CrewMetric(
              label: 'Scheduled',
              value: crewMoney(pending ~/ 100),
              delta: 'Pending milestones',
              icon: Icons.schedule_outlined,
              tone: CrewTone.gold,
              route: CrewServicesRoutes.contracts,
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (readyForContract.isNotEmpty) ...[
          CrewSectionCard(
            title: 'Ready for contract',
            icon: Icons.post_add_outlined,
            selected: true,
            child: Column(
              children: [
                for (final booking in readyForContract)
                  _ReadyContractRow(
                    booking: booking,
                    busy: _busyId == booking.publicId,
                    onGenerate: () => _generate(booking),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],
        CrewTwoColumn(
          left: CrewSectionCard(
            title: 'Crew contracts',
            icon: Icons.draw_outlined,
            child: data.contracts.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.description_outlined,
                    title: 'No crew contracts yet',
                    message:
                        'Accepted crew bookings can generate an auditable contract here.',
                  )
                : Column(
                    children: [
                      for (final contract in data.contracts)
                        _ContractCard(
                          contract: contract,
                          busy: _busyId == contract.publicId,
                          onSign: () => _sign(contract),
                        ),
                    ],
                  ),
          ),
          right: CrewSectionCard(
            title: 'Payment ledger',
            icon: Icons.receipt_long_outlined,
            child: data.ledger.isEmpty
                ? const CoreEmptyState(
                    icon: Icons.account_balance_wallet_outlined,
                    title: 'No crew ledger entries',
                    message:
                        'Released project milestones and payout activity will appear here.',
                  )
                : Column(
                    children: [
                      for (final entry in data.ledger.take(8))
                        _LedgerRow(entry: entry),
                    ],
                  ),
          ),
        ),
      ],
    );
  }

  Future<void> _generate(Booking booking) async {
    setState(() => _busyId = booking.publicId);
    try {
      await _contracts!.generateForBooking(booking.publicId);
      if (!mounted) return;
      crewSnack(context, 'Crew contract generated');
      _reload();
    } catch (error) {
      if (mounted) crewSnack(context, 'Could not generate contract: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _sign(CineContract contract) async {
    setState(() => _busyId = contract.publicId);
    try {
      await _contracts!.sign(contract.publicId);
      if (!mounted) return;
      crewSnack(context, 'Contract signature recorded');
      _reload();
    } catch (error) {
      if (mounted) crewSnack(context, 'Could not sign contract: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }
}

class _ReadyContractRow extends StatelessWidget {
  final Booking booking;
  final bool busy;
  final VoidCallback onGenerate;

  const _ReadyContractRow({
    required this.booking,
    required this.busy,
    required this.onGenerate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: GlassSectionCard(
        radius: 12,
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Icon(Icons.movie_filter_outlined, color: colors.goldDark),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                booking.projectTitle,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
            const SizedBox(width: 8),
            FilledButton.icon(
              onPressed: busy ? null : onGenerate,
              icon: busy
                  ? const SizedBox.square(
                      dimension: 14,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.post_add_outlined, size: 17),
              label: const Text('Generate'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContractCard extends StatelessWidget {
  final CineContract contract;
  final bool busy;
  final VoidCallback onSign;

  const _ContractCard({
    required this.contract,
    required this.busy,
    required this.onSign,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: GlassSectionCard(
        radius: 14,
        padding: EdgeInsets.zero,
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: colors.infoPurple),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(13),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              contract.title,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.cardLabel.copyWith(
                                color: colors.textPrimary,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          StatusChip(
                            label: contract.statusLabel,
                            color: contract.isSigned
                                ? colors.success
                                : colors.goldMid,
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '${contract.displayValue} · ${contract.signatureProgressPercent}',
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                      if (!contract.isSigned) ...[
                        const SizedBox(height: 10),
                        OutlinedButton.icon(
                          onPressed: busy ? null : onSign,
                          icon: const Icon(Icons.draw_outlined, size: 17),
                          label: Text(busy ? 'Signing...' : 'Sign contract'),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _LedgerRow extends StatelessWidget {
  final LedgerEntryDto entry;

  const _LedgerRow({required this.entry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            entry.direction == 'credit'
                ? Icons.south_west_rounded
                : Icons.north_east_rounded,
            color:
                entry.direction == 'credit' ? colors.success : colors.goldMid,
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
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  entry.status,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Text(
            crewMoney(entry.amountMinor ~/ 100),
            style: AppTextStyles.cardLabel.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _ContractsData {
  final List<Booking> bookings;
  final List<CineContract> contracts;
  final List<PaymentScheduleDto> schedules;
  final List<LedgerEntryDto> ledger;

  const _ContractsData({
    required this.bookings,
    required this.contracts,
    required this.schedules,
    required this.ledger,
  });
}
