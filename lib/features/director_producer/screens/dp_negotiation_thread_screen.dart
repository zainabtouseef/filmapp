import 'package:flutter/material.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_negotiation.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dp_empty_state.dart';
import '../widgets/dp_holographic_button.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_negotiation_round_card.dart';

class DPNegotiationThreadScreen extends StatefulWidget {
  final String? negotiationId;

  /// When set, this is being shown inside a bottom sheet — render a
  /// close (X) button in the header instead of relying on page-level
  /// back navigation.
  final VoidCallback? onClose;

  const DPNegotiationThreadScreen({
    super.key,
    this.negotiationId,
    this.onClose,
  });

  @override
  State<DPNegotiationThreadScreen> createState() =>
      _DPNegotiationThreadScreenState();
}

class _DPNegotiationThreadScreenState extends State<DPNegotiationThreadScreen> {
  late Future<NegotiationThread> _future;
  final _rate = TextEditingController(text: '275000');
  final _schedule = TextEditingController(text: '30% / 40% / 30%');
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
          return _DemoNegotiationThread(
            negotiationId: widget.negotiationId,
            onClose: widget.onClose,
          );
        }
        return _LiveNegotiationThread(
          thread: snapshot.data!,
          rate: _rate,
          schedule: _schedule,
          sending: _sending,
          onCounter: _sendCounter,
          onAccept: _accept,
          onDecline: _decline,
          onClose: widget.onClose,
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
      widget.onClose?.call();
      Navigator.pushNamed(context, DirectorProducerRoutes.contracts);
    } on ApiException catch (error) {
      if (!mounted) return;
      dpSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _decline(NegotiationThread thread) async {
    setState(() => _sending = true);
    try {
      await BookingsScope.of(context).rejectBooking(thread.booking.publicId);
      if (!mounted) return;
      dpSnack(context, 'Negotiation declined');
      widget.onClose?.call();
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

class _ThreadHeader extends StatelessWidget {
  final String name;
  final String subtitle;
  final VoidCallback? onClose;

  const _ThreadHeader({
    required this.name,
    required this.subtitle,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle
                    .copyWith(color: colors.textPrimary, fontSize: 17),
              ),
              const SizedBox(height: 3),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style:
                    AppTextStyles.caption.copyWith(color: colors.textTertiary),
              ),
            ],
          ),
        ),
        if (onClose != null)
          GestureDetector(
            onTap: onClose,
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(9),
                color: colors.softSurface,
              ),
              child: Icon(Icons.close_rounded, color: colors.icon, size: 16),
            ),
          ),
      ],
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final IconData icon;
  final String label;

  const _SectionLabel({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(icon, size: 16, color: colors.goldDark),
        const SizedBox(width: 8),
        Text(
          label,
          style: AppTextStyles.cardTitle.copyWith(color: colors.textPrimary),
        ),
      ],
    );
  }
}

