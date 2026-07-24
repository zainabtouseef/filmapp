import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR04ApplicationsInboxScreen extends StatefulWidget {
  const BR04ApplicationsInboxScreen({super.key});

  @override
  State<BR04ApplicationsInboxScreen> createState() =>
      _BR04ApplicationsInboxScreenState();
}

class _BR04ApplicationsInboxScreenState
    extends State<BR04ApplicationsInboxScreen> {
  SpecialistController? _specialist;
  BrandProfileDto? _profile;
  List<BrandOpportunityDto> _opportunities = const [];
  List<BrandApplicationDto> _applications = const [];
  String _query = '';
  String _status = 'All';
  String _opportunityId = 'All';
  String _sort = 'Newest';
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
      if (profile != null) {
        final values = await Future.wait<Object>([
          _specialist!.brandOpportunities(force: force),
          _specialist!.ownerBrandApplications(force: force),
        ]);
        opportunities = values[0] as List<BrandOpportunityDto>;
        applications = values[1] as List<BrandApplicationDto>;
      }
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _opportunities = opportunities;
        _applications = applications;
        _loaded = true;
        if (_opportunityId != 'All' &&
            !opportunities.any((item) => item.publicId == _opportunityId)) {
          _opportunityId = 'All';
        }
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
    if (_specialist == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load applications',
        message:
            'The proposal queue only shows applications fetched from the backend for your published opportunities.',
      );
    }
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
        title: 'Applications unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_profile == null) {
      return CoreEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Brand profile required',
        message:
            'Create the organization profile before reviewing sponsorship proposals.',
        actionLabel: 'Create profile',
        onAction: () =>
            Navigator.pushNamed(context, BrandSponsorRoutes.profile),
      );
    }

    final visible = _filteredApplications();
    final awaiting = _applications
        .where(
            (item) => item.status == 'submitted' || item.status == 'reviewing')
        .length;
    final shortlisted =
        _applications.where((item) => item.status == 'shortlisted').length;
    final negotiating =
        _applications.where((item) => item.status == 'negotiating').length;

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
        BrandSectionCard(
          title: 'Proposal review queue',
          icon: Icons.move_to_inbox_outlined,
          selected: true,
          actionText: _loading ? 'Loading' : 'Refresh',
          onActionTap: _loading ? null : _load,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  StatusChip(
                    label: '$awaiting AWAITING REVIEW',
                    icon: Icons.schedule_outlined,
                    color: context.appColors.goldMid,
                  ),
                  StatusChip(
                    label: '$shortlisted SHORTLISTED',
                    icon: Icons.star_outline_rounded,
                    color: context.appColors.infoBlue,
                  ),
                  StatusChip(
                    label: '$negotiating IN TERMS',
                    icon: Icons.handshake_outlined,
                    color: context.appColors.infoPurple,
                  ),
                ],
              ),
              const SizedBox(height: 12),
              BrandSearchField(
                hintText: 'Search applicant, opportunity or proposal',
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              LayoutBuilder(
                builder: (context, constraints) {
                  final compact = constraints.maxWidth < 640;
                  final statusField = CoreDropdownField<String>(
                    value: _status,
                    values: const [
                      'All',
                      'Awaiting review',
                      'Shortlisted',
                      'Negotiating',
                      'Accepted',
                      'Rejected',
                    ],
                    label: 'Status',
                    icon: Icons.filter_alt_outlined,
                    onChanged: (value) {
                      if (value != null) setState(() => _status = value);
                    },
                  );
                  final opportunityField = CoreDropdownField<String>(
                    value: _opportunityId,
                    values: [
                      'All',
                      ..._opportunities.map((item) => item.publicId),
                    ],
                    label: 'Opportunity',
                    icon: Icons.campaign_outlined,
                    labelBuilder: (value) {
                      if (value == 'All') return 'All opportunities';
                      return _opportunities
                          .firstWhere((item) => item.publicId == value)
                          .title;
                    },
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _opportunityId = value);
                      }
                    },
                  );
                  final sortField = CoreDropdownField<String>(
                    value: _sort,
                    values: const [
                      'Newest',
                      'Budget: high to low',
                      'Applicant'
                    ],
                    label: 'Sort',
                    icon: Icons.sort_rounded,
                    onChanged: (value) {
                      if (value != null) setState(() => _sort = value);
                    },
                  );
                  if (compact) {
                    return Column(
                      children: [
                        statusField,
                        const SizedBox(height: 10),
                        opportunityField,
                        const SizedBox(height: 10),
                        sortField,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: statusField),
                      const SizedBox(width: 10),
                      Expanded(flex: 2, child: opportunityField),
                      const SizedBox(width: 10),
                      Expanded(child: sortField),
                    ],
                  );
                },
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (visible.isEmpty)
          CoreEmptyState(
            icon: _applications.isEmpty
                ? Icons.inbox_outlined
                : Icons.search_off_rounded,
            title: _applications.isEmpty
                ? 'No applications yet'
                : 'No matching applications',
            message: _applications.isEmpty
                ? 'Published opportunities will collect proposals here.'
                : 'Change the opportunity, status or search filters.',
            actionLabel:
                _applications.isEmpty ? 'Open opportunities' : 'Clear filters',
            onAction: _applications.isEmpty
                ? () => Navigator.pushNamed(
                      context,
                      BrandSponsorRoutes.composer,
                    )
                : _clearFilters,
          )
        else
          BrandResponsiveGrid(
            minWidth: 330,
            children: [
              for (final application in visible)
                _LiveApplicationCard(
                  application: application,
                  working: _workingId == application.publicId,
                  onDetails: () => _showApplication(application),
                  onChat: () => _openChat(application),
                  onShortlist: () => _changeStatus(application, 'shortlisted'),
                  onNegotiate: () => _beginNegotiation(application),
                  onReject: () => _reject(application),
                ),
            ],
          ),
      ],
    );
  }

  List<BrandApplicationDto> _filteredApplications() {
    final lower = _query.trim().toLowerCase();
    final rows = _applications.where((application) {
      final matchesOpportunity = _opportunityId == 'All' ||
          application.opportunityId == _opportunityId;
      final matchesStatus = switch (_status) {
        'Awaiting review' => application.status == 'submitted' ||
            application.status == 'reviewing',
        'Shortlisted' => application.status == 'shortlisted',
        'Negotiating' => application.status == 'negotiating',
        'Accepted' => application.status == 'accepted',
        'Rejected' => application.status == 'rejected',
        _ => true,
      };
      final haystack = [
        application.applicant.displayName,
        application.opportunityTitle,
        application.proposal,
        brandAudienceSummary(application.audienceMetrics),
      ].join(' ').toLowerCase();
      return matchesOpportunity &&
          matchesStatus &&
          (lower.isEmpty || haystack.contains(lower));
    }).toList();
    if (_sort == 'Budget: high to low') {
      rows.sort(
        (a, b) => (b.budgetAskMinor ?? 0).compareTo(a.budgetAskMinor ?? 0),
      );
    } else if (_sort == 'Applicant') {
      rows.sort(
        (a, b) => a.applicant.displayName
            .toLowerCase()
            .compareTo(b.applicant.displayName.toLowerCase()),
      );
    } else {
      rows.sort((a, b) {
        final left = a.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        final right = b.createdAt ?? DateTime.fromMillisecondsSinceEpoch(0);
        return right.compareTo(left);
      });
    }
    return rows;
  }

  void _clearFilters() {
    setState(() {
      _query = '';
      _status = 'All';
      _opportunityId = 'All';
      _sort = 'Newest';
    });
  }

  Future<void> _changeStatus(
    BrandApplicationDto application,
    String status, {
    String? rejectionReason,
  }) async {
    setState(() {
      _workingId = application.publicId;
      _error = null;
    });
    try {
      await _specialist!.updateBrandApplication(
        application.publicId,
        {
          'status': status,
          if (rejectionReason != null) 'rejection_reason': rejectionReason,
        },
      );
      await _load();
      if (!mounted) return;
      brandSnack(
        context,
        '${application.applicant.displayName}: ${readableBrandStatus(status)}',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _beginNegotiation(BrandApplicationDto application) async {
    if (application.status != 'negotiating' &&
        application.status != 'accepted') {
      await _changeStatus(application, 'negotiating');
    }
    if (!mounted || _error != null) return;
    Navigator.pushNamed(context, BrandSponsorRoutes.negotiation);
  }

  Future<void> _openChat(BrandApplicationDto application) async {
    setState(() {
      _workingId = application.publicId;
      _error = null;
    });
    try {
      final conversationId = application.conversationId ??
          await _specialist!
              .ensureBrandApplicationConversation(application.publicId);
      if (!mounted) return;
      Navigator.pushNamed(
        context,
        CoreRoutes.chat,
        arguments: conversationId,
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _workingId = null);
    }
  }

  Future<void> _reject(BrandApplicationDto application) async {
    final reason = TextEditingController();
    String? validation;
    var confirmed = false;
    await showBrandSheet(
      context,
      title: 'Decline application',
      child: StatefulBuilder(
        builder: (context, setSheetState) => Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Give ${application.applicant.displayName} a concise decision reason. It will remain on the application record.',
              style: AppTextStyles.body.copyWith(
                color: context.appColors.textSecondary,
              ),
            ),
            const SizedBox(height: 12),
            CoreTextField(
              controller: reason,
              label: 'Decision reason',
              icon: Icons.rate_review_outlined,
              maxLines: 4,
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
                    icon: Icons.block_outlined,
                    label: 'Decline',
                    onTap: () {
                      final value = reason.text.trim();
                      if (value.length < 4) {
                        setSheetState(
                          () => validation = 'Add a useful decision reason.',
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
    final value = reason.text.trim();
    reason.dispose();
    if (!confirmed || value.length < 4 || !mounted) return;
    await _changeStatus(
      application,
      'rejected',
      rejectionReason: value,
    );
  }

  void _showApplication(BrandApplicationDto application) {
    showBrandSheet(
      context,
      title: application.applicant.displayName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              BrandLiveStatusChip(status: application.status),
              StatusChip(
                label: '${application.termsCount} TERM VERSIONS',
                icon: Icons.history_rounded,
                color: context.appColors.infoPurple,
              ),
            ],
          ),
          const SizedBox(height: 12),
          BrandInfoRow(
            icon: Icons.campaign_outlined,
            label: 'Opportunity',
            value: application.opportunityTitle,
          ),
          BrandInfoRow(
            icon: Icons.payments_outlined,
            label: 'Budget ask',
            value: brandMoney(
              application.budgetAskMinor,
              currency: application.currency,
            ),
          ),
          BrandInfoRow(
            icon: Icons.groups_outlined,
            label: 'Audience',
            value: brandAudienceSummary(application.audienceMetrics),
          ),
          BrandInfoRow(
            icon: Icons.event_outlined,
            label: 'Received',
            value: brandDate(application.createdAt, fallback: 'Not recorded'),
          ),
          const SizedBox(height: 8),
          Text(
            'PROPOSAL',
            style: AppTextStyles.micro.copyWith(
              color: context.appColors.goldDark,
              letterSpacing: 1,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            application.proposal.isEmpty
                ? 'No written proposal was provided.'
                : application.proposal,
            style: AppTextStyles.body.copyWith(
              color: context.appColors.textPrimary,
              height: 1.45,
            ),
          ),
          if (application.rejectionReason?.isNotEmpty == true) ...[
            const SizedBox(height: 12),
            InlineNotice(
              message: application.rejectionReason!,
              icon: Icons.info_outline_rounded,
              tone: CoreStatusTone.danger,
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  label: 'Message',
                  compact: true,
                  onTap: () {
                    Navigator.pop(context);
                    _openChat(application);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.handshake_outlined,
                  label: 'Terms',
                  compact: true,
                  onTap: () {
                    Navigator.pop(context);
                    _beginNegotiation(application);
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

class _LiveApplicationCard extends StatelessWidget {
  final BrandApplicationDto application;
  final bool working;
  final VoidCallback onDetails;
  final VoidCallback onChat;
  final VoidCallback onShortlist;
  final VoidCallback onNegotiate;
  final VoidCallback onReject;

  const _LiveApplicationCard({
    required this.application,
    required this.working,
    required this.onDetails,
    required this.onChat,
    required this.onShortlist,
    required this.onNegotiate,
    required this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final terminal =
        application.status == 'accepted' || application.status == 'rejected';
    return GestureDetector(
      onTap: onDetails,
      child: GlassSectionCard(
        radius: 18,
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _ApplicantAvatar(name: application.applicant.displayName),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        application.applicant.displayName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardTitle.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        application.opportunityTitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.smallMeta.copyWith(
                          color: colors.textSecondary,
                        ),
                      ),
                    ],
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
                  BrandLiveStatusChip(status: application.status),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              application.proposal.isEmpty
                  ? 'No written proposal provided.'
                  : application.proposal,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.body.copyWith(
                color: colors.textPrimary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 10),
            BrandInfoRow(
              icon: Icons.groups_outlined,
              label: 'Audience',
              value: brandAudienceSummary(application.audienceMetrics),
            ),
            BrandInfoRow(
              icon: Icons.payments_outlined,
              label: 'Budget ask',
              value: brandMoney(
                application.budgetAskMinor,
                currency: application.currency,
              ),
            ),
            BrandInfoRow(
              icon: Icons.history_rounded,
              label: 'Terms',
              value: '${application.termsCount} versions',
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                IconButton(
                  tooltip: 'Message applicant',
                  onPressed: working ? null : onChat,
                  icon: const Icon(Icons.chat_bubble_outline_rounded),
                ),
                IconButton(
                  tooltip: 'Decline application',
                  onPressed: working || terminal ? null : onReject,
                  icon: const Icon(Icons.block_outlined),
                ),
                const Spacer(),
                if (application.status == 'submitted' ||
                    application.status == 'reviewing')
                  CoreSecondaryButton(
                    icon: Icons.star_outline_rounded,
                    label: 'Shortlist',
                    compact: true,
                    onTap: working ? null : onShortlist,
                  ),
                if (application.status != 'rejected') ...[
                  const SizedBox(width: 8),
                  CorePrimaryButton(
                    icon: Icons.handshake_outlined,
                    label: application.status == 'accepted'
                        ? 'Terms'
                        : 'Negotiate',
                    compact: true,
                    onTap: working ? null : onNegotiate,
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _ApplicantAvatar extends StatelessWidget {
  final String name;

  const _ApplicantAvatar({required this.name});

  @override
  Widget build(BuildContext context) {
    final words =
        name.trim().split(RegExp(r'\s+')).where((item) => item.isNotEmpty);
    final initials = words.take(2).map((item) => item[0].toUpperCase()).join();
    return Container(
      width: 44,
      height: 44,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: context.appColors.infoBlue.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.appColors.infoBlue.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        initials.isEmpty ? 'BR' : initials,
        style: AppTextStyles.cardLabel.copyWith(
          color: context.appColors.infoBlue,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}
