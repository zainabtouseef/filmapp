import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/actor_talent_demo_data.dart';
import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';
import '../widgets/actor_talent_components.dart';

/// AT-07 Offer Detail & Response
class AT07OfferDetailScreen extends StatelessWidget {
  final String? offerId;

  const AT07OfferDetailScreen({super.key, this.offerId});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ActorTalentDemoStore.instance,
      builder: (context, _) {
        final store = ActorTalentDemoStore.instance;
        final opportunities = ActorTalentDemoData.opportunities;
        final offer = opportunities.firstWhere(
          (item) => item.id == offerId,
          orElse: () => opportunities.first,
        );
        final status = store.opportunityStatus(offer);
        return ActorTwoColumn(
          left: ActorSectionCard(
            title: '${offer.id} Structured Offer',
            icon: Icons.description_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ActorMediaFrame(
                  imageUrl: offer.imageUrl,
                  title: offer.projectTitle,
                  badge: offer.expiry,
                  fallbackIcon: Icons.movie_filter_outlined,
                ),
                const SizedBox(height: 9),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: ActorTalentDemoData.statusLabel(status),
                      color: actorStatusColor(context, status),
                    ),
                    StatusChip(
                        label: offer.fee, color: context.appColors.goldMid),
                    StatusChip(
                        label: offer.city, color: context.appColors.infoBlue),
                  ],
                ),
                const SizedBox(height: 9),
                ActorInfoRow(
                  icon: Icons.badge_outlined,
                  label: 'Role',
                  value: offer.role,
                ),
                ActorInfoRow(
                  icon: Icons.apartment_outlined,
                  label: 'Producer',
                  value: offer.producer,
                ),
                ActorInfoRow(
                  icon: Icons.date_range_outlined,
                  label: 'Dates',
                  value: offer.dates,
                ),
                ActorInfoRow(
                  icon: Icons.star_outline_rounded,
                  label: 'Director trust',
                  value: '${offer.directorRating} rating',
                ),
                const SizedBox(height: 8),
                Text(
                  offer.notes,
                  style: AppTextStyles.body.copyWith(
                    color: context.appColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          right: ActorSectionCard(
            title: 'Response Rail',
            icon: Icons.route_outlined,
            child: Column(
              children: [
                ActorTimeline(
                  items: [
                    ('Offer received', ActorBookingStatus.sent),
                    ('Terms review', status),
                    ('Contract follows', ActorBookingStatus.contractPending),
                  ],
                ),
                const SizedBox(height: 10),
                CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: 'Accept offer',
                  compact: true,
                  onTap: () {
                    store.acceptOffer(offer.id);
                    actorSnack(context, 'Offer accepted. Terms approved.');
                  },
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.edit_note_outlined,
                  label: 'Counteroffer',
                  compact: true,
                  onTap: () => Navigator.pushNamed(
                    context,
                    ActorTalentRoutes.counteroffer,
                    arguments: offer.id,
                  ),
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.calendar_today_outlined,
                  label: 'Hold dates',
                  compact: true,
                  onTap: () {
                    store.holdDates(offer.id);
                    actorSnack(context, 'Dates held tentatively');
                  },
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Ask question',
                  compact: true,
                  onTap: () => Navigator.pushNamed(context, CoreRoutes.chat),
                ),
                const SizedBox(height: 8),
                CoreSecondaryButton(
                  icon: Icons.block_rounded,
                  label: 'Reject',
                  compact: true,
                  onTap: () => _rejectSheet(context, store, offer.id),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _rejectSheet(
    BuildContext context,
    ActorTalentDemoStore store,
    String offerId,
  ) {
    final reason = TextEditingController(text: 'Dates unavailable');
    showActorSheet(
      context,
      title: 'Reject with reason',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: reason,
            label: 'Reason',
            icon: Icons.notes_outlined,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.send_outlined,
            label: 'Send rejection',
            compact: true,
            onTap: () {
              store.rejectOffer(offerId);
              Navigator.pop(context);
              actorSnack(context, 'Rejection sent to producer');
            },
          ),
        ],
      ),
    );
  }
}
