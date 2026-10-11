import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../shared/cards/cine_card_system.dart';
import '../../../core/insurance/insurance_controller.dart';
import '../../../core/insurance/insurance_models.dart';
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

  void _refresh() => setState(() {
        _future = _load();
      });

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const PortalDashboardPage(
        children: [
          CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to view insurance operations',
            message: 'Policies and claims are loaded from the server.',
          ),
        ],
      );
    }

    return FutureBuilder<_InsuranceDashboardBundle>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const PortalDashboardPage(
            showLiveStrip: false,
            children: [SkeletonCard(height: 420)],
          );
        }
        if (snapshot.hasError) {
          return PortalDashboardPage(
            showLiveStrip: false,
            children: [
              _LoadError(
                message: 'Could not load insurance dashboard',
                onRetry: _refresh,
              ),
            ],
          );
        }

        final data = snapshot.data!;
        final highRisk = data.policies
            .where((policy) => policy.riskLevel.toLowerCase().contains('high'))
            .length;
        final latestPolicy = data.policies.isEmpty ? null : data.policies.first;
        final displayName = AuthScope.maybeOf(context)?.user?.displayName;
        final name = (displayName == null || displayName.trim().isEmpty)
            ? 'Insurance partner'
            : displayName.trim();

        return PortalDashboardPage(
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
                PortalHeroStat(value: '$highRisk', label: 'High risk'),
              ],
              ctaLabel: 'Refresh',
              onCta: _refresh,
            ),
            const PortalStaggeredReveal(
              children: [PortalLiveClockWidget()],
            ),
            PortalCommandCenter(
              eyebrow: 'Insurance operations',
              title: 'Policy Command Centre',
              subtitle:
                  'Coverage, claims and safety actions in one live workspace.',
              icon: Icons.health_and_safety_outlined,
              primaryTitle:
                  latestPolicy == null ? 'Coverage overview' : 'Latest policy',
              primary: latestPolicy == null
                  ? const CoreEmptyState(
                      icon: Icons.policy_outlined,
                      title: 'No live policies',
                      message:
                          'Policies appear here as soon as coverage is issued.',
                    )
                  : _PolicySummary(policy: latestPolicy),
              actionLabel: 'View policies',
              onAction: () => Navigator.pushNamed(
                context,
                InsurancePartnerRoutes.records,
              ),
              actions: [
                PortalCommandAction(
                  icon: Icons.policy_outlined,
                  title: 'Policy records',
                  subtitle: 'Coverage, dates and insured productions',
                  value: '${data.policies.length}',
                  onTap: () => Navigator.pushNamed(
                    context,
                    InsurancePartnerRoutes.records,
                  ),
                ),
                PortalCommandAction(
                  icon: Icons.assignment_late_outlined,
                  title: 'Claims desk',
                  subtitle: 'Review evidence and claim decisions',
                  value: '${data.dashboard.openClaims}',
                  onTap: () => Navigator.pushNamed(
                    context,
                    InsurancePartnerRoutes.claims,
                  ),
                ),
                PortalCommandAction(
                  icon: Icons.fact_check_outlined,
                  title: 'Safety checks',
                  subtitle: 'Permits and production readiness',
                  onTap: () => Navigator.pushNamed(
                    context,
                    InsurancePartnerRoutes.safety,
                  ),
                ),
                PortalCommandAction(
                  icon: Icons.warning_amber_outlined,
                  title: 'Incident reports',
                  subtitle: 'Open the live incident response queue',
                  onTap: () => Navigator.pushNamed(
                    context,
                    InsurancePartnerRoutes.incidents,
                  ),
                ),
              ],
            ),
          ],
        );
      },
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
        PortalCommandDataRow(
          icon: Icons.person_outline,
          label: 'Insured',
          value: policy.insuredUserName,
        ),
        PortalCommandDataRow(
          icon: Icons.shield_outlined,
          label: 'Coverage',
          value: policy.coverageSummary.isEmpty
              ? 'Coverage not set'
              : policy.coverageSummary,
        ),
        PortalCommandDataRow(
          icon: Icons.warning_amber_outlined,
          label: 'Risk',
          value: policy.riskLevel,
        ),
        PortalCommandDataRow(
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
