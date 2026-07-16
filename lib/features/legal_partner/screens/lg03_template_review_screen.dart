import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/legal_partner_demo_data.dart';
import '../models/legal_partner_models.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_partner_components.dart';

class LG03TemplateReviewScreen extends StatefulWidget {
  const LG03TemplateReviewScreen({super.key});

  @override
  State<LG03TemplateReviewScreen> createState() =>
      _LG03TemplateReviewScreenState();
}

class _LG03TemplateReviewScreenState extends State<LG03TemplateReviewScreen> {
  final _template = TextEditingController(text: 'Brand Integration Agreement');
  final _clause =
      TextEditingController(text: 'Payment proof and approval release');
  final _change = TextEditingController(
    text: 'Add platform-verified proof state before final campaign release.',
  );
  final _reason = TextEditingController(
    text: 'Avoid ambiguity between client approval and payment verification.',
  );
  String? _error;

  @override
  void dispose() {
    _template.dispose();
    _clause.dispose();
    _change.dispose();
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = LegalPartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return LegalTwoColumn(
          left: LegalSectionCard(
            title: 'Template change form',
            icon: Icons.library_books_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _Field(controller: _template, label: 'Template'),
                _Field(controller: _clause, label: 'Clause'),
                _Field(controller: _change, label: 'Tracked change'),
                _Field(controller: _reason, label: 'Reason'),
                if (_error != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    _error!,
                    style: AppTextStyles.statusText.copyWith(
                      color: context.appColors.infoPurple,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.save_outlined,
                        label: 'Save draft',
                        compact: true,
                        onTap: () =>
                            legalSnack(context, 'Template draft saved'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.send_outlined,
                        label: store.templateSubmitted
                            ? 'Submitted'
                            : 'Submit change',
                        compact: true,
                        onTap: () => _submit(context, store),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              LegalSectionCard(
                title: 'Governance preview',
                icon: Icons.preview_outlined,
                child: Column(
                  children: [
                    LegalInfoRow(
                      icon: Icons.library_books_outlined,
                      label: 'Template',
                      value: _template.text,
                    ),
                    LegalInfoRow(
                      icon: Icons.rule_outlined,
                      label: 'Clause',
                      value: _clause.text,
                    ),
                    LegalInfoRow(
                      icon: Icons.verified_user_outlined,
                      label: 'Approval',
                      value: 'Platform admin required',
                    ),
                    LegalInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LegalSectionCard(
                title: 'Current template queue',
                icon: Icons.pending_actions_outlined,
                child: Column(
                  children: [
                    for (final item in LegalPartnerDemoData.templateChanges)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _TemplateRow(
                          template: item.template,
                          clause: item.clause,
                          status: item.status,
                        ),
                      ),
                    CoreSecondaryButton(
                      icon: Icons.article_outlined,
                      label: 'Review contract sample',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        LegalPartnerRoutes.contractReview,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, LegalPartnerDemoStore store) {
    if (_template.text.trim().length < 4 ||
        _clause.text.trim().length < 4 ||
        _change.text.trim().length < 12) {
      setState(() => _error = 'Complete template, clause and tracked change.');
      return;
    }
    setState(() => _error = null);
    store.submitTemplateChange();
    legalSnack(context, 'Template change submitted for platform approval');
  }
}

class _Field extends StatelessWidget {
  final TextEditingController controller;
  final String label;

  const _Field({required this.controller, required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        style:
            AppTextStyles.body.copyWith(color: context.appColors.textPrimary),
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
      ),
    );
  }
}

class _TemplateRow extends StatelessWidget {
  final String template;
  final String clause;
  final LegalStatus status;

  const _TemplateRow({
    required this.template,
    required this.clause,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                template,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                clause,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta
                    .copyWith(color: colors.textSecondary),
              ),
            ],
          ),
        ),
        LegalStatusChip(status: status),
      ],
    );
  }
}
