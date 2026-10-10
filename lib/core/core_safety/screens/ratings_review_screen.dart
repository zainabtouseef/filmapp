import 'package:flutter/material.dart';

import '../../auth/auth_controller.dart';
import '../../bookings/booking_models.dart';
import '../../bookings/bookings_controller.dart';
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
  bool _submitting = false;
  String? _notice;
  Future<Booking>? _bookingFuture;
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
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bookingId = widget.bookingId?.trim();
    final bookings = BookingsScope.maybeOf(context);
    if (bookingId != null && bookingId.isNotEmpty && bookings != null) {
      _bookingFuture ??= bookings.booking(bookingId);
    }
  }

  @override
  void dispose() {
    _review.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_submitting) return;
    final trustSafety = TrustSafetyScope.maybeOf(context);
    final bookingId = widget.bookingId?.trim();
    if (trustSafety == null || bookingId == null || bookingId.isEmpty) {
      showCoreSnack(context, 'Open Review from a completed live booking.');
      return;
    }
    setState(() {
      _submitting = true;
      _notice = null;
    });
    try {
      if (_privateComplaint) {
        await trustSafety.createReport({
          'entity_type': 'booking',
          'entity_id': bookingId,
          'reason': 'other',
          'description':
              '${_review.text.trim()}\nPrivate complaint from review flow.',
        });
      } else {
        await trustSafety.createReview({
          'booking_id': bookingId,
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
      if (!mounted) return;
      showCoreSuccessDialog(
        context,
        title: _privateComplaint ? 'Complaint Submitted' : 'Review Published',
        message: _privateComplaint
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
    final bookingId = widget.bookingId?.trim();
    if (bookingId == null || bookingId.isEmpty || _bookingFuture == null) {
      return const CoreScreenScaffold(
        child: CoreEmptyState(
          icon: Icons.star_outline_rounded,
          title: 'Choose a completed booking',
          message: 'Open Review from a completed live booking.',
        ),
      );
    }
    return FutureBuilder<Booking>(
      future: _bookingFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CoreScreenScaffold(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return CoreScreenScaffold(
            child: CoreEmptyState(
              icon: Icons.star_outline_rounded,
              title: 'Booking could not be loaded',
              message: 'Check your connection and reopen this review.',
              actionLabel: 'Retry',
              onAction: () => setState(() {
                _bookingFuture = BookingsScope.of(context).booking(bookingId);
              }),
            ),
          );
        }
        return _buildReview(context, snapshot.data!);
      },
    );
  }

  Widget _buildReview(BuildContext context, Booking booking) {
    final colors = context.appColors;
    final currentUserId = AuthScope.maybeOf(context)?.user?.publicId;
    final counterpart = booking.requester.publicId == currentUserId
        ? booking.provider
        : booking.requester;
    final eligible =
        booking.status == 'secured' || booking.status == 'completed';
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
          if (!eligible) ...[
            InlineNotice(
              message:
                  'Reviews open after a booking is secured or completed. Current status: ${booking.status.replaceAll('_', ' ')}.',
              tone: CoreStatusTone.warning,
            ),
            const SizedBox(height: 12),
          ],
          if (_notice != null) ...[
            InlineNotice(message: _notice!, tone: CoreStatusTone.warning),
            const SizedBox(height: 12),
          ],
          CoreGlassCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  booking.projectTitle,
                  style: AppTextStyles.cardTitle
                      .copyWith(color: colors.textPrimary),
                ),
                const SizedBox(height: 8),
                Text(
                  'Reviewing: ${counterpart.displayName} · ${booking.publicId}',
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
                const SizedBox(height: 18),
                CorePrimaryButton(
                  icon: Icons.send_rounded,
                  label: _submitting ? 'Submitting...' : 'Submit',
                  onTap: _submitting || !eligible ? null : _submit,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
