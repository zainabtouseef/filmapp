import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../data/distribution_partner_demo_data.dart';
import '../widgets/distribution_partner_components.dart';

class DS03ReleaseCoordinationScreen extends StatefulWidget {
  const DS03ReleaseCoordinationScreen({super.key});

  @override
  State<DS03ReleaseCoordinationScreen> createState() =>
      _DS03ReleaseCoordinationScreenState();
}

class _DS03ReleaseCoordinationScreenState
    extends State<DS03ReleaseCoordinationScreen> {
  final _notes = TextEditingController(
    text: 'Pakistan theatrical first, UAE OTT after 45-day holdback.',
  );
  String? _error;

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = DistributionPartnerDemoStore.instance;
    final project = store.primaryProject;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        return DistributionTwoColumn(
          left: DistributionSectionCard(
            title: 'Project handover',
            icon: Icons.rocket_launch_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DistributionMediaFrame(
                  imageUrl: project.imageUrl,
                  title: project.title,
                  badge: project.releaseWindow,
                  fallbackIcon: Icons.movie_filter_outlined,
                  aspectRatio: 16 / 8.5,
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        project.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.metricNumberCompact.copyWith(
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                    DistributionStatusChip(
                        status: store.projectStatus(project)),
                  ],
                ),
                const SizedBox(height: 7),
                Text(
                  '${project.producer} - ${project.territories} - ${project.releaseWindow}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                DistributionProgressMeter(
                  label: 'Release handover readiness',
                  percent: store.handoverProgress,
                ),
                const SizedBox(height: 12),
                for (final item in DistributionPartnerDemoData.handoverItems)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: DistributionChecklistTile(
                      title: item.label,
                      subtitle: item.detail,
                      checked: store.completedHandover.contains(item.id),
                      mandatory: item.mandatory,
                      onTap: () => store.toggleHandover(item.id),
                    ),
                  ),
                TextField(
                  controller: _notes,
                  maxLines: 3,
                  style: AppTextStyles.body.copyWith(
                    color: colors.textPrimary,
                  ),
                  decoration: InputDecoration(
                    labelText: 'Release coordination note',
                    hintText: 'Add deadline, approval or territory notes',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
                if (_error != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    _error!,
                    style: AppTextStyles.statusText.copyWith(
                      color: colors.infoPurple,
                    ),
                  ),
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.save_outlined,
                        label: 'Save draft',
                        compact: true,
                        onTap: () {
                          setState(() => _error = null);
                          store.saveReleaseDraft();
                          distributionSnack(context, 'Release draft saved');
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: Icons.send_outlined,
                        label: 'Submit',
                        compact: true,
                        onTap: () => _submit(context, store),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              DistributionSectionCard(
                title: 'Status context',
                icon: Icons.fact_check_outlined,
                child: Column(
                  children: [
                    DistributionInfoRow(
                      icon: Icons.event_available_outlined,
                      label: 'Release window',
                      value: project.releaseWindow,
                    ),
                    DistributionInfoRow(
                      icon: Icons.public_outlined,
                      label: 'Territories',
                      value: project.territories,
                    ),
                    DistributionInfoRow(
                      icon: Icons.inventory_2_outlined,
                      label: 'Missing items',
                      value: project.missingItems,
                    ),
                    DistributionInfoRow(
                      icon: Icons.history_outlined,
                      label: 'Audit events',
                      value: '${store.auditEvents}',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: 'Open release chat',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.chat),
                    ),
                    const SizedBox(height: 8),
                    CoreSecondaryButton(
                      icon: Icons.article_outlined,
                      label: 'Open contract',
                      compact: true,
                      onTap: () =>
                          Navigator.pushNamed(context, CoreRoutes.contract),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              DistributionSectionCard(
                title: 'Other release windows',
                icon: Icons.event_note_outlined,
                child: Column(
                  children: [
                    for (final item
                        in DistributionPartnerDemoData.projects.where(
                      (item) => item.id != project.id,
                    ))
                      Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _ReleaseMiniRow(
                          title: item.title,
                          subtitle: '${item.producer} - ${item.releaseWindow}',
                          status: store.projectStatus(item),
                        ),
                      ),
                    CoreSecondaryButton(
                      icon: Icons.analytics_outlined,
                      label: 'Open reporting',
                      compact: true,
                      onTap: () => Navigator.pushNamed(
                        context,
                        '/distribution/reports',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _submit(BuildContext context, DistributionPartnerDemoStore store) {
    if (!store.handoverReady || _notes.text.trim().length < 12) {
      setState(
        () => _error =
            'Complete required handover items and add a coordination note.',
      );
      return;
    }
    setState(() => _error = null);
    store.submitReleaseHandover();
    distributionSnack(context, 'Release handover submitted');
  }
}

class _ReleaseMiniRow extends StatelessWidget {
  final String title;
  final String subtitle;
  final dynamic status;

  const _ReleaseMiniRow({
    required this.title,
    required this.subtitle,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Row(
      children: [
        Icon(Icons.rocket_launch_outlined, color: colors.goldDark, size: 19),
        const SizedBox(width: 9),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardLabel.copyWith(
                  color: colors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Text(
                subtitle,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        DistributionStatusChip(status: status),
      ],
    );
  }
}
