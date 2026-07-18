import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../data/model_extension_demo_data.dart';
import '../models/model_extension_models.dart';
import '../widgets/model_extension_components.dart';

/// MD-02 Usage Rights Manager
class MD02UsageRightsScreen extends StatefulWidget {
  const MD02UsageRightsScreen({super.key});

  @override
  State<MD02UsageRightsScreen> createState() => _MD02UsageRightsScreenState();
}

class _MD02UsageRightsScreenState extends State<MD02UsageRightsScreen> {
  String query = '';
  String filter = 'All';
  Future<List<ModelUsageRightDto>>? _rightsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    _rightsFuture ??= specialist?.modelUsageRights(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModelExtensionDemoStore.instance,
      builder: (context, _) {
        final store = ModelExtensionDemoStore.instance;
        final rights = store.usageRights.where((right) {
          final platform = ModelExtensionDemoData.platformLabel(right.platform);
          final matchesQuery = query.trim().isEmpty ||
              platform.toLowerCase().contains(query.toLowerCase()) ||
              right.territory.toLowerCase().contains(query.toLowerCase()) ||
              right.id.toLowerCase().contains(query.toLowerCase());
          final matchesFilter = filter == 'All' ||
              (filter == 'Exclusive' && right.exclusive) ||
              (filter == 'Locked' &&
                  right.status == ModelUsageStatus.contractLocked) ||
              (filter == 'Draft' && right.status == ModelUsageStatus.draft);
          return matchesQuery && matchesFilter;
        }).toList();
        return Column(
          children: [
            ActorSearchFilterBar(
              query: query,
              onQueryChanged: (value) => setState(() => query = value),
              filters: const ['All', 'Exclusive', 'Locked', 'Draft'],
              selectedFilter: filter,
              onFilterChanged: (value) => setState(() => filter = value),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Mandatory Usage Blocks',
              icon: Icons.policy_outlined,
              actionText: 'Add right',
              onActionTap: () async {
                store.addUsageRight();
                final specialist = SpecialistScope.maybeOf(context);
                if (specialist != null) {
                  try {
                    await specialist.createModelUsageRight({
                      'platform': 'instagram',
                      'territory': 'Pakistan',
                      'duration_months': 6,
                      'exclusive': false,
                      'status': 'active',
                    });
                    if (mounted) {
                      setState(() => _rightsFuture =
                          specialist.modelUsageRights(force: true));
                    }
                  } catch (error) {
                    if (context.mounted) {
                      actorSnack(context, 'Live usage right skipped: $error');
                    }
                  }
                }
                if (!context.mounted) return;
                actorSnack(context, 'Draft usage right added');
              },
              child: Column(
                children: [
                  if (_rightsFuture != null)
                    FutureBuilder<List<ModelUsageRightDto>>(
                      future: _rightsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live usage rights...',
                              icon: Icons.hourglass_top_rounded,
                            ),
                          );
                        }
                        final rows = snapshot.data ?? const [];
                        if (rows.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                'Live usage rights connected: ${rows.length} right(s), latest ${rows.first.platform}/${rows.first.territory}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  if (rights.isEmpty)
                    const CoreEmptyState(
                      icon: Icons.policy_outlined,
                      title: 'No usage rights',
                      message: 'Change filter or add a draft right.',
                    )
                  else
                    Column(
                      children: [
                        for (final right in rights)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _UsageRightCard(right: right),
                          ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _UsageRightCard extends StatelessWidget {
  final ModelUsageRight right;

  const _UsageRightCard({required this.right});

  @override
  Widget build(BuildContext context) {
    final store = ModelExtensionDemoStore.instance;
    final colors = context.appColors;
    final locked = right.status == ModelUsageStatus.contractLocked;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: colors.goldDark, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  ModelExtensionDemoData.platformLabel(right.platform),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              modelUsageStatusChip(context, right.status),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: right.id, color: colors.infoBlue),
              StatusChip(label: right.territory, color: colors.goldMid),
              StatusChip(label: right.duration, color: colors.infoPurple),
              StatusChip(
                label: right.exclusive ? 'Exclusive' : 'Non-exclusive',
                color: right.exclusive ? colors.success : colors.textSecondary,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.swap_horiz_outlined,
                  label: 'Exclusive',
                  compact: true,
                  onTap: locked
                      ? null
                      : () {
                          store.toggleUsageExclusive(right.id);
                          actorSnack(context, 'Usage exclusivity updated');
                        },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.lock_outline,
                  label: locked ? 'Locked' : 'Lock',
                  compact: true,
                  onTap: locked
                      ? null
                      : () {
                          store.lockUsageRight(right.id);
                          actorSnack(context,
                              'Usage right locked into contract rules');
                        },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
