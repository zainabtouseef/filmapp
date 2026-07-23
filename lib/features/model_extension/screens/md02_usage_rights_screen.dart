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

class MD02UsageRightsScreen extends StatefulWidget {
  const MD02UsageRightsScreen({super.key});

  @override
  State<MD02UsageRightsScreen> createState() => _MD02UsageRightsScreenState();
}

class _MD02UsageRightsScreenState extends State<MD02UsageRightsScreen> {
  String _query = '';
  String _filter = 'All';
  Future<List<ModelUsageRightDto>>? _rightsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _reload(initial: true);
  }

  void _reload({bool initial = false}) {
    if (initial && _rightsFuture != null) return;
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    _rightsFuture = specialist.modelUsageRights(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ActorSearchFilterBar(
          query: _query,
          onQueryChanged: (value) => setState(() => _query = value),
          filters: const ['All', 'Exclusive', 'Locked', 'Draft'],
          selectedFilter: _filter,
          onFilterChanged: (value) => setState(() => _filter = value),
        ),
        const SizedBox(height: 12),
        ActorSectionCard(
          title: 'Usage Rights Library',
          icon: Icons.policy_outlined,
          actionText: 'Add right',
          onActionTap: _showAddRight,
          child: _rightsFuture == null
              ? _PreviewRights(query: _query, filter: _filter)
              : FutureBuilder<List<ModelUsageRightDto>>(
                  future: _rightsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const InlineNotice(
                        message: 'Loading usage rights...',
                        icon: Icons.hourglass_top_rounded,
                      );
                    }
                    if (snapshot.hasError) {
                      return Column(
                        children: [
                          const InlineNotice(
                            message:
                                'Live rights are unavailable. Preview records are shown.',
                            icon: Icons.cloud_off_outlined,
                          ),
                          const SizedBox(height: 10),
                          _PreviewRights(query: _query, filter: _filter),
                        ],
                      );
                    }
                    final rows = (snapshot.data ?? const [])
                        .where(_matchesLiveFilter)
                        .toList();
                    if (rows.isEmpty) {
                      return CoreEmptyState(
                        icon: Icons.policy_outlined,
                        title: 'No matching usage rights',
                        message:
                            'Add a territory and platform rule or change the filter.',
                        actionLabel: 'Add usage right',
                        onAction: _showAddRight,
                      );
                    }
                    return Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                '${snapshot.data!.length} live licensing rule(s) connected to offers and model releases.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        ),
                        for (final right in rows)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: _LiveUsageRightCard(
                              right: right,
                              onExclusiveChanged: (value) =>
                                  _updateRight(right, {'exclusive': value}),
                              onStatusChanged: (status) =>
                                  _updateRight(right, {'status': status}),
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

  bool _matchesLiveFilter(ModelUsageRightDto right) {
    final query = _query.trim().toLowerCase();
    final matchesQuery = query.isEmpty ||
        '${right.platform} ${right.territory} ${right.publicId}'
            .toLowerCase()
            .contains(query);
    final matchesFilter = switch (_filter) {
      'Exclusive' => right.exclusive,
      'Locked' => right.status == 'contract_locked',
      'Draft' => right.status == 'draft',
      _ => true,
    };
    return matchesQuery && matchesFilter;
  }

  Future<void> _updateRight(
    ModelUsageRightDto right,
    Map<String, dynamic> body,
  ) async {
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null) return;
    try {
      await specialist.updateModelUsageRight(right.publicId, body);
      if (!mounted) return;
      setState(_reload);
      actorSnack(context, 'Usage right updated');
    } catch (error) {
      if (mounted) actorSnack(context, 'Could not update usage right: $error');
    }
  }

  void _showAddRight() {
    final territory = TextEditingController(text: 'Pakistan');
    final months = TextEditingController(text: '6');
    var platform = 'social_media';
    var exclusive = false;
    showActorSheet(
      context,
      title: 'Add usage right',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Platform',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    'social_media',
                    'website',
                    'print',
                    'billboard',
                    'tv',
                    'packaging',
                  ])
                    CoreChip(
                      label: _title(value),
                      selected: platform == value,
                      onTap: () => setSheetState(() => platform = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              CoreTextField(
                controller: territory,
                label: 'Territory',
                icon: Icons.public_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: months,
                label: 'Duration in months',
                icon: Icons.date_range_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Exclusive category use'),
                subtitle: const Text('Blocks competing work during this term.'),
                value: exclusive,
                onChanged: (value) => setSheetState(() => exclusive = value),
              ),
              const SizedBox(height: 10),
              CorePrimaryButton(
                icon: Icons.add_rounded,
                label: 'Create usage right',
                onTap: () async {
                  final duration = int.tryParse(months.text.trim());
                  if (territory.text.trim().isEmpty ||
                      duration == null ||
                      duration < 1) {
                    actorSnack(context, 'Enter territory and valid duration');
                    return;
                  }
                  final specialist = SpecialistScope.maybeOf(context);
                  if (specialist == null) {
                    ModelExtensionDemoStore.instance.addUsageRight();
                    Navigator.pop(context);
                    return;
                  }
                  try {
                    await specialist.createModelUsageRight({
                      'platform': platform,
                      'territory': territory.text.trim(),
                      'duration_months': duration,
                      'exclusive': exclusive,
                      'status': 'active',
                    });
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    actorSnack(this.context, 'Usage right created');
                  } catch (error) {
                    if (context.mounted) {
                      actorSnack(context, 'Could not create right: $error');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      territory.dispose();
      months.dispose();
    });
  }
}

class _LiveUsageRightCard extends StatelessWidget {
  final ModelUsageRightDto right;
  final ValueChanged<bool> onExclusiveChanged;
  final ValueChanged<String> onStatusChanged;

  const _LiveUsageRightCard({
    required this.right,
    required this.onExclusiveChanged,
    required this.onStatusChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final locked = right.status == 'contract_locked';
    final statusColor = switch (right.status) {
      'active' => colors.success,
      'contract_locked' => colors.goldMid,
      'disputed' => colors.danger,
      _ => colors.infoBlue,
    };
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: locked ? colors.goldMid : colors.border,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Icon(Icons.verified_outlined, color: colors.goldDark, size: 20),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  _title(right.platform),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: _title(right.status).toUpperCase(),
                color: statusColor,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(label: right.territory, color: colors.infoBlue),
              StatusChip(
                label: right.durationMonths == null
                    ? 'Open duration'
                    : '${right.durationMonths} months',
                color: colors.infoPurple,
              ),
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
                  label: right.exclusive ? 'Remove exclusive' : 'Exclusive',
                  compact: true,
                  onTap: locked
                      ? null
                      : () => onExclusiveChanged(!right.exclusive),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: locked ? Icons.lock_rounded : Icons.lock_outline,
                  label: locked ? 'Locked' : 'Lock for contract',
                  compact: true,
                  onTap:
                      locked ? null : () => onStatusChanged('contract_locked'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewRights extends StatelessWidget {
  final String query;
  final String filter;

  const _PreviewRights({
    required this.query,
    required this.filter,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: ModelExtensionDemoStore.instance,
      builder: (context, _) {
        final store = ModelExtensionDemoStore.instance;
        final rows = store.usageRights.where((right) {
          final platform = ModelExtensionDemoData.platformLabel(right.platform);
          final matchesQuery = query.trim().isEmpty ||
              '$platform ${right.territory} ${right.id}'
                  .toLowerCase()
                  .contains(query.toLowerCase());
          final matchesFilter = filter == 'All' ||
              (filter == 'Exclusive' && right.exclusive) ||
              (filter == 'Locked' &&
                  right.status == ModelUsageStatus.contractLocked) ||
              (filter == 'Draft' && right.status == ModelUsageStatus.draft);
          return matchesQuery && matchesFilter;
        });
        return Column(
          children: [
            const Padding(
              padding: EdgeInsets.only(bottom: 10),
              child: InlineNotice(
                message:
                    'Preview mode. Sign in to edit live licensing records.',
                icon: Icons.visibility_outlined,
              ),
            ),
            for (final right in rows)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _PreviewUsageRightCard(right: right),
              ),
          ],
        );
      },
    );
  }
}

class _PreviewUsageRightCard extends StatelessWidget {
  final ModelUsageRight right;

  const _PreviewUsageRightCard({required this.right});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(Icons.policy_outlined, color: colors.goldDark, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ModelExtensionDemoData.platformLabel(right.platform),
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  '${right.territory} · ${right.duration}',
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          modelUsageStatusChip(context, right.status),
        ],
      ),
    );
  }
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
