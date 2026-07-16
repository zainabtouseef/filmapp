import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/crew_services_demo_data.dart';
import '../models/crew_services_models.dart';
import '../widgets/crew_services_components.dart';

class CR07RatingsWorkHistoryScreen extends StatefulWidget {
  const CR07RatingsWorkHistoryScreen({super.key});

  @override
  State<CR07RatingsWorkHistoryScreen> createState() =>
      _CR07RatingsWorkHistoryScreenState();
}

class _CR07RatingsWorkHistoryScreenState
    extends State<CR07RatingsWorkHistoryScreen> {
  String _query = '';
  String _filter = 'All';

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final reviews = _reviews().toList();
    final disputeCount = CrewServicesDemoData.ledger
        .where((item) => item.status == CrewBookingStatus.disputed)
        .length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricActionRail(
          items: [
            MetricActionItem(
              value: CrewServicesDemoData.profile.rating.toStringAsFixed(1),
              icon: Icons.star_outline_rounded,
              title: 'Overall',
              subtitle: 'Current',
              accentColor: crewToneColor(context, CrewTone.purple),
            ),
            MetricActionItem(
              value: '74',
              icon: Icons.check_circle_outline,
              title: 'Completed',
              subtitle: 'Current',
              accentColor: crewToneColor(context, CrewTone.green),
            ),
            MetricActionItem(
              value: '68%',
              icon: Icons.replay_outlined,
              title: 'Repeat score',
              subtitle: 'Current',
              accentColor: crewToneColor(context, CrewTone.blue),
            ),
            MetricActionItem(
              value: '$disputeCount',
              icon: Icons.verified_user_outlined,
              title: 'Disputes',
              subtitle: 'Current',
              accentColor: crewToneColor(
                context,
                disputeCount > 0 ? CrewTone.danger : CrewTone.gold,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        CrewSectionCard(
          title: 'Work history filters',
          icon: Icons.search_rounded,
          selected: true,
          child: Column(
            children: [
              _SearchField(
                  onChanged: (value) => setState(() => _query = value)),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in [
                      'All',
                      'Drama',
                      'Commercial',
                      'Brand'
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label: filter,
                          selected: _filter == filter,
                          onTap: () {
                            setState(() => _filter = filter);
                            crewSnack(context, '$filter filter applied');
                          },
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CrewTwoColumn(
          left: CrewSectionCard(
            title: 'Director reviews',
            icon: Icons.rate_review_outlined,
            child: reviews.isEmpty
                ? CoreEmptyState(
                    icon: Icons.search_off_rounded,
                    title: 'No reviews found',
                    message: 'Adjust the filter or search text.',
                    actionLabel: 'Clear',
                    onAction: () => setState(() {
                      _query = '';
                      _filter = 'All';
                    }),
                  )
                : Column(
                    children: [
                      for (final review in reviews)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: _ReviewRow(review: review),
                        ),
                    ],
                  ),
          ),
          right: CrewSectionCard(
            title: 'Ratings breakdown',
            icon: Icons.stars_outlined,
            child: Column(
              children: [
                _RatingBar(label: 'Quality', value: 4.9),
                _RatingBar(label: 'Punctuality', value: 4.8),
                _RatingBar(label: 'Communication', value: 4.7),
                _RatingBar(label: 'Safety', value: 4.9),
                const SizedBox(height: 10),
                StatusChip(
                  label: disputeCount > 0
                      ? '$disputeCount OPEN DISPUTE${disputeCount > 1 ? 'S' : ''}'
                      : 'DISPUTE-FREE TRUST',
                  color: disputeCount > 0 ? colors.danger : colors.success,
                  icon: Icons.verified_user_outlined,
                ),
                const SizedBox(height: 12),
                CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Report review issue',
                  compact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    CoreRoutes.report,
                    arguments: 'Crew review issue',
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Iterable<CrewReview> _reviews() {
    final lower = _query.trim().toLowerCase();
    return CrewServicesDemoData.reviews.where((review) {
      final credits = CrewServicesDemoData.credits
          .where((credit) => credit.title == review.project)
          .toList();
      final category = credits.isNotEmpty ? credits.first.category : '';
      final matchesFilter = _filter == 'All' ||
          category.toLowerCase().contains(_filter.toLowerCase());
      final matchesQuery = '${review.project} ${review.director} ${review.note}'
          .toLowerCase()
          .contains(lower);
      return matchesFilter && matchesQuery;
    });
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search projects, directors, notes...',
        hintStyle: AppTextStyles.smallMeta.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon:
            Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
        filled: true,
        fillColor:
            colors.surface.withValues(alpha: colors.isLight ? 0.74 : 0.36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.goldMid),
        ),
      ),
    );
  }
}

class _ReviewRow extends StatelessWidget {
  final CrewReview review;

  const _ReviewRow({required this.review});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  review.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
              StatusChip(
                label: review.rating.toStringAsFixed(1),
                color: colors.goldMid,
                icon: Icons.star_outline_rounded,
              ),
            ],
          ),
          const SizedBox(height: 5),
          Text(
            '${review.director} - ${review.note}',
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style:
                AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}

class _RatingBar extends StatelessWidget {
  final String label;
  final double value;

  const _RatingBar({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Text(
            value.toStringAsFixed(1),
            style: AppTextStyles.statusText.copyWith(color: colors.goldDark),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 92,
            child: LinearProgressIndicator(
              value: value / 5,
              minHeight: 7,
              borderRadius: BorderRadius.circular(999),
              backgroundColor: colors.border,
              color: colors.goldMid,
            ),
          ),
        ],
      ),
    );
  }
}
