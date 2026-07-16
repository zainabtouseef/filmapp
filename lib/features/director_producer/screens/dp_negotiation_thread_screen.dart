import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../data/director_producer_demo_data.dart';
import '../models/dp_negotiation.dart';
import '../routes/director_producer_routes.dart';
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

class _DPNegotiationThreadScreenState
    extends State<DPNegotiationThreadScreen> {
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
    if (_rate.text.trim().isEmpty) {
      dpSnack(context, 'Enter a rate before sending a counter.');
      return;
    }
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
          message: 'Counter sent from Negotiation Detail.',
          timestamp: 'Just now',
          expiry: negotiation.expiry,
        ),
      ];
    });
    dpSnack(context, 'Counter sent');
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        dpHeaderAction(
          context,
          icon: Icons.article_outlined,
          label: 'Contract',
          onTap: () =>
              Navigator.pushNamed(context, DirectorProducerRoutes.contracts),
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
                      child:
                          dpText(context, negotiation.candidate, strong: true)),
                  DPStatusChip(label: negotiation.status, tone: DpTone.warning),
                ],
              ),
              const SizedBox(height: 6),
              dpText(
                context,
                '${negotiation.project} - ${negotiation.requirement} - ${negotiation.currentRate}',
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  DPStatusChip(label: negotiation.move, tone: DpTone.info),
                  DPStatusChip(label: negotiation.expiry, tone: DpTone.danger),
                  const DPStatusChip(
                      label: 'Counter enabled', tone: DpTone.success),
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
                for (var i = 0; i < _rounds.length; i++)
                  DPNegotiationRoundCard(
                    round: _rounds[i],
                    showDivider: i != _rounds.length - 1,
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
                  controller: _rate,
                  label: 'Rate',
                  icon: Icons.payments_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _schedule,
                  label: 'Payment schedule',
                  icon: Icons.event_repeat_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _conditions,
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
                      label: 'Send Counter',
                      icon: Icons.send_rounded,
                      onTap: _sendCounter,
                    ),
                    DPHolographicButton(
                      label: 'Accept',
                      icon: Icons.check_circle_outline,
                      onTap: () => Navigator.pushNamed(
                        context,
                        DirectorProducerRoutes.contracts,
                      ),
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
