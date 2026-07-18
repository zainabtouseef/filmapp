import 'package:flutter/material.dart';

import '../../core_ui/widgets/core_widgets.dart';
import '../../network/api_exception.dart';
import '../../theme/app_color_scheme.dart';
import '../../theme/app_text_styles.dart';
import '../../trust_safety/trust_safety_controller.dart';

class RatingsReviewScreen extends StatefulWidget {
  final String? bookingId;

  const RatingsReviewScreen({super.key, this.bookingId});

  @override
  State<RatingsReviewScreen> createState() => _RatingsReviewScreenState();
}

class _RatingsReviewScreenState extends State<RatingsReviewScreen> {
  int _rating = 4;
  bool _privateComplaint = false;
  bool _evidenceUploaded = false;
  bool _submitting = false;
  String? _notice;
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

  Future<void> _submit() async {
    if (_submitting) return;
    final trustSafety = TrustSafetyScope.maybeOf(context);
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      if (trustSafety != null && widget.bookingId != null) {
        if (_privateComplaint) {
          await trustSafety.createReport({
            'entity_type': 'booking',
            'entity_id': widget.bookingId,
            'reason': 'other',
            'description':
                '${_review.text.trim()}\nPrivate complaint from review flow. Evidence attached: $_evidenceUploaded',
          });
        } else {
          await trustSafety.createReview({
            'booking_id': widget.bookingId,
            'rating': _rating,
            'text': _review.text.trim(),
            'dimensions': [
              for (final chip in _chips)
                {
                  'dimension': chip.toLowerCase().replaceAll(' ', '_'),
                  'score': _rating
                },
            ],
          });
        }
      } else {
        setState(() {
          _notice =
              'Open this review from a completed live booking to publish it to the server.';
        });
      }
      if (!mounted) return;
      showCoreSuccessDialog(
        context,
        title: _privateComplaint ? 'Complaint Submitted' : 'Review Published',
        message: widget.bookingId == null
            ? 'Your review is saved as a local preview until a booking id is provided.'
            : _privateComplaint
                ? 'Your private admin complaint has been routed to support moderation.'
                : 'The public review updated the user’s live trust badge.',
      );
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } catch (_) {
      if (mounted) showCoreSnack(context, 'Could not submit review right now.');
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
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
          if (_notice != null) ...[
            InlineNotice(message: _notice!, tone: CoreStatusTone.warning),
            const SizedBox(height: 12),
          ],
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
                    style:
                        AppTextStyles.label.copyWith(color: colors.textPrimary),
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
                  label: _submitting ? 'Submitting...' : 'Submit',
                  onTap: _submitting ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
