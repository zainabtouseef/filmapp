import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_negotiation.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_negotiation_round_card.dart';
import '../widgets/dp_status_chip.dart';

class DPNegotiationThreadScreen extends StatefulWidget {
  final String? negotiationId;

  const DPNegotiationThreadScreen({super.key, this.negotiationId});

  @override
  State<DPNegotiationThreadScreen> createState() =>
      _DPNegotiationThreadScreenState();
}

class _DPNegotiationThreadScreenState extends State<DPNegotiationThreadScreen> {
  late Future<NegotiationThread> _future;
  final _rate = TextEditingController(text: '275000');
  final _schedule = TextEditingController(text: '30% / 40% / 30%');
  final _conditions = TextEditingController(text: 'One prep day included');
  bool _sending = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future = _load();
  }

  @override
  void dispose() {
    _rate.dispose();
    _schedule.dispose();
    _conditions.dispose();
    super.dispose();
  }

  Future<NegotiationThread> _load() async {
    final id = widget.negotiationId;
    final bookings = BookingsScope.of(context);
    if (id != null && id.startsWith('NEG-')) {
      return bookings.negotiation(id);
    }
    final rows = await bookings.negotiations();
    if (rows.isEmpty) {
      throw const ApiException(
        code: 'negotiation.none',
        message: 'No live negotiations found.',
      );
    }
    return rows.first;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<NegotiationThread>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const DPEmptyState(
            icon: Icons.hourglass_top_rounded,
            title: 'Loading negotiation',
            message: 'Fetching the live offer thread.',
          );
        }
        if (snapshot.hasError) {
          return _DemoNegotiationThread(negotiationId: widget.negotiationId);
        }
        return _LiveNegotiationThread(
          thread: snapshot.data!,
          rate: _rate,
          schedule: _schedule,
          conditions: _conditions,
          sending: _sending,
          onCounter: _sendCounter,
          onAccept: _accept,
        );
      },
    );
  }

  Future<void> _sendCounter(NegotiationThread thread) async {
    final feeMinor = _parseMinor(_rate.text);
    if (feeMinor == null || feeMinor <= 0) {
      dpSnack(context, 'Enter a valid rate before sending a counter.');
      return;
    }
    setState(() => _sending = true);
    try {
      await BookingsScope.of(context).createCounterOffer(
        bookingId: thread.booking.publicId,
        feeMinor: feeMinor,
        currency: thread.currentOffer?.currency ?? thread.booking.currency,
        conditions: _conditions.text.trim(),
        message: 'Counter sent from Negotiation Detail.',
      );
      if (!mounted) return;
      dpSnack(context, 'Counter sent');
      setState(() =>
          _future = BookingsScope.of(context).negotiation(thread.publicId));
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _accept(NegotiationThread thread) async {
    final offer = thread.currentOffer;
    if (offer == null) return;
    setState(() => _sending = true);
    try {
      await BookingsScope.of(context).acceptOffer(offer.publicId);
      if (!mounted) return;
      dpSnack(context, 'Offer accepted');
      Navigator.pushNamed(context, DirectorProducerRoutes.contracts);
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  int? _parseMinor(String value) {
    final whole = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (whole == null) return null;
    return whole * 100;
  }
}

class _LiveNegotiationThread extends StatelessWidget {
  final NegotiationThread thread;
  final TextEditingController rate;
  final TextEditingController schedule;
  final TextEditingController conditions;
  final bool sending;
  final ValueChanged<NegotiationThread> onCounter;
  final ValueChanged<NegotiationThread> onAccept;

  const _LiveNegotiationThread({
    required this.thread,
    required this.rate,
    required this.schedule,
    required this.conditions,
    required this.sending,
    required this.onCounter,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = thread.rounds.map((item) => item.toDpRound()).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.chat_bubble_outline_rounded,
          label: 'Chat',
          onTap: () => Navigator.pushNamed(
            context,
            CoreRoutes.chat,
            arguments: thread.booking.conversationId,
          ),
        ),
        const SizedBox(height: 8),
        DPGlassCard(
          selected: true,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: dpText(
                      context,
                      thread.booking.provider.displayName,
                      strong: true,
                    ),
                  ),
                  DPStatusChip(label: thread.status, tone: DpTone.warning),
                ],
              ),
              const SizedBox(height: 6),
              dpText(
                context,
                'Booking ${thread.booking.publicId} - ${thread.currentOffer?.feeLabel ?? 'Rate TBD'}',
              ),
              const SizedBox(height: 10),
              const Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DPStatusChip(label: 'Counter enabled', tone: DpTone.success),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Rounds',
            icon: Icons.timeline_rounded,
            child: Column(
              children: [
                for (var i = 0; i < rounds.length; i++)
                  DPNegotiationRoundCard(
                    round: rounds[i],
                    showDivider: i != rounds.length - 1,
                  ),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Counter Offer',
            icon: Icons.edit_note_rounded,
            child: Column(
              children: [
                CoreTextField(
                  controller: rate,
                  label: 'Rate (PKR)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: schedule,
                  label: 'Payment schedule',
                  icon: Icons.event_repeat_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: conditions,
                  label: 'Conditions',
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    DPHolographicButton(
                      label: sending ? 'Sending' : 'Send Counter',
                      icon: Icons.send_rounded,
                      onTap: sending ? null : () => onCounter(thread),
                    ),
                    DPHolographicButton(
                      label: 'Accept',
                      icon: Icons.check_circle_outline,
                      onTap: sending ? null : () => onAccept(thread),
                      secondary: true,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _DemoNegotiationThread extends StatefulWidget {
  final String? negotiationId;

  const _DemoNegotiationThread({this.negotiationId});

  @override
  State<_DemoNegotiationThread> createState() => _DemoNegotiationThreadState();
}

class _DemoNegotiationThreadState extends State<_DemoNegotiationThread> {
  late final DpNegotiation negotiation;
  late List<DpNegotiationRound> _rounds;
  late final _rate = TextEditingController(text: negotiation.currentRate);
  final _schedule = TextEditingController(text: '30% / 40% / 30%');
  final _conditions =
      TextEditingController(text: 'One camera prep day included');

  @override
  void initState() {
    super.initState();
    final negotiations = DirectorProducerDemoData.negotiations;
    negotiation = negotiations.firstWhere(
      (item) => item.id == widget.negotiationId,
      orElse: () => negotiations.first,
    );
    _rounds = List.of(negotiation.rounds);
  }

  @override
  void dispose() {
    _rate.dispose();
    _schedule.dispose();
    _conditions.dispose();
    super.dispose();
  }

  void _sendCounter() {
    setState(() {
      _rounds = [
        ..._rounds,
        DpNegotiationRound(
          round: _rounds.length + 1,
          sentBy: 'Producer',
          rate: _rate.text.trim(),
          dates: negotiation.rounds.isNotEmpty
              ? negotiation.rounds.last.dates
              : '',
          schedule: _schedule.text.trim(),
          conditions: _conditions.text.trim(),
          message: 'Counter sent from preview mode.',
          timestamp: 'Just now',
          expiry: negotiation.expiry,
        ),
      ];
    });
    dpSnack(context, 'Counter sent');
  }

  @override
  Widget build(BuildContext context) {
    return _LivePreview(
      negotiation: negotiation,
      rounds: _rounds,
      rate: _rate,
      schedule: _schedule,
      conditions: _conditions,
      onCounter: _sendCounter,
    );
  }
}

class _LivePreview extends StatelessWidget {
  final DpNegotiation negotiation;
  final List<DpNegotiationRound> rounds;
  final TextEditingController rate;
  final TextEditingController schedule;
  final TextEditingController conditions;
  final VoidCallback onCounter;

  const _LivePreview({
    required this.negotiation,
    required this.rounds,
    required this.rate,
    required this.schedule,
    required this.conditions,
    required this.onCounter,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        DPSectionCard(
          title: 'Preview mode',
          icon: Icons.info_outline_rounded,
          child: dpText(
              context, 'Live negotiation unavailable — showing preview.'),
        ),
        const SizedBox(height: 12),
        DPTwoColumn(
          left: DPSectionCard(
            title: 'Rounds',
            icon: Icons.timeline_rounded,
            child: Column(
              children: [
                for (var i = 0; i < rounds.length; i++)
                  DPNegotiationRoundCard(
                    round: rounds[i],
                    showDivider: i != rounds.length - 1,
                  ),
              ],
            ),
          ),
          right: DPSectionCard(
            title: 'Counter Offer',
            icon: Icons.edit_note_rounded,
            child: Column(
              children: [
                CoreTextField(
                  controller: rate,
                  label: 'Rate',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: schedule,
                  label: 'Payment schedule',
                  icon: Icons.event_repeat_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: conditions,
                  label: 'Conditions',
                  icon: Icons.notes_outlined,
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DPHolographicButton(
                  label: 'Send Counter',
                  icon: Icons.send_rounded,
                  onTap: onCounter,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
