import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-08 Counteroffer Composer
class AT08CounterofferComposerScreen extends StatefulWidget {
  final String? offerId;

  const AT08CounterofferComposerScreen({super.key, this.offerId});

  @override
  State<AT08CounterofferComposerScreen> createState() =>
      _AT08CounterofferComposerScreenState();
}

class _AT08CounterofferComposerScreenState
    extends State<AT08CounterofferComposerScreen> {
  late final String offerId;
  late final TextEditingController amount;
  late final TextEditingController dates;
  late final TextEditingController advance;
  late final TextEditingController conditions;
  late final TextEditingController message;
  String? error;
  bool sending = false;
  bool _loadedLiveTerms = false;
  bool _allowsBargaining = true;

  @override
  void initState() {
    super.initState();
    offerId = widget.offerId ?? '';
    amount = TextEditingController();
    dates = TextEditingController();
    advance = TextEditingController();
    conditions = TextEditingController();
    message = TextEditingController();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_loadedLiveTerms && offerId.startsWith('BKG-')) {
      _loadedLiveTerms = true;
      _loadLiveTerms();
    }
  }

  @override
  void dispose() {
    amount.dispose();
    dates.dispose();
    advance.dispose();
    conditions.dispose();
    message.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!offerId.startsWith('BKG-')) {
      return const ActorSectionCard(
        title: 'Counteroffer',
        icon: Icons.edit_note_outlined,
        tone: ActorTone.blue,
        child: CoreEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Open a live offer first',
          message:
              'Counteroffers require a server booking ID. No local draft or fake offer is shown.',
        ),
      );
    }
    if (!_allowsBargaining) {
      return const ActorSectionCard(
        title: 'Fixed-price booking',
        icon: Icons.lock_outline_rounded,
        tone: ActorTone.blue,
        child: CoreEmptyState(
          icon: Icons.price_check_outlined,
          title: 'Counteroffers are disabled',
          message:
              'This marketplace listing uses a fixed public price. Accept or reject the offer from the offer detail screen.',
        ),
      );
    }
    return ActorTwoColumn(
      left: ActorSectionCard(
        title: 'Editable Terms',
        icon: Icons.edit_note_outlined,
        child: Column(
          children: [
            Text(
              'Revise only the terms that need to change. The producer receives this as the next offer revision.',
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
            const SizedBox(height: 14),
            CoreTextField(
              controller: amount,
              label: 'Counter amount',
              icon: Icons.payments_outlined,
              errorText: error,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: dates,
              label: 'Change dates',
              icon: Icons.date_range_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: advance,
              label: 'Advance percentage',
              icon: Icons.percent_rounded,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: conditions,
              label: 'Conditions',
              icon: Icons.rule_folder_outlined,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: message,
              label: 'Professional message',
              icon: Icons.chat_bubble_outline_rounded,
              maxLines: 4,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            CorePrimaryButton(
              icon: Icons.send_outlined,
              label: 'Send counteroffer',
              compact: true,
              loading: sending,
              onTap: sending ? null : _submit,
            ),
          ],
        ),
      ),
      right: _CounterSummary(
        amount: amount.text,
        dates: dates.text,
        advance: advance.text,
        conditions: conditions.text,
        message: message.text,
      ),
    );
  }

  Future<void> _loadLiveTerms() async {
    final bookings = BookingsScope.maybeOf(context);
    if (bookings == null) return;
    try {
      final booking = await bookings.booking(offerId);
      if (!mounted) return;
      final offer = booking.activeOffer;
      setState(() {
        _allowsBargaining = booking.allowsBargaining;
        if (offer != null) amount.text = offer.feeLabel;
        dates.text =
            '${DateFormat('MMM d').format(booking.startAt.toLocal())} - ${DateFormat('MMM d, y').format(booking.endAt.toLocal())}';
        if ((offer?.conditions ?? '').trim().isNotEmpty) {
          conditions.text = offer!.conditions!.trim();
        }
      });
    } on ApiException catch (apiError) {
      if (!mounted) return;
      setState(() => error = apiError.message);
    }
  }

  void _submit() {
    if (amount.text.trim().isEmpty || message.text.trim().isEmpty) {
      setState(() => error = 'Required');
      return;
    }
    _submitLive();
  }

  Future<void> _submitLive() async {
    final feeMinor = _parseMinor(amount.text);
    if (feeMinor == null || feeMinor <= 0) {
      setState(() => error = 'Enter a valid amount');
      return;
    }
    setState(() {
      sending = true;
      error = null;
    });
    try {
      await BookingsScope.of(context).createCounterOffer(
        bookingId: offerId,
        feeMinor: feeMinor,
        conditions: _structuredConditions(),
        message: message.text.trim(),
      );
      if (!mounted) return;
      actorSnack(context, 'Counteroffer sent to Director');
      Navigator.popUntil(
        context,
        (route) =>
            route.settings.name == ActorTalentRoutes.opportunities ||
            route.isFirst,
      );
    } on ApiException catch (apiError) {
      if (!mounted) return;
      setState(() => error = apiError.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => error = 'Could not send the counteroffer. Try again.');
    } finally {
      if (mounted) setState(() => sending = false);
    }
  }

  int? _parseMinor(String value) {
    final whole = int.tryParse(value.replaceAll(RegExp(r'[^0-9]'), ''));
    if (whole == null) return null;
    return whole * 100;
  }

  String _structuredConditions() {
    return [
      if (conditions.text.trim().isNotEmpty) conditions.text.trim(),
      if (dates.text.trim().isNotEmpty) 'Requested dates: ${dates.text.trim()}',
      if (advance.text.trim().isNotEmpty)
        'Requested advance: ${advance.text.trim()}',
    ].join('\n');
  }
}

class _CounterSummary extends StatelessWidget {
  final String amount;
  final String dates;
  final String advance;
  final String conditions;
  final String message;

  const _CounterSummary({
    required this.amount,
    required this.dates,
    required this.advance,
    required this.conditions,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return ActorSectionCard(
      title: 'Live Summary',
      icon: Icons.summarize_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ActorInfoRow(
            icon: Icons.payments_outlined,
            label: 'Amount',
            value: amount,
          ),
          ActorInfoRow(
            icon: Icons.date_range_outlined,
            label: 'Dates',
            value: dates,
          ),
          ActorInfoRow(
            icon: Icons.percent_rounded,
            label: 'Advance',
            value: advance,
          ),
          ActorInfoRow(
            icon: Icons.rule_folder_outlined,
            label: 'Conditions',
            value: conditions,
          ),
          const SizedBox(height: 8),
          Text(
            message,
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}
