part of '../super_admin_screens.dart';

class ReviewHubScreen extends StatefulWidget {
  const ReviewHubScreen({super.key});

  @override
  State<ReviewHubScreen> createState() => _ReviewHubScreenState();
}

class _ReviewHubScreenState extends State<ReviewHubScreen> {
  Future<_ReviewHubSnapshot>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_ReviewHubSnapshot> _load() async {
    final results = await Future.wait<Object>([
      AuthScope.of(context).adminKycSubmissions(status: 'pending'),
      AdminScope.of(context).listings(force: true),
      TrustSafetyScope.of(context).adminModerationCases(force: true),
      PaymentsScope.of(context).adminProofs(force: true),
      TrustSafetyScope.of(context).adminDisputes(force: true),
    ]);
    final listings = results[1] as List<AdminListingRecordDto>;
    final moderation = results[2] as List<ModerationCaseDto>;
    final proofs = results[3] as List<PaymentProofDto>;
    final disputes = results[4] as List<DisputeDto>;
    return _ReviewHubSnapshot(
      people: (results[0] as List<verification.KycSubmission>).length,
      listings:
          listings.where((item) => item.moderationStatus == 'pending').length,
      content: moderation
          .where((item) => {'queued', 'escalated'}.contains(item.status))
          .length,
      payments: proofs.where((item) => item.status == 'pending').length,
      disputes: disputes
          .where((item) => {'open', 'escalated'}.contains(item.status))
          .length,
    );
  }

  void _refresh() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_ReviewHubSnapshot>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.fact_check_outlined,
                  title: 'Could not load review workload',
                  message: error is ApiException
                      ? error.message
                      : 'One or more admin queues are unavailable.',
                ),
                const SizedBox(height: 12),
                AdminActionButton(
                  icon: Icons.refresh_rounded,
                  label: 'Retry',
                  secondary: true,
                  onTap: _refresh,
                ),
              ],
            ),
          );
        }
        final data = snapshot.data!;
        final total = data.people +
            data.listings +
            data.content +
            data.payments +
            data.disputes;
        final queues = [
          _ReviewQueueSummary(
            label: 'People verification',
            description: 'Identity, role, business and bank documents.',
            count: data.people,
            icon: Icons.verified_user_outlined,
            route: SuperAdminRoutes.reviewHubPeople,
            tone: AdminDecisionTone.warning,
          ),
          _ReviewQueueSummary(
            label: 'Listing reviews',
            description: 'Marketplace pricing, media, ownership and policy.',
            count: data.listings,
            icon: Icons.storefront_outlined,
            route: SuperAdminRoutes.reviewHubListings,
            tone: AdminDecisionTone.info,
          ),
          _ReviewQueueSummary(
            label: 'Content safety',
            description: 'Reports, profile media and marketplace safety.',
            count: data.content,
            icon: Icons.policy_outlined,
            route: SuperAdminRoutes.reviewHubContent,
            tone: AdminDecisionTone.danger,
          ),
          _ReviewQueueSummary(
            label: 'Payment proofs',
            description: 'Proof, amount, duplicate and risk verification.',
            count: data.payments,
            icon: Icons.receipt_long_outlined,
            route: SuperAdminRoutes.paymentQueue,
            tone: AdminDecisionTone.warning,
          ),
          _ReviewQueueSummary(
            label: 'Dispute cases',
            description: 'Evidence, rulings and escalated case work.',
            count: data.disputes,
            icon: Icons.gavel_outlined,
            route: SuperAdminRoutes.disputes,
            tone: AdminDecisionTone.danger,
          ),
        ];
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSurface(
              padding: EdgeInsets.zero,
              child: Stack(
                children: [
                  Positioned(
                    left: 0,
                    top: 0,
                    bottom: 0,
                    width: 6,
                    child: ColoredBox(
                      color: total == 0
                          ? context.appColors.success
                          : context.appColors.goldMid,
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(22, 16, 16, 16),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final summary = Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headline(context, 'Cross-platform workload'),
                            const SizedBox(height: 5),
                            _text(
                              context,
                              total == 0
                                  ? 'All governed review queues are clear.'
                                  : '$total items need an admin decision '
                                      'across trust, marketplace and finance.',
                            ),
                          ],
                        );
                        final refresh = AdminActionButton(
                          icon: Icons.refresh_rounded,
                          label: 'Refresh',
                          secondary: true,
                          onTap: _refresh,
                        );
                        if (constraints.maxWidth < 620) {
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              summary,
                              const SizedBox(height: 10),
                              refresh,
                            ],
                          );
                        }
                        return Row(
                          children: [
                            Expanded(child: summary),
                            const SizedBox(width: 12),
                            refresh,
                          ],
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _ResponsiveGrid(
              minTileWidth: 240,
              childAspectRatio: 1.45,
              children: [
                for (final queue in queues)
                  _ReviewQueueControlCard(queue: queue),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ReviewHubSnapshot {
  final int people;
  final int listings;
  final int content;
  final int payments;
  final int disputes;

  const _ReviewHubSnapshot({
    required this.people,
    required this.listings,
    required this.content,
    required this.payments,
    required this.disputes,
  });
}

class _ReviewQueueSummary {
  final String label;
  final String description;
  final int count;
  final IconData icon;
  final String route;
  final AdminDecisionTone tone;

  const _ReviewQueueSummary({
    required this.label,
    required this.description,
    required this.count,
    required this.icon,
    required this.route,
    required this.tone,
  });
}

class _ReviewQueueControlCard extends StatelessWidget {
  final _ReviewQueueSummary queue;

  const _ReviewQueueControlCard({required this.queue});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = _dashboardToneColor(context, queue.tone);
    return InkWell(
      onTap: () => Navigator.pushNamed(context, queue.route),
      borderRadius: BorderRadius.circular(8),
      child: AdminSurface(
        padding: EdgeInsets.zero,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ColoredBox(
              color: tone,
              child: const SizedBox(width: 5),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(queue.icon, color: tone, size: 22),
                        const Spacer(),
                        Text(
                          '${queue.count}',
                          style: AppTextStyles.metricNumberCompact.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: queue.count == 0 ? colors.success : tone,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      queue.label,
                      style: AppTextStyles.cardTitle.copyWith(
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      queue.description,
                      maxLines: 3,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.caption.copyWith(
                        color: colors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                    const Spacer(),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Text(
                          queue.count == 0 ? 'Queue clear' : 'Open queue',
                          style: AppTextStyles.label.copyWith(
                            color: colors.goldDark,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_rounded,
                          color: colors.goldDark,
                          size: 18,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
