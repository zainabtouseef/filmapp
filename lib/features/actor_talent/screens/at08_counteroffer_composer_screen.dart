import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/actor_talent_demo_data.dart';
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

  @override
  void initState() {
    super.initState();
    final opportunities = ActorTalentDemoData.opportunities;
    final offer = opportunities.firstWhere(
      (item) => item.id == widget.offerId,
      orElse: () => opportunities.first,
    );
    offerId = offer.id;
    final draft = ActorTalentDemoStore.instance.draftFor(offerId);
    amount = TextEditingController(text: draft?.amount ?? offer.fee);
    dates = TextEditingController(text: draft?.dates ?? offer.dates);
    advance = TextEditingController(text: draft?.advance ?? '40%');
    conditions = TextEditingController(
        text: draft?.conditions ?? 'Travel and wardrobe provided');
    message = TextEditingController(
      text: draft?.message ??
          'Thank you for the offer. I can confirm availability with the adjusted dates and advance.',
    );
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
    return ActorTwoColumn(
      left: ActorSectionCard(
        title: 'Editable Terms',
        icon: Icons.edit_note_outlined,
        child: Column(
          children: [
            const StepWizardIndicator(currentStep: 1, totalSteps: 3),
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
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.save_outlined,
                    label: 'Save draft',
                    compact: true,
                    onTap: _saveDraft,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.send_outlined,
                    label: 'Send',
                    compact: true,
                    onTap: _submit,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      right: _CounterPreview(
        amount: amount.text,
        dates: dates.text,
        advance: advance.text,
        conditions: conditions.text,
        message: message.text,
      ),
    );
  }

  void _saveDraft() {
    ActorTalentDemoStore.instance.saveDraft(
      offerId,
      ActorCounterofferDraft(
        amount: amount.text,
        dates: dates.text,
        advance: advance.text,
        conditions: conditions.text,
        message: message.text,
      ),
    );
    actorSnack(context, 'Counteroffer draft saved');
  }

  void _submit() {
    if (amount.text.trim().isEmpty || message.text.trim().isEmpty) {
      setState(() => error = 'Required');
      return;
    }
    ActorTalentDemoStore.instance.sendCounteroffer(offerId);
    ActorTalentDemoStore.instance.clearDraft(offerId);
    setState(() => error = null);
    actorSnack(context, 'Counteroffer sent to Director DP-11');
    Navigator.popUntil(
      context,
      (route) =>
          route.settings.name == ActorTalentRoutes.opportunities ||
          route.isFirst,
    );
  }
}

class _CounterPreview extends StatelessWidget {
  final String amount;
  final String dates;
  final String advance;
  final String conditions;
  final String message;

  const _CounterPreview({
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
      icon: Icons.preview_outlined,
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