class _FieldBox extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;

  const _FieldBox({
    required this.label,
    required this.controller,
    this.keyboardType,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.caption.copyWith(color: colors.textTertiary),
        ),
        const SizedBox(height: 5),
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 13),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(11),
            color: colors.softSurface,
          ),
          child: Center(
            child: TextField(
              controller: controller,
              keyboardType: keyboardType,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w600,
              ),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ThreadFooter extends StatelessWidget {
  final String name;
  final bool sending;
  final VoidCallback onAccept;
  final VoidCallback onCounter;
  final VoidCallback onChat;
  final VoidCallback onDecline;

  const _ThreadFooter({
    required this.name,
    required this.sending,
    required this.onAccept,
    required this.onCounter,
    required this.onChat,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: DPHolographicButton(
                label: sending ? 'Working…' : 'Accept terms',
                icon: Icons.check_circle_outline,
                onTap: sending ? null : onAccept,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DPHolographicButton(
                label: 'Send counter',
                icon: Icons.send_rounded,
                secondary: true,
                onTap: sending ? null : onCounter,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: onChat,
                icon: Icon(Icons.chat_bubble_outline_rounded,
                    size: 15, color: colors.infoBlue),
                label: Text(
                  'Chat with $name',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption.copyWith(
                    color: colors.infoBlue,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colors.border),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton(
              onPressed: sending ? null : onDecline,
              style: OutlinedButton.styleFrom(
                foregroundColor: colors.danger,
                side: BorderSide(color: colors.border),
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: Text(
                'Decline',
                style: AppTextStyles.caption.copyWith(
                  color: colors.danger,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _LiveNegotiationThread extends StatelessWidget {
  final NegotiationThread thread;
  final TextEditingController rate;
  final TextEditingController schedule;
  final bool sending;
  final ValueChanged<NegotiationThread> onCounter;
  final ValueChanged<NegotiationThread> onAccept;
  final ValueChanged<NegotiationThread> onDecline;
  final VoidCallback? onClose;

  const _LiveNegotiationThread({
    required this.thread,
    required this.rate,
    required this.schedule,
    required this.sending,
    required this.onCounter,
    required this.onAccept,
    required this.onDecline,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    final rounds = thread.rounds.map((item) => item.toDpRound()).toList();
    final name = thread.booking.provider.displayName;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThreadHeader(
          name: name,
          subtitle:
              'Booking ${thread.booking.publicId} · ${thread.booking.category}',
          onClose: onClose,
        ),
        const SizedBox(height: 18),
        const _SectionLabel(icon: Icons.trending_up_rounded, label: 'Rounds'),
        const SizedBox(height: 10),
        for (var i = 0; i < rounds.length; i++)
          DPNegotiationRoundCard(round: rounds[i]),
        const SizedBox(height: 8),
        Container(height: 1, color: context.appColors.borderMuted),
        const SizedBox(height: 16),
        const _SectionLabel(icon: Icons.tune_rounded, label: 'Counter offer'),
        const SizedBox(height: 12),
        _FieldBox(
          label: 'Rate',
          controller: rate,
          keyboardType: TextInputType.number,
        ),
        const SizedBox(height: 10),
        _FieldBox(label: 'Payment schedule', controller: schedule),
        const SizedBox(height: 20),
        _ThreadFooter(
          name: name,
          sending: sending,
          onAccept: () => onAccept(thread),
          onCounter: () => onCounter(thread),
          onChat: () => Navigator.pushNamed(
            context,
            CoreRoutes.chat,
            arguments: thread.booking.conversationId,
          ),
          onDecline: () => onDecline(thread),
        ),
      ],
    );
  }
}

class _DemoNegotiationThread extends StatefulWidget {
  final String? negotiationId;
  final VoidCallback? onClose;

  const _DemoNegotiationThread({this.negotiationId, this.onClose});

  @override
  State<_DemoNegotiationThread> createState() => _DemoNegotiationThreadState();
}

class _DemoNegotiationThreadState extends State<_DemoNegotiationThread> {
  late final DpNegotiation negotiation;
  late List<DpNegotiationRound> _rounds;
  late String _status;
  late final _rate = TextEditingController(text: negotiation.currentRate);
  final _schedule = TextEditingController(text: '30% / 40% / 30%');

  @override
  void initState() {
    super.initState();
    final negotiations = DirectorProducerDemoData.negotiations;
    negotiation = negotiations.firstWhere(
      (item) => item.id == widget.negotiationId,
      orElse: () => negotiations.first,
    );
    _rounds = List.of(negotiation.rounds);
    _status = negotiation.status;
  }

  @override
  void dispose() {
    _rate.dispose();
    _schedule.dispose();
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
          conditions: '',
          message: 'Counter sent from preview mode.',
          timestamp: 'Just now',
          expiry: negotiation.expiry,
        ),
      ];
      _status = 'Their move';
    });
    dpSnack(context, 'Counter sent');
  }

  void _accept() {
    setState(() => _status = 'Accepted');
    dpSnack(context, 'Offer accepted');
    widget.onClose?.call();
  }

  void _decline() {
    setState(() => _status = 'Withdrawn');
    dpSnack(context, 'Negotiation declined');
    widget.onClose?.call();
  }

  @override
  Widget build(BuildContext context) {
    return _LivePreview(
      negotiation: negotiation,
      status: _status,
      rounds: _rounds,
      rate: _rate,
      schedule: _schedule,
      onCounter: _sendCounter,
      onAccept: _accept,
      onDecline: _decline,
      onClose: widget.onClose,
    );
  }
}

class _LivePreview extends StatelessWidget {
  final DpNegotiation negotiation;
  final String status;
  final List<DpNegotiationRound> rounds;
  final TextEditingController rate;
  final TextEditingController schedule;
  final VoidCallback onCounter;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final VoidCallback? onClose;

  const _LivePreview({
    required this.negotiation,
    required this.status,
    required this.rounds,
    required this.rate,
    required this.schedule,
    required this.onCounter,
    required this.onAccept,
    required this.onDecline,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ThreadHeader(
          name: negotiation.candidate,
          subtitle: '${negotiation.project} · ${negotiation.requirement}',
          onClose: onClose,
        ),
        const SizedBox(height: 18),
        const _SectionLabel(icon: Icons.trending_up_rounded, label: 'Rounds'),
        const SizedBox(height: 10),
        for (var i = 0; i < rounds.length; i++)
          DPNegotiationRoundCard(round: rounds[i]),
        const SizedBox(height: 8),
        Container(height: 1, color: context.appColors.borderMuted),
        const SizedBox(height: 16),
        const _SectionLabel(icon: Icons.tune_rounded, label: 'Counter offer'),
        const SizedBox(height: 12),
        _FieldBox(label: 'Rate', controller: rate),
        const SizedBox(height: 10),
        _FieldBox(label: 'Payment schedule', controller: schedule),
        const SizedBox(height: 20),
        _ThreadFooter(
          name: negotiation.candidate,
          sending: false,
          onAccept: onAccept,
          onCounter: onCounter,
          onChat: () => Navigator.pushNamed(
            context,
            DirectorProducerRoutes.room,
          ),
          onDecline: onDecline,
        ),
      ],
    );
  }
}
