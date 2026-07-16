import 'package:flutter/material.dart';

import '../../core_ui/widgets/core_widgets.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';

class RatingsReviewScreen extends StatefulWidget {
  const RatingsReviewScreen({super.key});

  @override
  State<RatingsReviewScreen> createState() => _RatingsReviewScreenState();
}

class _RatingsReviewScreenState extends State<RatingsReviewScreen> {
  int _rating = 4;
  bool _privateComplaint = false;
  bool _evidenceUploaded = false;
  final _review = TextEditingController();
  final Set<String> _chips = {'Professionalism', 'Communication'};

  final _categories = const [
    'Punctuality',
    'Professionalism',
    'Quality',
    'Communication',
    'Preparedness',
    'Respectful Conduct',
  ];

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  void _submit() {
    showCoreSuccessDialog(
      context,
      title: _privateComplaint ? 'Complaint Submitted' : 'Review Published',
      message: _privateComplaint
          ? 'Your private admin complaint has been routed to support moderation.'
          : 'The public review updated Ali Khan’s dummy trust badge preview.',
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return CoreScreenScaffold(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CoreAppHeader(
            title: 'Ratings & Review',
            subtitle:
                'Booking status: Closed. Share public feedback or a private complaint.',
            icon: Icons.star_outline_rounded,
          ),
          const SizedBox(height: 18),
          CoreGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TVC Shoot — Lahore',
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reviewing: Ali Khan · Actor / Talent · BK-2048',
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textSecondary),
                ),
                const SizedBox(height: 18),
                RatingStars(
                    rating: _rating,
                    onChanged: (value) => setState(() => _rating = value)),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 9,
                  runSpacing: 9,
                  children: _categories
                      .map(
                        (category) => CoreChip(
                          label: category,
                          selected: _chips.contains(category),
                          onTap: () => setState(() {
                            if (_chips.contains(category)) {
                              _chips.remove(category);
                            } else {
                              _chips.add(category);
                            }
                          }),
                        ),
                      )
                      .toList(),
                ),
                const SizedBox(height: 16),
                CoreTextField(
                  controller: _review,
                  label: 'Text review',
                  icon: Icons.rate_review_outlined,
                  maxLines: 5,
                ),
                SwitchListTile.adaptive(
                  contentPadding: EdgeInsets.zero,
                  value: _privateComplaint,
                  activeThumbColor: colors.goldMid,
                  onChanged: (value) =>
                      setState(() => _privateComplaint = value),
                  title: Text(
                    'Private complaint',
                    style: AppTextStyles.label
                        .copyWith(color: colors.textPrimary),
                  ),
                  subtitle: Text(
                    'Route to admin support instead of a public review',
                    style: AppTextStyles.caption
                        .copyWith(color: colors.textSecondary),
                  ),
                ),
                if (_privateComplaint) ...[
                  const SizedBox(height: 8),
                  UploadCard(
                    title: 'Evidence upload',
                    subtitle: 'Attach screenshots, documents or media',
                    uploaded: _evidenceUploaded,
                    onTap: () => setState(() => _evidenceUploaded = true),
                  ),
                ],
                const SizedBox(height: 18),
                CorePrimaryButton(
                  icon: Icons.send_rounded,
                  label: 'Submit',
                  onTap: _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
