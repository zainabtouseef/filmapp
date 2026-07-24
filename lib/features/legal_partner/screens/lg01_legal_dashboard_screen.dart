import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/contracts/contract_models.dart';
import '../../../core/contracts/contracts_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../routes/legal_partner_routes.dart';
import '../widgets/legal_live_widgets.dart';
import '../widgets/legal_partner_components.dart';

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

  void _refresh() => setState(() => _future = _load());

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const PersonalDashboardKpiStrip(),
        const SizedBox(height: 12),
        LegalSectionCard(
          title: 'Legal desk',
          icon: Icons.gavel_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: _future == null
              ? const CoreEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to view legal reviews',
                  message:
                      'Legal reviews and contracts are loaded from the server.',
                )
              : FutureBuilder<_LegalDashboardBundle>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonCard(height: 460);
                    }
                    if (snapshot.hasError) {
                      return LegalLoadError(
                        message: 'Could not load legal dashboard',
                        onRetry: _refresh,
                      );
                    }
                    final data = snapshot.data!;
                    final openReviews = data.reviews
                        .where((review) => !{
                              'approved',
                              'completed',
                              'closed',
                            }.contains(review.status.toLowerCase()))
                        .length;
                    final highRisk = data.reviews
                        .where((review) => review.risk.toLowerCase() == 'high')
                        .length;
                    return Column(
                      children: [
                        MetricActionRail(
                          items: [
                            MetricActionItem(
                              icon: Icons.rate_review_outlined,
                              value: '${data.reviews.length}',
                              title: 'Reviews',
                              subtitle: '$openReviews open',
                              accentColor: context.appColors.goldDark,
                              onTap: () => Navigator.pushNamed(
                                context,
                                LegalPartnerRoutes.contractReview,
                              ),
                            ),
                            MetricActionItem(
                              icon: Icons.warning_amber_outlined,
                              value: '$highRisk',
                              title: 'High risk',
                              subtitle: 'Live reviews',
                              accentColor: context.appColors.danger,
                            ),
                            MetricActionItem(
                              icon: Icons.description_outlined,
                              value: '${data.contracts.length}',
                              title: 'Contracts',
                              subtitle: 'Live records',
                              accentColor: context.appColors.success,
                              onTap: () => Navigator.pushNamed(
                                context,
                                LegalPartnerRoutes.billing,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        LegalTwoColumn(
                          left: LegalSectionCard(
                            title: 'Latest review',
                            icon: Icons.rate_review_outlined,
                            child: data.reviews.isEmpty
                                ? const CoreEmptyState(
                                    icon: Icons.rate_review_outlined,
                                    title: 'No live legal reviews',
                                    message:
                                        'Seed legal review rows in MySQL to populate this dashboard.',
                                  )
                                : LegalReviewCard(review: data.reviews.first),
                          ),
                          right: LegalSectionCard(
                            title: 'Operational links',
                            icon: Icons.route_outlined,
                            child: Column(
                              children: [
                                CorePrimaryButton(
                                  icon: Icons.rate_review_outlined,
                                  label: 'Review queue',
                                  compact: true,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    LegalPartnerRoutes.contractReview,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                CoreSecondaryButton(
                                  icon: Icons.history_outlined,
                                  label: 'History',
                                  compact: true,
                                  onTap: () => Navigator.pushNamed(
                                    context,
                                    LegalPartnerRoutes.billing,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
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
