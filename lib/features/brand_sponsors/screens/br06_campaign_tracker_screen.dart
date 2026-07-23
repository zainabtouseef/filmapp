import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR06CampaignTrackerScreen extends StatefulWidget {
  const BR06CampaignTrackerScreen({super.key});

  @override
  State<BR06CampaignTrackerScreen> createState() =>
      _BR06CampaignTrackerScreenState();
}

class _BR06CampaignTrackerScreenState extends State<BR06CampaignTrackerScreen> {
  SpecialistController? _specialist;
  BrandProfileDto? _profile;
  List<BrandOpportunityDto> _opportunities = const [];
  List<BrandApplicationDto> _applications = const [];
  List<CampaignDeliverableDto> _deliverables = const [];
  String _tab = 'All';
  String _query = '';
  String? _workingId;
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null || identical(specialist, _specialist)) return;
    _specialist = specialist;
    _load();
  }

  Future<void> _load({bool force = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _specialist!.brandProfile(force: force);
      List<BrandOpportunityDto> opportunities = const [];
      List<BrandApplicationDto> applications = const [];
      List<CampaignDeliverableDto> deliverables = const [];
      if (profile != null) {
        final values = await Future.wait<Object>([
          _specialist!.brandOpportunities(force: force),
          _specialist!.ownerBrandApplications(force: force),
          _specialist!.campaignDeliverables(force: force),
        ]);
        opportunities = values[0] as List<BrandOpportunityDto>;
        applications = values[1] as List<BrandApplicationDto>;
        deliverables = values[2] as List<CampaignDeliverableDto>;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _opportunities = opportunities;
        _applications = applications;
        _deliverables = deliverables;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_specialist == null) return _buildPreview(context);
    if (_loading && !_loaded) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: CircularProgressIndicator(),
        ),
      );
    }
    if (_error != null && !_loaded) {
      return CoreEmptyState(
        icon: Icons.cloud_off_outlined,
        title: 'Campaign delivery unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_profile == null) {
      return CoreEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Brand profile required',
        message: 'Create the organization profile before managing campaigns.',
        actionLabel: 'Create profile',
        onAction: () =>
            Navigator.pushNamed(context, BrandSponsorRoutes.profile),
      );
    }

    final visible = _visibleDeliverables();
    final pending =
        _deliverables.where((item) => item.status == 'pending').length;
    final review =
        _deliverables.where((item) => item.status == 'submitted').length;
    final revisions = _deliverables
        .where((item) => item.status == 'revision_requested')
        .length;
    final approved =
        _deliverables.where((item) => item.status == 'approved').length;
    final metrics = _deliverables
        .expand((item) => item.metrics)
        .fold<int>(0, (total, metric) => total + metric.impressions);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_error != null) ...[
          InlineNotice(
            message: _error!,
            icon: Icons.warning_amber_rounded,
            tone: CoreStatusTone.warning,
          ),
          const SizedBox(height: 12),
        ],
        MetricActionRail(
          items: [
            MetricActionItem(
              value: '$pending',
              icon: Icons.schedule_outlined,
              title: 'Awaiting proof',
              subtitle: '$revisions revision requests',
              accentColor: context.appColors.goldDark,
            ),
            MetricActionItem(
              value: '$review',
              icon: Icons.rate_review_outlined,
              title: 'Ready to review',
              subtitle: 'Proof submitted',
              accentColor: context.appColors.infoBlue,
            ),
            MetricActionItem(
              value: '$approved',
              icon: Icons.verified_outlined,
              title: 'Approved',
              subtitle: 'Campaign outputs',
              accentColor: context.appColors.success,
            ),
            MetricActionItem(
              value: _compactCount(metrics),
              icon: Icons.visibility_outlined,
              title: 'Impressions',
              subtitle: 'Verified metrics',
              accentColor: context.appColors.infoPurple,
            ),
          ],
        ),
        const SizedBox(height: 12),
        BrandSectionCard(
          title: 'Campaign deliverables',
          icon: Icons.fact_check_outlined,
          selected: true,
          actionText: _acceptedApplications.isEmpty ? null : 'Assign',
          onActionTap:
              _acceptedApplications.isEmpty ? null : _showCreateDeliverable,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              BrandSearchField(
                hintText: 'Search deliverable, owner or opportunity',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final tab in const [
                      'All',
                      'Awaiting proof',
                      'Review',
                      'Revision',
                      'Approved',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label: tab,
                          selected: _tab == tab,
                          onTap: () => setState(() => _tab = tab),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          CoreEmptyState(
            icon: _deliverables.isEmpty
                ? Icons.fact_check_outlined
                : Icons.search_off_rounded,
            title: _deliverables.isEmpty
                ? 'No campaign deliverables'
                : 'No matching deliverables',
            message: _deliverables.isEmpty
                ? _acceptedApplications.isEmpty
                    ? 'Accepted deals will be ready for delivery assignment.'
                    : 'Assign the first output to an accepted applicant.'
                : 'Change the status or search filter.',
            actionLabel:
                _deliverables.isEmpty && _acceptedApplications.isNotEmpty
                    ? 'Assign deliverable'
                    : 'Clear filters',
            onAction: _deliverables.isEmpty && _acceptedApplications.isNotEmpty
                ? _showCreateDeliverable
                : () => setState(() {
                      _tab = 'All';
                      _query = '';
                    }),
          )
        else
          BrandResponsiveGrid(
            minWidth: 330,
            children: [
              for (final deliverable in visible)
                _CampaignDeliverableCard(
                  deliverable: deliverable,
                  opportunityTitle:
                      _opportunityTitle(deliverable.opportunityId),
                  working: _workingId == deliverable.publicId,
                  onApprove: deliverable.status == 'submitted'
                      ? () => _approve(deliverable)
                      : null,
                  onRevision: deliverable.status == 'submitted'
                      ? () => _requestRevision(deliverable)
                      : null,
                  onMetrics: deliverable.status == 'approved'
                      ? () => _showMetricSheet(deliverable)
                      : null,
                ),
            ],
          ),
      ],
    );
  }

  List<BrandApplicationDto> get _acceptedApplications => _applications
      .where((application) => application.status == 'accepted')
      .toList();

  List<CampaignDeliverableDto> _visibleDeliverables() {
    final lower = _query.trim().toLowerCase();
    return _deliverables.where((item) {
      final matchesTab = switch (_tab) {
        'Awaiting proof' => item.status == 'pending',
        'Review' => item.status == 'submitted',
        'Revision' => item.status == 'revision_requested',
        'Approved' => item.status == 'approved',
        _ => item.status != 'cancelled',
      };
      final haystack = [
        item.label,
        item.owner.displayName,
        _opportunityTitle(item.opportunityId),
      ].join(' ').toLowerCase();
      return matchesTab && (lower.isEmpty || haystack.contains(lower));
    }).toList();
  }

  String _opportunityTitle(String opportunityId) {
    for (final opportunity in _opportunities) {
      if (opportunity.publicId == opportunityId) return opportunity.title;
    }
    return 'Campaign opportunity';
  }

  Future<void> _approve(CampaignDeliverableDto item) async {
    setState(() {
      _workingId = item.publicId;
      _error = null;
    });
    try {
      await _specialist!.approveCampaignDeliverable(item.publicId);
      await _load();
      if (!mounted) return;
      brandSnack(context, '${item.label} approved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _requestRevision(CampaignDeliverableDto item) async {
    final note = TextEditingController();
    String? validation;
    var confirmed = false;
    await showBrandSheet(
      context,
      title: 'Request revision',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.label,
              style: AppTextStyles.cardTitle.copyWith(
                color: context.appColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: note,
              label: 'Required changes',
              icon: Icons.edit_note_outlined,
              maxLines: 5,
            ),
            if (validation != null) ...[
              const SizedBox(height: 8),
              InlineNotice(
                message: validation!,
                icon: Icons.error_outline_rounded,
                tone: CoreStatusTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.close_rounded,
                    label: 'Cancel',
                    onTap: () => Navigator.pop(context),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.send_outlined,
                    label: 'Request revision',
                    onTap: () {
                      if (note.text.trim().length < 4) {
                        setSheetState(
                          () => validation = 'Describe the required change.',
                        );
                        return;
                      }
                      confirmed = true;
                      Navigator.pop(context);
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
    final value = note.text.trim();
    note.dispose();
    if (!confirmed || !mounted) return;
    setState(() {
      _workingId = item.publicId;
      _error = null;
    });
    try {
      await _specialist!.updateCampaignDeliverable(
        item.publicId,
        {
          'status': 'revision_requested',
          'revision_note': value,
        },
      );
      await _load();
      if (!mounted) return;
      brandSnack(context, 'Revision request sent');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _showCreateDeliverable() async {
    final accepted = _acceptedApplications;
    if (accepted.isEmpty) return;
    final label = TextEditingController();
    var applicationId = accepted.first.publicId;
    DateTime? dueAt;
    String? validation;
    var confirmed = false;
    await showBrandSheet(
      context,
      title: 'Assign deliverable',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          final application = accepted.firstWhere(
            (item) => item.publicId == applicationId,
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreDropdownField<String>(
                value: applicationId,
                values: accepted.map((item) => item.publicId).toList(),
                label: 'Accepted applicant',
                icon: Icons.person_outline_rounded,
                labelBuilder: (value) {
                  final row =
                      accepted.firstWhere((item) => item.publicId == value);
                  return '${row.applicant.displayName} | ${row.opportunityTitle}';
                },
                onChanged: (value) {
                  if (value != null) {
                    setSheetState(() => applicationId = value);
                  }
                },
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: label,
                label: 'Deliverable',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 10),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  Icons.event_outlined,
                  color: context.appColors.goldDark,
                ),
                title: const Text('Due date'),
                subtitle: Text(brandDate(dueAt)),
                trailing: const Icon(Icons.edit_calendar_outlined),
                onTap: () async {
                  final selected = await showDatePicker(
                    context: context,
                    initialDate:
                        dueAt ?? DateTime.now().add(const Duration(days: 7)),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 730)),
                  );
                  if (selected != null) {
                    setSheetState(() => dueAt = selected);
                  }
                },
              ),
              BrandInfoRow(
                icon: Icons.campaign_outlined,
                label: 'Opportunity',
                value: application.opportunityTitle,
              ),
              if (validation != null) ...[
                const SizedBox(height: 8),
                InlineNotice(
                  message: validation!,
                  icon: Icons.error_outline_rounded,
                  tone: CoreStatusTone.danger,
                ),
              ],
              const SizedBox(height: 14),
              CorePrimaryButton(
                icon: Icons.add_task_rounded,
                label: 'Assign deliverable',
                onTap: () {
                  if (label.text.trim().length < 2) {
                    setSheetState(
                      () => validation = 'Add a deliverable name.',
                    );
                    return;
                  }
                  confirmed = true;
                  Navigator.pop(context);
                },
              ),
            ],
          );
        },
      ),
    );
    final value = label.text.trim();
    label.dispose();
    if (!confirmed || !mounted) return;
    final application =
        accepted.firstWhere((item) => item.publicId == applicationId);
    setState(() {
      _workingId = 'creating';
      _error = null;
    });
    try {
      await _specialist!.createCampaignDeliverable(
        {
          'opportunity_id': application.opportunityId,
          'owner_user_id': application.applicant.publicId,
          'label': value,
          if (dueAt != null) 'due_at': dueAt!.toUtc().toIso8601String(),
        },
      );
      await _load();
      if (!mounted) return;
      brandSnack(context, 'Deliverable assigned');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _showMetricSheet(CampaignDeliverableDto item) async {
    final impressions = TextEditingController();
    final reach = TextEditingController();
    final engagements = TextEditingController();
    final clicks = TextEditingController();
    var platform = 'Instagram';
    String? validation;
    var confirmed = false;
    await showBrandSheet(
      context,
      title: 'Record campaign metrics',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CoreDropdownField<String>(
              value: platform,
              values: const [
                'Instagram',
                'TikTok',
                'YouTube',
                'Facebook',
                'Website',
                'Other',
              ],
              label: 'Platform',
              icon: Icons.public_outlined,
              onChanged: (value) {
                if (value != null) setSheetState(() => platform = value);
              },
            ),
            const SizedBox(height: 10),
            _MetricInput(
              controller: impressions,
              label: 'Impressions',
              icon: Icons.visibility_outlined,
            ),
            const SizedBox(height: 10),
            _MetricInput(
              controller: reach,
              label: 'Reach',
              icon: Icons.groups_outlined,
            ),
            const SizedBox(height: 10),
            _MetricInput(
              controller: engagements,
              label: 'Engagements',
              icon: Icons.favorite_border_rounded,
            ),
            const SizedBox(height: 10),
            _MetricInput(
              controller: clicks,
              label: 'Clicks',
              icon: Icons.ads_click_outlined,
            ),
            if (validation != null) ...[
              const SizedBox(height: 8),
              InlineNotice(
                message: validation!,
                icon: Icons.error_outline_rounded,
                tone: CoreStatusTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            CorePrimaryButton(
              icon: Icons.add_chart_outlined,
              label: 'Save metric snapshot',
              onTap: () {
                if (int.tryParse(impressions.text.trim()) == null) {
                  setSheetState(
                    () => validation = 'Add a valid impressions total.',
                  );
                  return;
                }
                confirmed = true;
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
    int number(TextEditingController controller) =>
        int.tryParse(controller.text.trim()) ?? 0;
    final body = {
      'deliverable_id': item.publicId,
      'platform': platform.toLowerCase(),
      'impressions': number(impressions),
      'reach': number(reach),
      'engagements': number(engagements),
      'clicks': number(clicks),
      'source': 'manual_verified',
    };
    impressions.dispose();
    reach.dispose();
    engagements.dispose();
    clicks.dispose();
    if (!confirmed || !mounted) return;
    setState(() {
      _workingId = item.publicId;
      _error = null;
    });
    try {
      await _specialist!.createCampaignMetric(body);
      await _load();
      if (!mounted) return;
      brandSnack(context, 'Metric snapshot recorded');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  String _compactCount(int value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(1)}K';
    return '$value';
  }

  Widget _buildPreview(BuildContext context) {
    final store = BrandSponsorDemoStore.instance;
    final items = BrandSponsorDemoData.deliverables.where((item) {
      final status = store.deliverableStatus(item);
      return switch (_tab) {
        'Awaiting proof' => status == BrandStatus.pending,
        'Review' =>
          status == BrandStatus.reviewing || status == BrandStatus.delivered,
        'Revision' => status == BrandStatus.revision,
        'Approved' => status == BrandStatus.approved,
        _ => true,
      };
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricActionRail(
          items: [
            MetricActionItem(
              value: '2',
              icon: Icons.schedule_outlined,
              title: 'Awaiting proof',
              subtitle: 'Campaign outputs',
              accentColor: context.appColors.goldDark,
            ),
            MetricActionItem(
              value: '1',
              icon: Icons.rate_review_outlined,
              title: 'Ready to review',
              subtitle: 'Proof submitted',
              accentColor: context.appColors.infoBlue,
            ),
            MetricActionItem(
              value: '1',
              icon: Icons.verified_outlined,
              title: 'Approved',
              subtitle: 'Campaign outputs',
              accentColor: context.appColors.success,
            ),
          ],
        ),
        const SizedBox(height: 12),
        BrandSectionCard(
          title: 'Campaign deliverables',
          icon: Icons.fact_check_outlined,
          selected: true,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                for (final tab in const [
                  'All',
                  'Awaiting proof',
                  'Review',
                  'Revision',
                  'Approved',
                ])
                  Padding(
                    padding: const EdgeInsets.only(right: 8),
                    child: CoreChip(
                      label: tab,
                      selected: _tab == tab,
                      onTap: () => setState(() => _tab = tab),
                    ),
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        BrandResponsiveGrid(
          minWidth: 330,
          children: [
            for (final item in items)
              _PreviewDeliverableCard(
                item: item,
                status: store.deliverableStatus(item),
              ),
          ],
        ),
      ],
    );
  }
}

class _CampaignDeliverableCard extends StatelessWidget {
  final CampaignDeliverableDto deliverable;
  final String opportunityTitle;
  final bool working;
  final VoidCallback? onApprove;
  final VoidCallback? onRevision;
  final VoidCallback? onMetrics;

  const _CampaignDeliverableCard({
    required this.deliverable,
    required this.opportunityTitle,
    required this.working,
    this.onApprove,
    this.onRevision,
    this.onMetrics,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final impressions = deliverable.metrics.fold<int>(
      0,
      (total, metric) => total + metric.impressions,
    );
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMediaFrame(
            imageUrl: deliverable.proofUrl,
            title: deliverable.label,
            badge:
                deliverable.proofUrl.isEmpty ? 'Proof pending' : 'Proof file',
            fallbackIcon: Icons.fact_check_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  deliverable.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              if (working)
                const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                BrandLiveStatusChip(status: deliverable.status),
            ],
          ),
          const SizedBox(height: 8),
          BrandInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner',
            value: deliverable.owner.displayName,
          ),
          BrandInfoRow(
            icon: Icons.campaign_outlined,
            label: 'Opportunity',
            value: opportunityTitle,
          ),
          BrandInfoRow(
            icon: Icons.event_outlined,
            label: 'Due',
            value: brandDate(deliverable.dueAt),
          ),
          BrandInfoRow(
            icon: Icons.visibility_outlined,
            label: 'Impressions',
            value: '$impressions across ${deliverable.metricCount} snapshots',
          ),
          if (deliverable.revisionNote?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            InlineNotice(
              message: deliverable.revisionNote!,
              icon: Icons.edit_note_outlined,
              tone: CoreStatusTone.warning,
            ),
          ],
          const SizedBox(height: 10),
          if (onApprove != null || onRevision != null)
            Row(
              children: [
                Expanded(
                  child: CoreSecondaryButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Revision',
                    compact: true,
                    onTap: working ? null : onRevision,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: CorePrimaryButton(
                    icon: Icons.check_circle_outline,
                    label: 'Approve proof',
                    compact: true,
                    onTap: working ? null : onApprove,
                  ),
                ),
              ],
            )
          else if (onMetrics != null)
            CoreSecondaryButton(
              icon: Icons.add_chart_outlined,
              label: 'Record verified metrics',
              compact: true,
              onTap: working ? null : onMetrics,
            )
          else
            StatusChip(
              label:
                  'WAITING ON ${deliverable.owner.displayName.toUpperCase()}',
              icon: Icons.schedule_outlined,
              color: colors.goldMid,
            ),
        ],
      ),
    );
  }
}

class _MetricInput extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _MetricInput({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      controller: controller,
      label: label,
      icon: icon,
      keyboardType: TextInputType.number,
    );
  }
}

class _PreviewDeliverableCard extends StatelessWidget {
  final BrandDeliverable item;
  final BrandStatus status;

  const _PreviewDeliverableCard({
    required this.item,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return GlassSectionCard(
      radius: 18,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          BrandMediaFrame(
            imageUrl: item.imageUrl,
            title: item.label,
            badge: item.dueDate,
            fallbackIcon: Icons.fact_check_outlined,
            aspectRatio: 16 / 9,
            compact: true,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardTitle.copyWith(
                    color: context.appColors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BrandStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 8),
          BrandInfoRow(
            icon: Icons.person_outline_rounded,
            label: 'Owner',
            value: item.owner,
          ),
          BrandInfoRow(
            icon: Icons.upload_file_outlined,
            label: 'Proof',
            value: item.proof,
          ),
        ],
      ),
    );
  }
}
