import 'package:flutter/material.dart';

import '../../../core/analytics/analytics_widgets.dart';
import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../shared/dashboard/dashboard_kit.dart';
import '../routes/insurance_partner_routes.dart';
import '../widgets/insurance_partner_components.dart';

class IN01InsuranceDashboardScreen extends StatefulWidget {
  const IN01InsuranceDashboardScreen({super.key});

  @override
  State<IN01InsuranceDashboardScreen> createState() =>
      _IN01InsuranceDashboardScreenState();
}

class _IN01InsuranceDashboardScreenState
    extends State<IN01InsuranceDashboardScreen> {
  Future<_InsuranceDashboardBundle>? _future;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<_InsuranceDashboardBundle>? _load() {
    final insurance = InsuranceScope.maybeOf(context);
    if (insurance == null) return null;
    return Future.wait([
      insurance.dashboard(force: true),
      insurance.policies(force: true),
      insurance.claims(force: true),
    ]).then(
      (values) => _InsuranceDashboardBundle(
        dashboard: values[0] as InsuranceDashboardDto,
        policies: values[1] as List<InsurancePolicyDto>,
        claims: values[2] as List<InsuranceClaimDto>,
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
        InsuranceSectionCard(
          title: 'Insurance dashboard',
          icon: Icons.health_and_safety_outlined,
          selected: true,
          actionText: _future == null ? null : 'Refresh',
          onActionTap: _refresh,
          child: _future == null
              ? const CoreEmptyState(
                  icon: Icons.lock_outline_rounded,
                  title: 'Sign in to view insurance operations',
                  message: 'Policies and claims are loaded from the server.',
                )
              : FutureBuilder<_InsuranceDashboardBundle>(
                  future: _future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const SkeletonCard(height: 420);
                    }
                    if (snapshot.hasError) {
                      return _LoadError(
                        message: 'Could not load insurance dashboard',
                        onRetry: _refresh,
                      );
                    }
                    final data = snapshot.data!;
                    final highRisk = data.policies
                        .where((policy) =>
                            policy.riskLevel.toLowerCase().contains('high'))
                        .length;
                    final latestPolicy =
                        data.policies.isEmpty ? null : data.policies.first;

                    final displayName =
                        AuthScope.maybeOf(context)?.user?.displayName;
                    final name =
                        (displayName == null || displayName.trim().isEmpty)
                            ? 'Insurance partner'
                            : displayName.trim();

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        PortalHeroCard(
                          initials: _initialsFor(name),
                          name: name,
                          badgeLabel: 'Verified insurer',
                          stats: [
                            PortalHeroStat(
                              value: '${data.dashboard.activePolicyCount}',
                              label: 'Active policies',
                            ),
                            PortalHeroStat(
                              value: '${data.dashboard.openClaims}',
                              label: 'Open claims',
                            ),
                          ],
                          ctaLabel: 'Refresh',
                          onCta: _refresh,
                        ),
                        const SizedBox(height: 12),
                        InsuranceResponsiveGrid(
                          children: [
                            PortalQuickStatTile(
                              icon: Icons.policy_outlined,
                              value: '${data.dashboard.activePolicyCount}',
                              label: 'Active policies',
                              delta: '${data.dashboard.policyCount} total',
                              tone: CineTone.positive,
                              onTap: () => Navigator.pushNamed(
                                context,
                                InsurancePartnerRoutes.records,
                              ),
                            ),
                            PortalQuickStatTile(
                              icon: Icons.assignment_late_outlined,
                              value: '${data.dashboard.openClaims}',
                              label: 'Open claims',
                              delta: '${data.claims.length} total',
                              tone: CineTone.critical,
                              onTap: () => Navigator.pushNamed(
                                context,
                                InsurancePartnerRoutes.claims,
                              ),
                            ),
                            PortalQuickStatTile(
                              icon: Icons.warning_amber_outlined,
                              value: '$highRisk',
                              label: 'High risk',
                              delta: 'Live policies',
                              tone: CineTone.warning,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        InsuranceTwoColumn(
                          left: InsuranceSectionCard(
                            title: 'Latest policy',
                            icon: Icons.policy_outlined,
                            child: latestPolicy == null
                                ? const CoreEmptyState(
                                    icon: Icons.policy_outlined,
                                    title: 'No live policies',
                                    message:
                                        'Seed or create insurance policies in the backend to fill this dashboard.',
                                  )
                                : _PolicySummary(policy: latestPolicy),
                          ),
                          right: InsuranceSectionCard(
                            title: 'Operational links',
                            icon: Icons.route_outlined,
                            child: Column(
                              children: [
                                InsuranceResponsiveGrid(
                                  minWidth: 200,
                                  children: [
                                    PortalModuleCard(
                                      icon: Icons.policy_outlined,
                                      name: 'Records',
                                      count: data.policies.isEmpty
                                          ? null
                                          : data.policies.length,
                                      description:
                                          'Shoot insurance policies and coverage.',
                                      actionLabel: 'Open records',
                                      tone: CineTone.information,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        InsurancePartnerRoutes.records,
                                      ),
                                    ),
                                    PortalModuleCard(
                                      icon: Icons.assignment_late_outlined,
                                      name: 'Claims',
                                      count: data.dashboard.openClaims > 0
                                          ? data.dashboard.openClaims
                                          : null,
                                      description:
                                          'File and track claim decisions.',
                                      actionLabel: 'Open claims',
                                      tone: CineTone.premium,
                                      onTap: () => Navigator.pushNamed(
                                        context,
                                        InsurancePartnerRoutes.claims,
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 10),
                                const InlineNotice(
                                  message:
                                      'Safety checks and incidents need read/list APIs before dashboards can show live rows.',
                                  icon: Icons.info_outline_rounded,
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

class _PolicySummary extends StatelessWidget {
  final InsurancePolicyDto policy;

  const _PolicySummary({required this.policy});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        InsuranceInfoRow(
          icon: Icons.person_outline,
          label: 'Insured',
          value: policy.insuredUserName,
        ),
        InsuranceInfoRow(
          icon: Icons.shield_outlined,
          label: 'Coverage',
          value: policy.coverageSummary.isEmpty
              ? 'Coverage not set'
              : policy.coverageSummary,
        ),
        InsuranceInfoRow(
          icon: Icons.warning_amber_outlined,
          label: 'Risk',
          value: policy.riskLevel,
        ),
        InsuranceInfoRow(
          icon: Icons.flag_outlined,
          label: 'Status',
          value: insuranceStatusLabel(insuranceStatusFromString(policy.status)),
        ),
      ],
    );
  }
}

class _InsuranceDashboardBundle {
  final InsuranceDashboardDto dashboard;
  final List<InsurancePolicyDto> policies;
  final List<InsuranceClaimDto> claims;

  const _InsuranceDashboardBundle({
    required this.dashboard,
    required this.policies,
    required this.claims,
  });
}

class _LoadError extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _LoadError({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CoreEmptyState(
          icon: Icons.cloud_off_outlined,
          title: message,
          message: 'Check your connection and try again.',
        ),
        const SizedBox(height: 10),
        CoreSecondaryButton(
          icon: Icons.refresh_rounded,
          label: 'Try again',
          compact: true,
          onTap: onRetry,
        ),
      ],
    );
  }
}

String _initialsFor(String name) {
  final parts =
      name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
  if (parts.isEmpty) return '?';
  if (parts.length == 1) return parts.first[0].toUpperCase();
  return (parts[0][0] + parts[1][0]).toUpperCase();
}
