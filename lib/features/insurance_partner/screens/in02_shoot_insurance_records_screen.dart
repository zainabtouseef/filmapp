import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../data/insurance_partner_demo_data.dart';
import '../models/insurance_partner_models.dart';
import '../widgets/insurance_partner_components.dart';

class IN02ShootInsuranceRecordsScreen extends StatefulWidget {
  const IN02ShootInsuranceRecordsScreen({super.key});

  @override
  State<IN02ShootInsuranceRecordsScreen> createState() =>
      _IN02ShootInsuranceRecordsScreenState();
}

class _IN02ShootInsuranceRecordsScreenState
    extends State<IN02ShootInsuranceRecordsScreen> {
  String _query = '';
  String _sort = 'Risk';
  Future<List<InsurancePolicyDto>>? _policiesFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final insurance = InsuranceScope.maybeOf(context);
    _policiesFuture ??= insurance?.policies(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = InsurancePartnerDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _rows(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            InsuranceSectionCard(
              title: 'Policy command',
              icon: Icons.policy_outlined,
              selected: true,
              child: Column(
                children: [
                  if (_policiesFuture != null)
                    FutureBuilder<List<InsurancePolicyDto>>(
                      future: _policiesFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live insurance policies...',
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
                                'Live policy records connected: ${rows.length} policy/policies, latest ${rows.first.publicId}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  InsuranceSearchField(
                    hintText: 'Search project, booking, insured party...',
                    onChanged: (value) => setState(() => _query = value),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Active',
                          'Pending',
                          'Verified',
                          'High Risk',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: store.policyFilter == filter,
                              onTap: () => store.setPolicyFilter(filter),
                            ),
                          ),
                        const SizedBox(width: 8),
                        for (final sort in ['Risk', 'Validity'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: sort,
                              selected: _sort == sort,
                              icon: Icons.sort_rounded,
                              onTap: () {
                                setState(() => _sort = sort);
                                insuranceSnack(
                                    context, '$sort sorting applied');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            InsuranceTwoColumn(
              left: InsuranceSectionCard(
                title: 'Shoot insurance records',
                icon: Icons.table_rows_outlined,
                child: rows.isEmpty
                    ? CoreEmptyState(
                        icon: Icons.search_off_rounded,
                        title: 'No policy records',
                        message: 'Clear filters or search another booking.',
                        actionLabel: 'Clear',
                        onAction: () {
                          setState(() => _query = '');
                          store.setPolicyFilter('All');
                        },
                      )
                    : Column(
                        children: [
                          for (final row in rows)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 10),
                              child: _PolicyRow(
                                policy: row,
                                status: store.policyStatus(row),
                                onDetail: () => _showPolicy(context, row),
                                onVerify: () {
                                  store.verifyPolicy(row.id);
                                  insuranceSnack(context, 'Policy verified');
                                },
                              ),
                            ),
                        ],
                      ),
              ),
              right: InsuranceSectionCard(
                title: 'Coverage summary',
                icon: Icons.shield_outlined,
                child: Column(
                  children: [
                    InsuranceInfoRow(
                      icon: Icons.policy_outlined,
                      label: 'Active coverage',
                      value: 'PKR 43M',
                    ),
                    InsuranceInfoRow(
                      icon: Icons.people_alt_outlined,
                      label: 'Insured parties',
                      value: '18 parties',
                    ),
                    InsuranceInfoRow(
                      icon: Icons.description_outlined,
                      label: 'Documents',
                      value: '31 files',
                    ),
                    InsuranceInfoRow(
                      icon: Icons.warning_amber_outlined,
                      label: 'Risk flags',
                      value: '3 high',
                    ),
                    const SizedBox(height: 10),
                    CoreSecondaryButton(
                      icon: Icons.download_outlined,
                      label: 'Export policy list',
                      compact: true,
                      onTap: () => insuranceSnack(
                        context,
                        'Policy export prepared',
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Iterable<InsurancePolicy> _rows(InsurancePartnerDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = InsurancePartnerDemoData.policies.where((row) {
      final status = store.policyStatus(row);
      final matchesFilter = switch (store.policyFilter) {
        'Active' => status == InsuranceStatus.active,
        'Pending' => status == InsuranceStatus.pending,
        'Verified' => status == InsuranceStatus.verified,
        'High Risk' => status == InsuranceStatus.highRisk,
        _ => true,
      };
      final haystack =
          '${row.project} ${row.booking} ${row.insuredParty} ${row.coverage} ${row.document}'
              .toLowerCase();
      return matchesFilter && haystack.contains(lower);
    }).toList();
    if (_sort == 'Validity') result = result.reversed.toList();
    return result;
  }

  void _showPolicy(BuildContext context, InsurancePolicy policy) {
    final store = InsurancePartnerDemoStore.instance;
    showInsuranceSheet(
      context,
      title: policy.project,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InsuranceInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Booking',
            value: policy.booking,
          ),
          InsuranceInfoRow(
            icon: Icons.business_outlined,
            label: 'Insured party',
            value: policy.insuredParty,
          ),
          InsuranceInfoRow(
            icon: Icons.shield_outlined,
            label: 'Coverage',
            value: policy.coverage,
          ),
          InsuranceInfoRow(
            icon: Icons.calendar_month_outlined,
            label: 'Validity',
            value: policy.validity,
          ),
          InsuranceInfoRow(
            icon: Icons.description_outlined,
            label: 'Document',
            value: policy.document,
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.report_problem_outlined,
                  label: 'Flag risk',
                  onTap: () {
                    store.flagPolicy(policy.id);
                    Navigator.pop(context);
                    insuranceSnack(context, 'Policy risk flagged');
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.article_outlined,
                  label: 'Contract',
                  onTap: () {
                    Navigator.pop(context);
                    Navigator.pushNamed(context, CoreRoutes.contract);
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

class _PolicyRow extends StatelessWidget {
  final InsurancePolicy policy;
  final InsuranceStatus status;
  final VoidCallback onDetail;
  final VoidCallback onVerify;

  const _PolicyRow({
    required this.policy,
    required this.status,
    required this.onDetail,
    required this.onVerify,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 16,
      padding: const EdgeInsets.all(11),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  policy.project,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              InsuranceStatusChip(status: status),
            ],
          ),
          const SizedBox(height: 5),
          Row(
            children: [
              Expanded(
                child: Text(
                  '${policy.booking} - ${policy.insuredParty} - ${policy.validity}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Detail',
                  compact: true,
                  onTap: onDetail,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.verified_outlined,
                  label: 'Verify',
                  compact: true,
                  onTap: onVerify,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
