import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_live_widgets.dart';

class LG01LegalDashboardScreen extends StatefulWidget {
  const LG01LegalDashboardScreen({super.key});

  @override
  State<LG01LegalDashboardScreen> createState() =>
      _LG01LegalDashboardScreenState();
}

class _LG01LegalDashboardScreenState extends State<LG01LegalDashboardScreen> {
  Future<_LegalDashboardBundle>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_LegalDashboardBundle>? _load() {
    final contracts = ContractsScope.maybeOf(context);
    if (contracts == null) return null;
    return Future.wait([
      contracts.legalReviews(force: true),
      contracts.contracts(force: true),
    ]).then(
      (values) => _LegalDashboardBundle(
        reviews: values[0] as List<LegalReviewDto>,
        contracts: values[1] as List<CineContract>,
      ),
    );
  }

  void _refresh() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const PortalDashboardPage(
        children: [
          CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view legal reviews',
            message: 'Legal reviews and contracts are loaded from the server.',
          ),
        ],
      );
    }

    return FutureBuilder<_LegalDashboardBundle>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PortalDashboardPage(
            showLiveStrip: false,
            children: [SkeletonCard(height: 460)],
          );
        }
        if (snapshot.hasError) {
          return PortalDashboardPage(
            showLiveStrip: false,
            children: [
              LegalLoadError(
                message: 'Could not load legal dashboard',
                onRetry: _refresh,
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final openReviews = data.reviews
            .where(
              (review) => !{'approved', 'completed', 'closed'}
                  .contains(review.status.toLowerCase()),
            )
            .length;
        final highRisk = data.reviews
            .where((review) => review.risk.toLowerCase() == 'high')
            .length;
        final displayName = AuthScope.maybeOf(context)?.user?.displayName;
        final name = (displayName == null || displayName.trim().isEmpty)
            ? 'Legal counsel'
            : displayName.trim();

        return PortalDashboardPage(
          children: [
            PortalHeroCard(
              initials: _initialsFor(name),
              name: name,
              badgeLabel: 'Verified counsel',
              stats: [
                PortalHeroStat(
                  value: '${data.reviews.length}',
                  label: 'Reviews',
                ),
                PortalHeroStat(
                  value: '${data.contracts.length}',
                  label: 'Contracts',
                ),
                PortalHeroStat(value: '$highRisk', label: 'High risk'),
              ],
              ctaLabel: 'Refresh',
              onCta: _refresh,
            ),
            const PortalStaggeredReveal(
              children: [PortalLiveClockWidget()],
            ),
            PortalCommandCenter(
              eyebrow: 'Legal operations',
              title: 'Review Command Centre',
              subtitle:
                  'Contracts, clause risks and decisions in one governed view.',
              icon: Icons.gavel_outlined,
              primaryTitle:
                  data.reviews.isEmpty ? 'Review overview' : 'Latest review',
              primary: data.reviews.isEmpty
                  ? const CoreEmptyState(
                      icon: Icons.rate_review_outlined,
                      title: 'No live legal reviews',
                      message: 'Review requests appear here when submitted.',
                    )
                  : _LegalReviewSummary(review: data.reviews.first),
              actionLabel: 'Open queue',
              onAction: () => Navigator.pushNamed(
                context,
                LegalPartnerRoutes.contractReview,
              ),
              actions: [
                PortalCommandAction(
                  icon: Icons.rate_review_outlined,
                  title: 'Contract reviews',
                  subtitle: 'Open review requests and clause decisions',
                  value: '$openReviews',
                  onTap: () => Navigator.pushNamed(
                    context,
                    LegalPartnerRoutes.contractReview,
                  ),
                ),
                PortalCommandAction(
                  icon: Icons.description_outlined,
                  title: 'Template review',
                  subtitle: 'Approve reusable agreement language',
                  onTap: () => Navigator.pushNamed(
                    context,
                    LegalPartnerRoutes.templateReview,
                  ),
                ),
                PortalCommandAction(
                  icon: Icons.note_add_outlined,
                  title: 'Addendum review',
                  subtitle: 'Track changes to signed agreements',
                  onTap: () => Navigator.pushNamed(
                    context,
                    LegalPartnerRoutes.addendumReview,
                  ),
                ),
                PortalCommandAction(
                  icon: Icons.history_outlined,
                  title: 'History and billing',
                  subtitle: 'Completed reviews and service records',
                  onTap: () => Navigator.pushNamed(
                    context,
                    LegalPartnerRoutes.billing,
                  ),
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _LegalReviewSummary extends StatelessWidget {
  final LegalReviewDto review;

  const _LegalReviewSummary({required this.review});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PortalCommandDataRow(
          icon: Icons.badge_outlined,
          label: 'Requested by',
          value: review.requestedBy.displayName,
        ),
        PortalCommandDataRow(
          icon: Icons.description_outlined,
          label: 'Contract',
          value: review.contractType,
        ),
        PortalCommandDataRow(
          icon: Icons.warning_amber_outlined,
          label: 'Risk',
          value: review.risk,
        ),
        PortalCommandDataRow(
          icon: Icons.schedule_outlined,
          label: 'SLA',
          value: review.slaLabel,
        ),
      ],
    );
  }
}

class _LegalDashboardBundle {
  final List<LegalReviewDto> reviews;
  final List<CineContract> contracts;

  const _LegalDashboardBundle({
    required this.reviews,
    required this.contracts,
  });
}

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
