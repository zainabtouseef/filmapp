import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/core_ui/core_routes.dart';
import '../../../core/director/director_dashboard_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_controller.dart';
import '../../../core/tour/tour_preferences_store.dart';
import '../../../core/tour/tour_target.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dashboard/dp_command_header.dart';
import '../widgets/dashboard/dp_deal_pipeline.dart';
import '../widgets/dashboard/dp_financial_centre.dart';
import '../widgets/dashboard/dp_priority_actions.dart';
import '../widgets/dashboard/dp_project_deck.dart';
import '../widgets/dashboard/dp_pulse_strip.dart';
import '../widgets/dashboard/dp_today_timeline.dart';
import '../widgets/dp_glass_card.dart';
import '../widgets/dp_layout_helpers.dart';
import '../widgets/dp_tour_steps.dart';

/// The Director/Producer command dashboard — a compact, cinematic
/// production-management console. Mobile gets a single scrolling
/// column; desktop splits into a dominant operational column plus a
/// contextual side rail, alongside the shell's own nav rail/top bar.
class DPHomeDashboardScreen extends StatefulWidget {
  const DPHomeDashboardScreen({super.key});

  @override
  State<DPHomeDashboardScreen> createState() => _DPHomeDashboardScreenState();
}

class _DPHomeDashboardScreenState extends State<DPHomeDashboardScreen> {
  Future<DirectorDashboard>? _future;
  bool _autoTourChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
    _maybeAutoStartTour();
  }

  void _maybeAutoStartTour() {
    if (_autoTourChecked) return;
    _autoTourChecked = true;
    const store = TourPreferencesStore();
    store.hasSeenTour(dpTourId).then((seen) {
      if (seen || !mounted) return;
      final controller = TourScope.maybeOf(context);
      if (controller == null || controller.isActive) return;
      controller.start(
        dpTourSteps,
        tourId: dpTourId,
        onFinished: () => store.markSeen(dpTourId),
      );
    });
  }

  Future<DirectorDashboard> _load() async {
    final auth = AuthScope.maybeOf(context);
    if (auth == null || !auth.isAuthenticated) {
      throw const ApiException(
        code: 'auth.required',
        message: 'Sign in to load the live Director dashboard.',
      );
    }
    return auth.directorDashboard();
  }

  void _retry() {
    setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DirectorDashboard>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const _DashboardLoadingState();
        }
        if (snapshot.hasError || !snapshot.hasData) {
          final message = snapshot.error is ApiException
              ? (snapshot.error! as ApiException).message
              : 'Could not load the live Director dashboard.';
          return _DashboardErrorState(message: message, onRetry: _retry);
        }
        final dashboard = snapshot.data!;
        return LayoutBuilder(
          builder: (context, constraints) {
            final wide = constraints.maxWidth >= AppBreakpoints.tablet;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DPCommandHeader(summary: dashboard.summary),
                const SizedBox(height: 14),
                DPPulseStrip(summary: dashboard.summary),
                const SizedBox(height: 14),
                const _ApplicationsShortcutSection(),
                const SizedBox(height: 14),
                if (wide)
                  _WideBody(dashboard: dashboard)
                else
                  _CompactBody(dashboard: dashboard),
              ],
            );
          },
        );
      },
    );
  }
}

class _ApplicationsShortcutSection extends StatelessWidget {
  const _ApplicationsShortcutSection();

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Casting, Auditions & Applications',
      icon: Icons.how_to_reg_outlined,
      actionText: 'Open projects',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: [
          TourTarget(
            id: 'dp.reviewApplications',
            child: FilledButton.icon(
              icon: const Icon(Icons.assignment_ind_outlined),
              label: const Text('Review project applications'),
              onPressed: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.projects),
            ),
          ),
          TourTarget(
            id: 'dp.createAudition',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.video_camera_front_outlined),
              label: const Text('Create audition requirements'),
              onPressed: () => Navigator.pushNamed(
                context,
                DirectorProducerRoutes.projects,
              ),
            ),
          ),
          TourTarget(
            id: 'dp.findProviders',
            child: OutlinedButton.icon(
              icon: const Icon(Icons.travel_explore_outlined),
              label: const Text('Find providers'),
              onPressed: () => Navigator.pushNamed(
                  context, DirectorProducerRoutes.marketplace),
            ),
          ),
        ],
      ),
    );
  }
}

class _WideBody extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _WideBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodaySection(dashboard: dashboard),
              const SizedBox(height: 14),
              _ProjectDeckSection(dashboard: dashboard),
              const SizedBox(height: 14),
              _FinancialSection(dashboard: dashboard),
              const SizedBox(height: 14),
              _PipelineSection(dashboard: dashboard),
            ],
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          flex: 4,
          child: _PrioritySection(dashboard: dashboard),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _CompactBody({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrioritySection(dashboard: dashboard),
        const SizedBox(height: 14),
        _TodaySection(dashboard: dashboard),
        const SizedBox(height: 14),
        _ProjectDeckSection(dashboard: dashboard),
        const SizedBox(height: 14),
        _FinancialSection(dashboard: dashboard),
        const SizedBox(height: 14),
        _PipelineSection(dashboard: dashboard),
      ],
    );
  }
}

class _PrioritySection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _PrioritySection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return TourTarget(
      id: 'dp.needsAttention',
      child: DPSectionCard(
        title: 'Needs your attention · ${dashboard.priorityActions.length}',
        icon: Icons.priority_high_rounded,
        actionText: 'View all',
        onActionTap: () =>
            Navigator.pushNamed(context, CoreRoutes.notifications),
        child: DPPriorityActions(items: dashboard.priorityActions),
      ),
    );
  }
}

class _TodaySection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _TodaySection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: "Today's Production Timeline",
      icon: Icons.today_outlined,
      actionText: 'Full schedule',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.schedule),
      child: DPTodayTimeline(events: dashboard.dpTimeline),
    );
  }
}

class _ProjectDeckSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _ProjectDeckSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Project Command Deck',
      icon: Icons.dashboard_customize_rounded,
      actionText: 'View all',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      child: DPProjectDeck(projects: dashboard.dpProjects),
    );
  }
}

class _FinancialSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _FinancialSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Financial Command Centre',
      icon: Icons.account_balance_wallet_outlined,
      actionText: 'View payments',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      child: DPFinancialCentre(
        payments: dashboard.dpPayments,
        summary: dashboard.summary,
      ),
    );
  }
}

class _PipelineSection extends StatelessWidget {
  final DirectorDashboard dashboard;

  const _PipelineSection({required this.dashboard});

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Deals & Contracts Pipeline',
      icon: Icons.handshake_outlined,
      actionText: 'View all',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      child: DPDealPipeline(items: dashboard.pipeline),
    );
  }
}

class _DashboardLoadingState extends StatelessWidget {
  const _DashboardLoadingState();

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Row(
        children: [
          const SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'Loading live Director dashboard…',
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DashboardErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _DashboardErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return DPGlassCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.cloud_off_outlined, color: colors.warning, size: 28),
          const SizedBox(height: 10),
          Text(
            'Live dashboard unavailable',
            style: AppTextStyles.cardTitle.copyWith(
              color: colors.textPrimary,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          TextButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }
}
