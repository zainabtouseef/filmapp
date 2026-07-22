import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/theme/app_breakpoints.dart';
import '../routes/director_producer_routes.dart';
import '../widgets/dashboard/dp_command_header.dart';
import '../widgets/dashboard/dp_deal_pipeline.dart';
import '../widgets/dashboard/dp_financial_centre.dart';
import '../widgets/dashboard/dp_dashboard_insights.dart';
import '../widgets/dashboard/dp_priority_actions.dart';
import '../widgets/dashboard/dp_project_deck.dart';
import '../widgets/dashboard/dp_pulse_strip.dart';
import '../widgets/dashboard/dp_today_timeline.dart';
import '../widgets/dp_layout_helpers.dart';

/// The Director/Producer command dashboard — a compact, cinematic
/// production-management console. Mobile gets a single scrolling
/// column; desktop splits into a dominant operational column plus a
/// contextual side rail, alongside the shell's own nav rail/top bar.
class DPHomeDashboardScreen extends StatelessWidget {
  const DPHomeDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final wide = constraints.maxWidth >= AppBreakpoints.tablet;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DPCommandHeader(),
            const SizedBox(height: 14),
            const DPPulseStrip(),
            const SizedBox(height: 14),
            if (wide) const _WideBody() else const _CompactBody(),
          ],
        );
      },
    );
  }
}

class _WideBody extends StatelessWidget {
  const _WideBody();

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Expanded(
          flex: 7,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _TodaySection(),
              SizedBox(height: 14),
              _ProjectDeckSection(),
              SizedBox(height: 14),
              _FinancialSection(),
              SizedBox(height: 14),
              _PipelineSection(),
            ],
          ),
        ),
        const SizedBox(width: 14),
        const Expanded(
          flex: 4,
          child: _PrioritySection(),
        ),
      ],
    );
  }
}

class _CompactBody extends StatelessWidget {
  const _CompactBody();

  @override
  Widget build(BuildContext context) {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _PrioritySection(),
        SizedBox(height: 14),
        _TodaySection(),
        SizedBox(height: 14),
        _ProjectDeckSection(),
        SizedBox(height: 14),
        _FinancialSection(),
        SizedBox(height: 14),
        _PipelineSection(),
      ],
    );
  }
}

class _PrioritySection extends StatelessWidget {
  const _PrioritySection();

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Needs your attention · ${dpPriorityItems().length}',
      icon: Icons.priority_high_rounded,
      actionText: 'View all',
      onActionTap: () => Navigator.pushNamed(context, CoreRoutes.notifications),
      child: const DPPriorityActions(),
    );
  }
}

class _TodaySection extends StatelessWidget {
  const _TodaySection();

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: "Today's Production Timeline",
      icon: Icons.today_outlined,
      actionText: 'Full schedule',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.schedule),
      child: const DPTodayTimeline(),
    );
  }
}

class _ProjectDeckSection extends StatelessWidget {
  const _ProjectDeckSection();

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Project Command Deck',
      icon: Icons.dashboard_customize_rounded,
      actionText: 'View all',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.projects),
      child: const DPProjectDeck(),
    );
  }
}

class _FinancialSection extends StatelessWidget {
  const _FinancialSection();

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Financial Command Centre',
      icon: Icons.account_balance_wallet_outlined,
      actionText: 'View payments',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.payments),
      child: const DPFinancialCentre(),
    );
  }
}

class _PipelineSection extends StatelessWidget {
  const _PipelineSection();

  @override
  Widget build(BuildContext context) {
    return DPSectionCard(
      title: 'Deals & Contracts Pipeline',
      icon: Icons.handshake_outlined,
      actionText: 'View all',
      onActionTap: () =>
          Navigator.pushNamed(context, DirectorProducerRoutes.bargaining),
      child: const DPDealPipeline(),
    );
  }
}
