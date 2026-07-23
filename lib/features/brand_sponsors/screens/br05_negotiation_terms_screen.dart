import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/brand_sponsor_demo_data.dart';
import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR05NegotiationTermsScreen extends StatefulWidget {
  const BR05NegotiationTermsScreen({super.key});

  @override
  State<BR05NegotiationTermsScreen> createState() =>
      _BR05NegotiationTermsScreenState();
}

class _BR05NegotiationTermsScreenState
    extends State<BR05NegotiationTermsScreen> {
  final _scope = TextEditingController();
  final _exclusivity = TextEditingController();
  final _approvalRights = TextEditingController();
  final _advance = TextEditingController(text: '40');
  final _proofApproval = TextEditingController(text: '40');
  final _completion = TextEditingController(text: '20');

  SpecialistController? _specialist;
  BrandProfileDto? _profile;
  List<BrandApplicationDto> _applications = const [];
  String? _selectedId;
  bool _loading = false;
  bool _loaded = false;
  bool _saving = false;
  bool _openingChat = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null || identical(specialist, _specialist)) return;
    _specialist = specialist;
    _load();
  }

  @override
  void dispose() {
    _scope.dispose();
    _exclusivity.dispose();
    _approvalRights.dispose();
    _advance.dispose();
    _proofApproval.dispose();
    _completion.dispose();
    super.dispose();
  }

  Future<void> _load({bool force = true}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final profile = await _specialist!.brandProfile(force: force);
      final applications = profile == null
          ? const <BrandApplicationDto>[]
          : await _specialist!.ownerBrandApplications(force: force);
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _applications = applications
            .where((item) =>
                item.status != 'rejected' && item.status != 'withdrawn')
            .toList();
        _loaded = true;
      });
      final selected = activeBrandApplication(_applications);
      if (selected != null) _selectApplication(selected);
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
        title: 'Terms unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: _load,
      );
    }
    if (_profile == null) {
      return CoreEmptyState(
        icon: Icons.business_center_outlined,
        title: 'Brand profile required',
        message: 'Create the organization profile before negotiating deals.',
        actionLabel: 'Create profile',
        onAction: () =>
            Navigator.pushNamed(context, BrandSponsorRoutes.profile),
      );
    }
    if (_applications.isEmpty) {
      return CoreEmptyState(
        icon: Icons.handshake_outlined,
        title: 'No applications ready for terms',
        message:
            'Shortlist an application first, then define scope, rights and payment milestones here.',
        actionLabel: 'Review applications',
        onAction: () =>
            Navigator.pushNamed(context, BrandSponsorRoutes.applications),
      );
    }

    final selected = _selectedApplication ?? _applications.first;
    final latest = selected.terms.isEmpty ? null : selected.terms.last;
    final colors = context.appColors;
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
        BrandTwoColumn(
          left: BrandSectionCard(
            title: 'Deal terms',
            icon: Icons.handshake_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    _DealAvatar(name: selected.applicant.displayName),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            selected.applicant.displayName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.cardTitle.copyWith(
                              color: colors.textPrimary,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            selected.opportunityTitle,
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
                    BrandLiveStatusChip(status: selected.status),
                  ],
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: latest == null
                          ? 'FIRST VERSION'
                          : 'VERSION ${latest.version}',
                      icon: Icons.history_rounded,
                      color: colors.infoPurple,
                    ),
                    StatusChip(
                      label: brandMoney(
                        selected.budgetAskMinor,
                        currency: selected.currency,
                      ),
                      icon: Icons.payments_outlined,
                      color: colors.goldMid,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                CoreTextField(
                  controller: _scope,
                  label: 'Campaign scope and deliverables',
                  icon: Icons.fact_check_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _exclusivity,
                  label: 'Category exclusivity and duration',
                  icon: Icons.lock_outline_rounded,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: _approvalRights,
                  label: 'Approval rights and response window',
                  icon: Icons.approval_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 14),
                Text(
                  'PAYMENT MILESTONES',
                  style: AppTextStyles.micro.copyWith(
                    color: colors.goldDark,
                    letterSpacing: 1,
                  ),
                ),
                const SizedBox(height: 8),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final fields = [
                      _PercentField(
                        controller: _advance,
                        label: 'Advance',
                        icon: Icons.playlist_add_check_rounded,
                      ),
                      _PercentField(
                        controller: _proofApproval,
                        label: 'Proof approval',
                        icon: Icons.fact_check_outlined,
                      ),
                      _PercentField(
                        controller: _completion,
                        label: 'Completion',
                        icon: Icons.task_alt_rounded,
                      ),
                    ];
                    if (constraints.maxWidth < 620) {
                      return Column(
                        children: [
                          for (var index = 0;
                              index < fields.length;
                              index++) ...[
                            fields[index],
                            if (index < fields.length - 1)
                              const SizedBox(height: 10),
                          ],
                        ],
                      );
                    }
                    return Row(
                      children: [
                        for (var index = 0; index < fields.length; index++) ...[
                          Expanded(child: fields[index]),
                          if (index < fields.length - 1)
                            const SizedBox(width: 10),
                        ],
                      ],
                    );
                  },
                ),
                const SizedBox(height: 10),
                InlineNotice(
                  message:
                      'Each save creates an immutable term version. Percentages must total 100.',
                  icon: Icons.info_outline_rounded,
                ),
                const SizedBox(height: 14),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final chat = CoreSecondaryButton(
                      icon: Icons.chat_bubble_outline_rounded,
                      label: _openingChat ? 'Opening...' : 'Message',
                      compact: true,
                      onTap: _openingChat ? null : _openChat,
                    );
                    final counter = CoreSecondaryButton(
                      icon: Icons.edit_note_outlined,
                      label: _saving ? 'Saving...' : 'Send counter',
                      compact: true,
                      onTap: _saving || selected.status == 'accepted'
                          ? null
                          : () => _save('negotiating'),
                    );
                    final accept = CorePrimaryButton(
                      icon: Icons.check_circle_outline,
                      label:
                          selected.status == 'accepted' ? 'Accepted' : 'Accept',
                      compact: true,
                      onTap: _saving || selected.status == 'accepted'
                          ? null
                          : () => _save('accepted'),
                    );
                    if (constraints.maxWidth < 560) {
                      return Column(
                        children: [
                          SizedBox(width: double.infinity, child: chat),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: counter),
                          const SizedBox(height: 8),
                          SizedBox(width: double.infinity, child: accept),
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: chat),
                        const SizedBox(width: 8),
                        Expanded(child: counter),
                        const SizedBox(width: 8),
                        Expanded(child: accept),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              BrandSectionCard(
                title: 'Applications in deal flow',
                icon: Icons.people_alt_outlined,
                tone: BrandTone.blue,
                child: Column(
                  children: [
                    for (final application in _applications)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 9),
                        child: _ApplicationDealRow(
                          application: application,
                          selected: application.publicId == selected.publicId,
                          onTap: () => _selectApplication(application),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Version history',
                icon: Icons.history_rounded,
                tone: BrandTone.purple,
                child: selected.terms.isEmpty
                    ? Text(
                        'No terms saved yet. The first counter creates version 1.',
                        style: AppTextStyles.body.copyWith(
                          color: colors.textSecondary,
                        ),
                      )
                    : Column(
                        children: [
                          for (final term in selected.terms.reversed)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 9),
                              child: _TermVersionRow(
                                term: term,
                                onTap: () => _seedTerm(term),
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 12),
              BrandSectionCard(
                title: 'Connected workflow',
                icon: Icons.account_tree_outlined,
                tone: BrandTone.green,
                child: Column(
                  children: [
                    BrandInfoRow(
                      icon: Icons.inbox_outlined,
                      label: 'Application',
                      value: readableBrandStatus(selected.status),
                    ),
                    BrandInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Terms record',
                      value: '${selected.termsCount} versions',
                    ),
                    BrandInfoRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Campaign delivery',
                      value: selected.status == 'accepted'
                          ? 'Ready to assign'
                          : 'Unlocks after acceptance',
                    ),
                    if (selected.status == 'accepted') ...[
                      const SizedBox(height: 8),
                      CorePrimaryButton(
                        icon: Icons.arrow_forward_rounded,
                        label: 'Open campaign delivery',
                        compact: true,
                        onTap: () => Navigator.pushNamed(
                          context,
                          BrandSponsorRoutes.tracker,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  BrandApplicationDto? get _selectedApplication {
    for (final application in _applications) {
      if (application.publicId == _selectedId) return application;
    }
    return null;
  }

  void _selectApplication(BrandApplicationDto application) {
    BrandSponsorDemoStore.instance
        .setActiveLiveApplication(application.publicId);
    setState(() => _selectedId = application.publicId);
    if (application.terms.isEmpty) {
      _scope.text = application.proposal;
      _exclusivity.clear();
      _approvalRights.clear();
      _advance.text = '40';
      _proofApproval.text = '40';
      _completion.text = '20';
      return;
    }
    _seedTerm(application.terms.last);
  }

  void _seedTerm(BrandTermDto term) {
    setState(() {
      _scope.text = term.scope;
      _exclusivity.text = term.exclusivity;
      _approvalRights.text = term.approvalRights;
      _advance.text = _schedulePercent(term, 'advance', fallback: 40);
      _proofApproval.text =
          _schedulePercent(term, 'proof_approval', fallback: 40);
      _completion.text = _schedulePercent(term, 'completion', fallback: 20);
    });
  }

  String _schedulePercent(
    BrandTermDto term,
    String key, {
    required int fallback,
  }) {
    for (final item in term.paymentSchedule) {
      if (item['key'] == key) {
        return ((item['percent'] as num?)?.toInt() ?? fallback).toString();
      }
    }
    return fallback.toString();
  }

  Future<void> _save(String status) async {
    final application = _selectedApplication;
    if (application == null) return;
    final advance = int.tryParse(_advance.text.trim()) ?? -1;
    final proof = int.tryParse(_proofApproval.text.trim()) ?? -1;
    final completion = int.tryParse(_completion.text.trim()) ?? -1;
    if (_scope.text.trim().length < 4) {
      setState(() => _error = 'Add the campaign scope and deliverables.');
      return;
    }
    if ([advance, proof, completion].any((value) => value < 0) ||
        advance + proof + completion != 100) {
      setState(
        () => _error = 'Payment milestone percentages must total 100.',
      );
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await _specialist!.createBrandTerms(
        application.publicId,
        {
          'scope': _scope.text.trim(),
          'exclusivity': _exclusivity.text.trim(),
          'approval_rights': _approvalRights.text.trim(),
          'payment_schedule': [
            {
              'key': 'advance',
              'label': 'Advance',
              'percent': advance,
              'trigger': 'Terms accepted',
            },
            {
              'key': 'proof_approval',
              'label': 'Proof approval',
              'percent': proof,
              'trigger': 'Campaign proof approved',
            },
            {
              'key': 'completion',
              'label': 'Completion',
              'percent': completion,
              'trigger': 'All deliverables complete',
            },
          ],
          'status': status,
        },
      );
      await _load();
      if (!mounted) return;
      brandSnack(
        context,
        status == 'accepted'
            ? 'Deal terms accepted'
            : 'Counter terms saved as a new version',
      );
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _openChat() async {
    final application = _selectedApplication;
    if (application == null) return;
    setState(() {
      _openingChat = true;
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
      if (mounted) setState(() => _openingChat = false);
    }
  }

  Widget _buildPreview(BuildContext context) {
    final term = BrandSponsorDemoStore.instance.activeTerm;
    return BrandTwoColumn(
      left: BrandSectionCard(
        title: 'Deal terms',
        icon: Icons.handshake_outlined,
        selected: true,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                _DealAvatar(name: term.applicant),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    term.applicant,
                    style: AppTextStyles.cardTitle.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                BrandStatusChip(status: term.status),
              ],
            ),
            const SizedBox(height: 14),
            CoreTextField(
              controller: TextEditingController(text: term.scope),
              label: 'Campaign scope and deliverables',
              icon: Icons.fact_check_outlined,
              maxLines: 4,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: TextEditingController(text: term.exclusivity),
              label: 'Category exclusivity and duration',
              icon: Icons.lock_outline_rounded,
              maxLines: 3,
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: TextEditingController(text: term.approvalRights),
              label: 'Approval rights and response window',
              icon: Icons.approval_outlined,
              maxLines: 3,
            ),
          ],
        ),
      ),
      right: BrandSectionCard(
        title: 'Version history',
        icon: Icons.history_rounded,
        tone: BrandTone.purple,
        child: Column(
          children: [
            for (final item in BrandSponsorDemoData.terms)
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.description_outlined),
                title: Text(item.applicant),
                subtitle: Text(item.paymentSchedule),
                trailing: BrandStatusChip(status: item.status),
              ),
          ],
        ),
      ),
    );
  }
}

class _PercentField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final IconData icon;

  const _PercentField({
    required this.controller,
    required this.label,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return CoreTextField(
      controller: controller,
      label: '$label %',
      icon: icon,
      keyboardType: TextInputType.number,
    );
  }
}

class _DealAvatar extends StatelessWidget {
  final String name;

  const _DealAvatar({required this.name});

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
        color: context.appColors.infoPurple.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: context.appColors.infoPurple.withValues(alpha: 0.35),
        ),
      ),
      child: Text(
        initials.isEmpty ? 'BR' : initials,
        style: AppTextStyles.cardLabel.copyWith(
          color: context.appColors.infoPurple,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _ApplicationDealRow extends StatelessWidget {
  final BrandApplicationDto application;
  final bool selected;
  final VoidCallback onTap;

  const _ApplicationDealRow({
    required this.application,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSectionCard(
        radius: 8,
        selected: selected,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            _DealAvatar(name: application.applicant.displayName),
            const SizedBox(width: 9),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    application.applicant.displayName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: context.appColors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${application.termsCount} versions',
                    style: AppTextStyles.smallMeta.copyWith(
                      color: context.appColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 6),
            BrandLiveStatusChip(status: application.status),
          ],
        ),
      ),
    );
  }
}

class _TermVersionRow extends StatelessWidget {
  final BrandTermDto term;
  final VoidCallback onTap;

  const _TermVersionRow({required this.term, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: GlassSectionCard(
        radius: 8,
        padding: const EdgeInsets.all(10),
        child: Row(
          children: [
            Container(
              width: 34,
              height: 34,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: context.appColors.goldMid.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                'V${term.version}',
                style: AppTextStyles.smallMeta.copyWith(
                  color: context.appColors.goldDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
            const SizedBox(width: 9),
            Expanded(
              child: Text(
                term.scope.isEmpty ? 'Scope not set' : term.scope,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.smallMeta.copyWith(
                  color: context.appColors.textPrimary,
                ),
              ),
            ),
            const SizedBox(width: 6),
            BrandLiveStatusChip(status: term.status),
          ],
        ),
      ),
    );
  }
}
