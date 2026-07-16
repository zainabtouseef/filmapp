import 'package:flutter/material.dart';

import '../../../core/core_ui/core_routes.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/role_portal_demo_data.dart';
import '../models/role_portal_models.dart';
import '../widgets/portal_media_frame.dart';
import '../widgets/role_portal_components.dart';
import '../widgets/role_portal_shell.dart';

enum _PortalViewMode { content, loading, empty, error }

class RolePortalScreen extends StatefulWidget {
  final String routeName;

  const RolePortalScreen({
    super.key,
    required this.routeName,
  });

  @override
  State<RolePortalScreen> createState() => _RolePortalScreenState();
}

class _RolePortalScreenState extends State<RolePortalScreen> {
  String _query = '';
  String _filter = 'All';
  _PortalViewMode _mode = _PortalViewMode.content;

  @override
  void didUpdateWidget(covariant RolePortalScreen oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.routeName != widget.routeName) {
      _query = '';
      _filter = 'All';
      _mode = _PortalViewMode.content;
    }
  }

  @override
  Widget build(BuildContext context) {
    final portal = RolePortalDemoData.portalForRoute(widget.routeName);
    final screen = RolePortalDemoData.screenForRoute(widget.routeName);
    return RolePortalShell(
      portal: portal,
      screen: screen,
      child: AnimatedBuilder(
        animation: RolePortalDemoStore.instance,
        builder: (context, _) => _PortalBody(
          portal: portal,
          screen: screen,
          query: _query,
          filter: _filter,
          mode: _mode,
          onQueryChanged: (value) => setState(() => _query = value),
          onFilterChanged: (value) => setState(() => _filter = value),
          onModeChanged: (value) => setState(() => _mode = value),
        ),
      ),
    );
  }
}

class _PortalBody extends StatelessWidget {
  final RolePortalSpec portal;
  final RolePortalScreenSpec screen;
  final String query;
  final String filter;
  final _PortalViewMode mode;
  final ValueChanged<String> onQueryChanged;
  final ValueChanged<String> onFilterChanged;
  final ValueChanged<_PortalViewMode> onModeChanged;

  const _PortalBody({
    required this.portal,
    required this.screen,
    required this.query,
    required this.filter,
    required this.mode,
    required this.onQueryChanged,
    required this.onFilterChanged,
    required this.onModeChanged,
  });

  @override
  Widget build(BuildContext context) {
    final records = _filteredRecords();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _ScreenIntro(portal: portal, screen: screen),
        const SizedBox(height: 12),
        MetricActionRail(
          items: [
            for (final metric in RolePortalDemoData.metricsFor(portal))
              MetricActionItem(
                icon: metric.icon,
                value: metric.value,
                title: metric.label,
                subtitle: metric.delta,
                accentColor: portalToneColor(context, metric.tone),
              ),
          ],
        ),
        const SizedBox(height: 12),
        PortalSearchFilterBar(
          query: query,
          onQueryChanged: onQueryChanged,
          filters: screen.filters,
          selectedFilter: filter,
          onFilterChanged: onFilterChanged,
        ),
        const SizedBox(height: 10),
        _StateModeStrip(mode: mode, onChanged: onModeChanged),
        const SizedBox(height: 14),
        if (mode != _PortalViewMode.content)
          _ModePanel(mode: mode, screen: screen)
        else
          PortalTwoColumn(
            left: _PrimaryPanel(screen: screen, records: records),
            right: _SecondaryPanel(
              portal: portal,
              screen: screen,
              records: records,
            ),
          ),
      ],
    );
  }

  List<PortalRecord> _filteredRecords() {
    final normalized = query.trim().toLowerCase();
    return RolePortalDemoData.records.where((record) {
      final matchesQuery = normalized.isEmpty ||
          record.title.toLowerCase().contains(normalized) ||
          record.subtitle.toLowerCase().contains(normalized) ||
          record.meta.toLowerCase().contains(normalized);
      final matchesFilter = filter == 'All' ||
          (filter == 'Urgent' && record.status.contains('PAYMENT')) ||
          (filter == 'Pending' && record.status.contains('PENDING')) ||
          (filter == 'Verified' && record.status.contains('SECURED')) ||
          filter == 'Archived';
      return matchesQuery && matchesFilter;
    }).toList();
  }
}

class _ScreenIntro extends StatelessWidget {
  final RolePortalSpec portal;
  final RolePortalScreenSpec screen;

