import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../data/director_producer_demo_data.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_booking_status_spine.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_status_chip.dart';

class DPBookingRequestFormScreen extends StatefulWidget {
  const DPBookingRequestFormScreen({super.key});

  @override
  State<DPBookingRequestFormScreen> createState() =>
      _DPBookingRequestFormScreenState();
}

class _DPBookingRequestFormScreenState
    extends State<DPBookingRequestFormScreen> {
  Future<_BookingRequestSeed>? _seedFuture;
  bool _started = false;
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_started) {
      _started = true;
      _seedFuture = _loadSeed();
    }
  }

  Future<_BookingRequestSeed> _loadSeed() async {
    final auth = AuthScope.of(context);
    final projects = ProjectsScope.of(context);
    final projectRows = await projects.projects(force: true);
    final listings = await auth.marketplaceListings(type: 'talent');
    if (projectRows.isEmpty || listings.isEmpty) {
      throw const ApiException(
        code: 'booking.seed_missing',
        message: 'Create a project and find a public talent listing first.',
      );
    }
    return _BookingRequestSeed(
        project: projectRows.first, listing: listings.first);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_BookingRequestSeed>(
      future: _seedFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DPEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Preparing booking request',
            message: 'Loading your first project and talent listing.',
          );
        }
        if (snapshot.hasError) {
          return _PreviewBookingRequest(onSend: () {
            Navigator.pushNamed(context, DirectorProducerRoutes.bargaining);
          });
        }
        final seed = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            dpHeaderAction(
              context,
              icon: Icons.send_rounded,
              label: _sending ? 'Sending...' : 'Send',
              onTap: _sending ? () {} : () => _send(seed),
            ),
            const SizedBox(height: 8),
            const DPBookingStatusSpine(activeIndex: 0),
            const SizedBox(height: 14),
            DPTwoColumn(
              left: DPSectionCard(
                title: 'Request Details',
                icon: Icons.assignment_outlined,
                child: Column(
                  children: [
                    _RequestRow(label: 'Project', value: seed.project.title),
                    _RequestRow(
                      label: 'Requirement',
                      value: seed.project.requirements.isEmpty
                          ? 'General talent booking'
                          : seed.project.requirements.first.title,
                    ),
                    _RequestRow(
                        label: 'Stakeholder', value: seed.listing.title),
                    _RequestRow(label: 'Dates', value: 'Aug 18 - Aug 22'),
                    _RequestRow(
                      label: 'Fee offer',
                      value: seed.listing.priceFromMinor == null
                          ? 'PKR 250k'
                          : '${seed.listing.currency} ${seed.listing.priceFromMinor! ~/ 100}',
                      showDivider: false,
                    ),
                  ],
                ),
              ),
              right: DPSectionCard(
                title: 'Terms Preview',
                icon: Icons.fact_check_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    dpBullet(context, '30% deposit after signed contract.'),
                    dpBullet(context, 'Counteroffers are allowed.'),
                    dpBullet(context, 'Chat is kept inside booking record.'),
                    const SizedBox(height: 10),
                    const Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        DPStatusChip(
                            label: 'Expires 48h', tone: DpTone.warning),
                        DPStatusChip(
                            label: 'Counter allowed', tone: DpTone.info),
                        DPStatusChip(
                          label: 'Contract auto-generate',
                          tone: DpTone.success,
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    DPHolographicButton(
                      label:
                          _sending ? 'Sending Request' : 'Send Booking Request',
                      icon: Icons.send_rounded,
                      onTap: _sending ? null : () => _send(seed),
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

  Future<void> _send(_BookingRequestSeed seed) async {
    final bookings = BookingsScope.of(context);
    setState(() => _sending = true);
    try {
      final now = DateTime.now().toUtc();
      final start = DateTime.utc(now.year, now.month, now.day + 7, 9);
      final end = start.add(const Duration(days: 2, hours: 8));
      final feeMinor = seed.listing.priceFromMinor ?? 25000000;
      final booking = await bookings.createAndSendBooking(
        projectId: seed.project.publicId,
        listingId: seed.listing.publicId,
        requirementId: seed.project.requirements.isEmpty
            ? null
            : seed.project.requirements.first.publicId,
        startAt: start.toIso8601String(),
        endAt: end.toIso8601String(),
        feeMinor: feeMinor,
        currency: seed.listing.currency,
        message: 'Booking request sent from CineConnect.',
      );
      if (!mounted) return;
      dpSnack(context, 'Booking request sent');
      Navigator.pushNamed(
        context,
        DirectorProducerRoutes.negotiationThread,
        arguments: booking.negotiationId,
      );
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }
}

class _PreviewBookingRequest extends StatelessWidget {
  final VoidCallback onSend;

  const _PreviewBookingRequest({required this.onSend});

  @override
  Widget build(BuildContext context) {
    final requirement = DirectorProducerDemoData.requirements.first;
    final candidate = DirectorProducerDemoData.candidates.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPSectionCard(
          title: 'Preview mode',
          icon: Icons.info_outline_rounded,
          child: dpText(
            context,
            'Live project/listing unavailable — showing preview request.',
          ),
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Request Details',
            icon: Icons.assignment_outlined,
            child: Column(
              children: [
                const _RequestRow(label: 'Project', value: 'Hunza Winter Film'),
                _RequestRow(label: 'Requirement', value: requirement.title),
                _RequestRow(label: 'Stakeholder', value: candidate.name),
                _RequestRow(label: 'Dates', value: requirement.dates),
                _RequestRow(
                  label: 'Fee offer',
                  value: requirement.budgetRange,
                  showDivider: false,
                ),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Terms Preview',
            icon: Icons.fact_check_outlined,
            child: DPHolographicButton(
              label: 'Preview Bargaining',
              icon: Icons.send_rounded,
              onTap: onSend,
            ),
          ),
        ),
      ],
    );
  }
}

class _BookingRequestSeed {
  final Project project;
  final MarketplaceListing listing;

  const _BookingRequestSeed({required this.project, required this.listing});
}

class _RequestRow extends StatelessWidget {
  final String label;
  final String value;
  final bool showDivider;

  const _RequestRow({
    required this.label,
    required this.value,
    this.showDivider = true,
  });

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
      child: Row(
        children: [
          Expanded(child: dpText(context, label)),
          const SizedBox(width: 10),
          Flexible(child: dpText(context, value, strong: true)),
        ],
      ),
    );
  }
}
