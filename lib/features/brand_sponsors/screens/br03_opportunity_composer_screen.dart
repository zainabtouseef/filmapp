import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';

class BR03OpportunityComposerScreen extends StatefulWidget {
  const BR03OpportunityComposerScreen({super.key});

  @override
  State<BR03OpportunityComposerScreen> createState() =>
      _BR03OpportunityComposerScreenState();
}

class _BR03OpportunityComposerScreenState
    extends State<BR03OpportunityComposerScreen> {
  final _title = TextEditingController(text: 'Nova Cola Music Video Placement');
  final _budget = TextEditingController(text: 'PKR 1.6M');
  final _usage = TextEditingController(text: 'Digital, social, 9 months');
  final _deliverables =
      TextEditingController(text: 'Hero product frame, 2 reels, 6 stills');
  final _eligibility =
      TextEditingController(text: 'Youth, music, fashion or campus projects');
  String _category = 'Product placement';
  String? _error;

  @override
  void dispose() {
    _title.dispose();
    _budget.dispose();
    _usage.dispose();
    _deliverables.dispose();
    _eligibility.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return BrandTwoColumn(
          left: BrandSectionCard(
            title: 'Opportunity builder',
            icon: Icons.campaign_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final category in [
                        'Product placement',
                        'Brand integration',
                        'Sponsorship',
                        'Launch campaign',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: CoreChip(
                            label: category,
                            selected: _category == category,
                            onTap: () => setState(() => _category = category),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                _Field(controller: _title, label: 'Opportunity title'),
                _Field(controller: _budget, label: 'Budget'),
                _Field(controller: _usage, label: 'Usage terms'),
                _Field(controller: _deliverables, label: 'Deliverables'),
                _Field(controller: _eligibility, label: 'Eligibility'),
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
                        onTap: () {
                          store.createOpportunityDraft();
                          brandSnack(context, 'Opportunity draft saved');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.publish_outlined,
                        label: 'Publish',
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
              BrandSectionCard(
                title: 'Live preview',
                icon: Icons.preview_outlined,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    BrandMediaFrame(
                      imageUrl: BrandSponsorDemoData.profile.imageUrl,
                      title: _title.text,
                      badge: _category,
                      fallbackIcon: Icons.campaign_outlined,
                      aspectRatio: 16 / 9,
                      compact: true,
                    ),
                    const SizedBox(height: 10),
                    BrandInfoRow(
                      icon: Icons.payments_outlined,
                      label: 'Budget',
                      value: _budget.text,
                    ),
                    BrandInfoRow(
                      icon: Icons.lock_clock_outlined,
                      label: 'Usage',
                      value: _usage.text,
                    ),
                    BrandInfoRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Deliverables',
                      value: _deliverables.text,
                    ),
                    BrandInfoRow(
                      icon: Icons.group_outlined,
                      label: 'Eligibility',
                      value: _eligibility.text,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Progress',
                icon: Icons.auto_graph_outlined,
                child: Column(
                  children: [
                    _ProgressRow(
                      label: 'Brief',
                      value: _title.text.trim().isEmpty ? 'Needed' : 'Ready',
                      complete: _title.text.trim().isNotEmpty,
                    ),
                    _ProgressRow(
                      label: 'Budget',
                      value: _budget.text.trim().isEmpty ? 'Needed' : 'Ready',
                      complete: _budget.text.trim().isNotEmpty,
                    ),
                    _ProgressRow(
                      label: 'Terms',
                      value: _usage.text.trim().isEmpty ? 'Needed' : 'Ready',
                      complete: _usage.text.trim().isNotEmpty,
                    ),
                    _ProgressRow(
                      label: 'Drafts',
                      value: '${store.draftsCreated}',
                      complete: true,
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

  void _submit(BuildContext context, BrandSponsorDemoStore store) {
    if (_title.text.trim().length < 6 ||
        _budget.text.trim().isEmpty ||
        _deliverables.text.trim().length < 8) {
      setState(() => _error = 'Complete title, budget and deliverables.');
      return;
    }
    setState(() => _error = null);
    store.createOpportunityDraft();
    brandSnack(context, 'Opportunity published to applications market');
    Navigator.pushNamed(context, BrandSponsorRoutes.applications);
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

class _ProgressRow extends StatelessWidget {
  final String label;
  final String value;
  final bool complete;

  const _ProgressRow({
    required this.label,
    required this.value,
    required this.complete,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Icon(
            complete
                ? Icons.check_circle_outline
                : Icons.radio_button_unchecked,
            color: complete ? colors.success : colors.iconMuted,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.right,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