  const _ScreenIntro({
    required this.portal,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return PortalPanel(
      title: screen.id,
      icon: screen.icon,
      actionText: 'Role switch',
      onActionTap: () => Navigator.pushNamed(context, CoreRoutes.profileRoles),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: colors.goldGradient,
            ),
            child: Icon(portal.icon, color: colors.onGold, size: 18),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  screen.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(label: portal.shortLabel, color: colors.goldMid),
                    lifecycleChip(
                      context,
                      label: lifecycleLabel(
                        RolePortalDemoStore.instance.currentStatus,
                      ),
                    ),
                    StatusChip(
                        label: 'Demo state linked', color: colors.infoBlue),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _StateModeStrip extends StatelessWidget {
  final _PortalViewMode mode;
  final ValueChanged<_PortalViewMode> onChanged;

  const _StateModeStrip({
    required this.mode,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _modeChip(context, 'Content', _PortalViewMode.content),
          _modeChip(context, 'Loading', _PortalViewMode.loading),
          _modeChip(context, 'Empty', _PortalViewMode.empty),
          _modeChip(context, 'Error', _PortalViewMode.error),
          const SizedBox(width: 8),
          Text(
            'State preview',
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _modeChip(BuildContext context, String label, _PortalViewMode value) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () => onChanged(value),
        child: StatusChip(
          label: label,
          color: mode == value ? colors.goldMid : colors.textSecondary,
        ),
      ),
    );
  }
}

class _ModePanel extends StatelessWidget {
  final _PortalViewMode mode;
  final RolePortalScreenSpec screen;

  const _ModePanel({
    required this.mode,
    required this.screen,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final (icon, title, message) = switch (mode) {
      _PortalViewMode.loading => (
          Icons.hourglass_top_rounded,
          'Loading ${screen.navLabel}',
          'Fetching verified demo records and media frames.'
        ),
      _PortalViewMode.empty => (
          Icons.inbox_outlined,
          'No matching records',
          'Try another filter or create a new demo record.'
        ),
      _PortalViewMode.error => (
          Icons.error_outline_rounded,
          'Demo sync issue',
          'Retry is available and keeps the local demo state intact.'
        ),
      _ => (Icons.check_circle_outline, 'Ready', 'Content is available.'),
    };
    return PortalPanel(
      title: title,
      icon: icon,
      actionText: mode == _PortalViewMode.error ? 'Retry' : 'Reset',
      onActionTap: () => showCoreSnack(context, '$title resolved'),
      child: SizedBox(
        width: double.infinity,
        child: Column(
          children: [
            Icon(icon, color: colors.goldDark, size: 34),
            const SizedBox(height: 10),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTextStyles.body.copyWith(color: colors.textSecondary),
            ),
          ],
        ),
      ),
    );
  }
}

class _PrimaryPanel extends StatelessWidget {
  final RolePortalScreenSpec screen;
  final List<PortalRecord> records;

  const _PrimaryPanel({
    required this.screen,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    final asset = RolePortalDemoData.mediaForCategory(screen.mediaCategory);
    return switch (screen.kind) {
      PortalScreenKind.profile ||
      PortalScreenKind.composer ||
      PortalScreenKind.manager ||
      PortalScreenKind.safety =>
        PortalPanel(
          title: 'Interactive Form',
          icon: Icons.edit_note_rounded,
          child: _PortalForm(screen: screen),
        ),
      PortalScreenKind.portfolio => PortalPanel(
          title: 'Media Gallery',
          icon: Icons.collections_outlined,
          actionText: 'Open viewer',
          onActionTap: () => showCoreSnack(context, 'Media viewer opened'),
          child: _MediaGallery(screen: screen),
        ),
      PortalScreenKind.calendar => PortalPanel(
          title: 'Availability Planner',
          icon: Icons.calendar_month_outlined,
          child: _CalendarGrid(screen: screen),
        ),
      PortalScreenKind.finance => PortalPanel(
          title: 'Finance Timeline',
          icon: Icons.payments_outlined,
          actionText: 'Ledger',
          onActionTap: () => Navigator.pushNamed(context, CoreRoutes.ledger),
          child: _FinancePanel(screen: screen),
        ),
      PortalScreenKind.reports => PortalPanel(
          title: 'Reporting Snapshot',
          icon: Icons.analytics_outlined,
          child: _ReportsPanel(screen: screen),
        ),
      _ => PortalPanel(
          title: 'Featured Work',
          icon: Icons.auto_awesome_mosaic_outlined,
          actionText: 'Preview',
          onActionTap: () => showCoreSnack(context, 'Preview opened'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PortalMediaFrame(
                asset: asset,
                badge: screen.mediaCategory.toUpperCase(),
              ),
              const SizedBox(height: 12),
              for (final record in records.take(2))
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: _CompactRecordRow(record: record),
                ),
            ],
          ),
        ),
    };
  }
}

class _SecondaryPanel extends StatelessWidget {
  final RolePortalSpec portal;
  final RolePortalScreenSpec screen;
  final List<PortalRecord> records;

  const _SecondaryPanel({
    required this.portal,
    required this.screen,
    required this.records,
  });

  @override
  Widget build(BuildContext context) {
    return PortalPanel(
      title: 'Actions & Linked Records',
      icon: Icons.route_outlined,
      actionText: 'Advance status',
      onActionTap: () {
        RolePortalDemoStore.instance.advanceLifecycle();
        showCoreSnack(context, 'Booking lifecycle advanced');
      },
      child: Column(
        children: [
          PortalLifecycleTimeline(
            items: RolePortalDemoData.workflow,
            activeIndex: RolePortalDemoStore.instance.lifecycleIndex
                .clamp(0, RolePortalDemoData.workflow.length - 1)
                .toInt(),
          ),
          const SizedBox(height: 10),
          ...records.take(3).map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: PortalRecordCard(
                    record: record,
                    shortlisted: RolePortalDemoStore.instance.shortlisted
                        .contains(record.id),
                    onShortlist: () {
                      RolePortalDemoStore.instance.toggleShortlist(record.id);
                      showCoreSnack(
                          context, 'Shortlist updated for ${record.id}');
                    },
                    onPrimary: () => _handlePrimary(context, screen, record),
                    onSecondary: () =>
                        Navigator.pushNamed(context, CoreRoutes.chat),
                  ),
                ),
              ),
          const SizedBox(height: 2),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.file_download_outlined,
                  label: screen.secondaryAction,
                  compact: true,
                  onTap: () => showCoreSnack(
                    context,
                    '${screen.secondaryAction} completed for ${portal.shortLabel}',
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.check_circle_outline,
                  label: screen.primaryAction,
                  compact: true,
                  onTap: () => _handleScreenAction(context, screen),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

void _handlePrimary(
  BuildContext context,
  RolePortalScreenSpec screen,
  PortalRecord record,
) {
  RolePortalDemoStore.instance.advanceLifecycle();
  showCoreSnack(context, '${screen.primaryAction}: ${record.id}');
}

void _handleScreenAction(BuildContext context, RolePortalScreenSpec screen) {
  switch (screen.kind) {
    case PortalScreenKind.finance:
      Navigator.pushNamed(context, CoreRoutes.ledger);
    case PortalScreenKind.detail:
      Navigator.pushNamed(context, CoreRoutes.contract);
    case PortalScreenKind.inbox:
      Navigator.pushNamed(context, CoreRoutes.chat);
    case PortalScreenKind.safety:
      Navigator.pushNamed(context, CoreRoutes.report);
    default:
      RolePortalDemoStore.instance.save(screen.route, screen.primaryAction);
      showCoreSnack(context, '${screen.primaryAction} saved');
  }
}

class _PortalForm extends StatefulWidget {
  final RolePortalScreenSpec screen;

  const _PortalForm({required this.screen});

  @override
  State<_PortalForm> createState() => _PortalFormState();
}

class _PortalFormState extends State<_PortalForm> {
  late final List<TextEditingController> _controllers;
  String? _error;

  @override
  void initState() {
    super.initState();
    _controllers = widget.screen.formFields
        .map((field) => TextEditingController(text: _seedValue(field)))
        .toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0;
            index < widget.screen.formFields.length;
            index++) ...[
          CoreTextField(
            controller: _controllers[index],
            label: widget.screen.formFields[index],
            icon: _fieldIcon(index),
            errorText: _error != null && _controllers[index].text.trim().isEmpty
                ? _error
                : null,
          ),
          const SizedBox(height: 10),
        ],
        Row(
          children: [
            Expanded(
              child: CoreSecondaryButton(
                icon: Icons.save_outlined,
                label: 'Save draft',
                compact: true,
                onTap: () => showCoreSnack(context, 'Draft saved'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: CorePrimaryButton(
                icon: Icons.check_rounded,
                label: widget.screen.primaryAction,
                compact: true,
                onTap: _submit,
              ),
            ),
          ],
        ),
      ],
    );
  }

  void _submit() {
    final invalid = _controllers.any((c) => c.text.trim().isEmpty);
    if (invalid) {
      setState(() => _error = 'Required');
      return;
    }
    RolePortalDemoStore.instance.save(
      widget.screen.route,
      _controllers.map((c) => c.text.trim()).join(' · '),
    );
    setState(() => _error = null);
    showCoreSnack(context, '${widget.screen.title} saved');
  }

  IconData _fieldIcon(int index) {
    return const [
      Icons.title_rounded,
      Icons.category_outlined,
      Icons.date_range_outlined,
      Icons.notes_outlined,
    ][index.clamp(0, 3)];
  }

  String _seedValue(String field) {
    if (field.toLowerCase().contains('amount') ||
        field.toLowerCase().contains('rate') ||
        field.toLowerCase().contains('budget')) {
      return 'PKR 180,000';
    }
    if (field.toLowerCase().contains('date')) return 'Jul 18 - Jul 22';
    if (field.toLowerCase().contains('city')) return 'Lahore';
    return 'Verified demo ${field.toLowerCase()}';
  }
}

class _MediaGallery extends StatelessWidget {
  final RolePortalScreenSpec screen;

  const _MediaGallery({required this.screen});

  @override
  Widget build(BuildContext context) {
    final assets = RolePortalDemoData.images.take(6).toList();
    return PortalResponsiveGrid(
      minWidth: 150,
      children: assets
          .map(
            (asset) => PortalMediaFrame(
              asset: asset,
              aspectRatio: screen.mediaCategory == 'talent' ? 4 / 5 : 16 / 10,
              badge: asset.category,
              compact: true,
            ),
          )
          .toList(),
    );
  }
}

class _CalendarGrid extends StatefulWidget {
  final RolePortalScreenSpec screen;

  const _CalendarGrid({required this.screen});

  @override
  State<_CalendarGrid> createState() => _CalendarGridState();
}

class _CalendarGridState extends State<_CalendarGrid> {
  final Set<int> _selected = {3, 8, 14};

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: List.generate(21, (index) {
            final day = index + 1;
            final active = _selected.contains(day);
            return GestureDetector(
              onTap: () {
                setState(() {
                  active ? _selected.remove(day) : _selected.add(day);
                });
                showCoreSnack(context, 'Availability updated for Jul $day');
              },
              child: Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  gradient: active ? colors.goldGradient : colors.glassGradient,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: active ? colors.goldMid : colors.border,
                  ),
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: AppTextStyles.cardLabel.copyWith(
                      color: active ? colors.onGold : colors.textPrimary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 12),
        Text(
          'Selected days are held for verified CineConnect bookings.',
          style: AppTextStyles.smallMeta.copyWith(color: colors.textSecondary),
        ),
      ],
    );
  }
}

class _FinancePanel extends StatelessWidget {
  final RolePortalScreenSpec screen;

  const _FinancePanel({required this.screen});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final rows = const [
      ('Deposit', 'PKR 180k', 'Payment Pending'),
      ('Milestone', 'PKR 260k', 'Under Verification'),
      ('Final', 'PKR 320k', 'Secured Booking'),
    ];
    return Column(
      children: [
        for (final row in rows)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                gradient: colors.inactiveChipGradient,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _panelText(context, row.$1, strong: true),
                      ),
                      const SizedBox(width: 10),
                      _panelText(context, row.$2),
                    ],
                  ),
                  const SizedBox(height: 8),
                  lifecycleChip(context, label: row.$3.toUpperCase()),
                ],
              ),
            ),
          ),
        CorePrimaryButton(
          icon: Icons.receipt_long_outlined,
          label: screen.primaryAction,
          compact: true,
          onTap: () => Navigator.pushNamed(context, CoreRoutes.ledger),
        ),
      ],
    );
  }
}

class _ReportsPanel extends StatelessWidget {
  final RolePortalScreenSpec screen;

  const _ReportsPanel({required this.screen});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 140,
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(8, (index) {
              final height = 42.0 + (index % 4) * 22;
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Container(
                    height: height,
                    decoration: BoxDecoration(
                      gradient: index.isEven
                          ? colors.goldGradient
                          : LinearGradient(
                              colors: [colors.infoBlue, colors.infoPurple],
                            ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
        const SizedBox(height: 12),
        CorePrimaryButton(
          icon: Icons.file_download_outlined,
          label: screen.primaryAction,
          compact: true,
          onTap: () => showCoreSnack(context, 'Report export prepared'),
        ),
      ],
    );
  }
}

class _CompactRecordRow extends StatelessWidget {
  final PortalRecord record;

  const _CompactRecordRow({required this.record});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(record.icon, color: colors.goldDark, size: 18),
          const SizedBox(width: 8),
          Expanded(child: _panelText(context, record.title, strong: true)),
          const SizedBox(width: 8),
          Flexible(
            child: Align(
              alignment: Alignment.centerRight,
              child: lifecycleChip(context, label: record.status),
            ),
          ),
        ],
      ),
    );
  }
}

Widget _panelText(BuildContext context, String text, {bool strong = false}) {
  final colors = context.appColors;
  return Text(
    text,
    maxLines: 1,
    overflow: TextOverflow.ellipsis,
    style:
        (strong ? AppTextStyles.cardLabel : AppTextStyles.smallMeta).copyWith(
      color: strong ? colors.textPrimary : colors.textSecondary,
      fontWeight: strong ? FontWeight.w800 : FontWeight.w600,
    ),
  );
}
