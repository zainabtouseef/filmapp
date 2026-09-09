import 'package:flutter/material.dart';

import '../../../core/auth/auth_controller.dart';
import '../../../core/bookings/booking_models.dart';
import '../../../core/bookings/bookings_controller.dart';
import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/marketplace/marketplace_models.dart';
import '../../../core/profile/profile_models.dart';
import '../../../core/projects/project_models.dart';
import '../../../core/projects/projects_controller.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../core/tour/tour_target.dart';
import '../models/brand_sponsor_models.dart';
import '../widgets/brand_demo_journey.dart';
import '../widgets/brand_sponsor_components.dart';
import '../widgets/brand_sponsor_live.dart';

class BR08BrandProjectsScreen extends StatefulWidget {
  const BR08BrandProjectsScreen({super.key});

  @override
  State<BR08BrandProjectsScreen> createState() =>
      _BR08BrandProjectsScreenState();
}

class _BR08BrandProjectsScreenState extends State<BR08BrandProjectsScreen> {
  ProjectsController? _projectsController;
  BookingsController? _bookingsController;
  AuthController? _auth;
  List<Project> _projects = const [];
  List<Booking> _bookings = const [];
  List<MarketplaceShortlist> _shortlists = const [];
  List<ProfileCity> _cities = const [];
  Project? _selected;
  String _query = '';
  String _status = 'All';
  bool _loading = false;
  bool _loaded = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final projects = ProjectsScope.maybeOf(context);
    final bookings = BookingsScope.maybeOf(context);
    final auth = AuthScope.maybeOf(context);
    if (identical(projects, _projectsController) &&
        identical(bookings, _bookingsController) &&
        identical(auth, _auth)) {
      return;
    }
    _projectsController = projects;
    _bookingsController = bookings;
    _auth = auth;
    if (projects != null) _load(force: true);
  }

  Future<void> _load({bool force = false, String? selectId}) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final values = await Future.wait<Object>([
        _projectsController!.projects(force: force),
        if (_bookingsController != null)
          _bookingsController!.bookings(force: force)
        else
          Future<List<Booking>>.value(const []),
        if (_auth != null)
          _auth!.shortlistBundle()
        else
          Future<MarketplaceShortlistBundle>.value(
            const MarketplaceShortlistBundle(
              savedSearches: [],
              shortlists: [],
            ),
          ),
        if (_auth != null)
          _auth!.cities()
        else
          Future<List<ProfileCity>>.value(const []),
      ]);
      final projects = values[0] as List<Project>;
      final bookings = values[1] as List<Booking>;
      final shortlistBundle = values[2] as MarketplaceShortlistBundle;
      final cities = values[3] as List<ProfileCity>;
      Project? selected;
      final targetId = selectId ??
          _selected?.publicId ??
          (isBrandDemoAccount(_auth)
              ? selectBrandDemoProject(projects)?.publicId
              : null);
      if (projects.isNotEmpty) {
        final summary = projects.firstWhere(
          (project) => project.publicId == targetId,
          orElse: () => projects.first,
        );
        selected = await _projectsController!.project(summary.publicId);
      }
      if (!mounted) return;
      setState(() {
        _projects = projects;
        _bookings = bookings;
        _shortlists = shortlistBundle.shortlists;
        _cities = cities;
        _selected = selected;
        _loaded = true;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<Project> get _visibleProjects {
    final query = _query.trim().toLowerCase();
    return _projects.where((project) {
      final statusMatches = _status == 'All' ||
          project.status.toLowerCase() == _status.toLowerCase();
      final queryMatches = query.isEmpty ||
          project.title.toLowerCase().contains(query) ||
          project.projectType.toLowerCase().contains(query) ||
          (project.city?.name.toLowerCase().contains(query) ?? false);
      return statusMatches && queryMatches;
    }).toList();
  }

  List<Booking> get _selectedBookings {
    final selectedId = _selected?.publicId;
    return _bookings.where((row) => row.projectId == selectedId).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_projectsController == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to manage brand projects',
        message:
            'Projects, requirements, selected resources and booking progress load from the CineConnect backend.',
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
        title: 'Projects unavailable',
        message: _error!,
        actionLabel: 'Try again',
        onAction: () => _load(force: true),
      );
    }

    final active = _projects
        .where((row) => {'active', 'paused'}.contains(row.status))
        .length;
    final confirmed = _bookings
        .where((row) => {'accepted', 'secured'}.contains(row.status))
        .length;
    final pending = _bookings
        .where((row) => {'draft', 'sent', 'viewed', 'under_negotiation'}
            .contains(row.status))
        .length;
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
        BrandResponsiveGrid(
          minWidth: 190,
          children: [
            _MetricTile(
              label: 'Active projects',
              value: '$active',
              icon: Icons.movie_creation_outlined,
            ),
            _MetricTile(
              label: 'Open requirements',
              value:
                  '${_projects.fold<int>(0, (sum, row) => sum + row.requirementCount)}',
              icon: Icons.checklist_outlined,
            ),
            _MetricTile(
              label: 'Pending requests',
              value: '$pending',
              icon: Icons.send_time_extension_outlined,
            ),
            _MetricTile(
              label: 'Confirmed bookings',
              value: '$confirmed',
              icon: Icons.verified_outlined,
            ),
          ],
        ),
        const SizedBox(height: 12),
        BrandTwoColumn(
          left: BrandSectionCard(
            title: 'Campaign projects',
            icon: Icons.workspaces_outline,
            selected: true,
            actionText: 'New project',
            onActionTap: _createProject,
            child: Column(
              children: [
                BrandSearchField(
                  hintText: 'Search project, type or city...',
                  onChanged: (value) => setState(() => _query = value),
                ),
                const SizedBox(height: 10),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final status in const [
                        'All',
                        'Draft',
                        'Active',
                        'Paused',
                        'Completed',
                        'Archived',
                      ])
                        Padding(
                          padding: const EdgeInsets.only(right: 7),
                          child: FilterChip(
                            label: Text(status),
                            selected: _status == status,
                            onSelected: (_) => setState(() => _status = status),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                if (_visibleProjects.isEmpty)
                  CoreEmptyState(
                    icon: Icons.movie_filter_outlined,
                    title: _projects.isEmpty
                        ? 'No brand projects yet'
                        : 'No matching projects',
                    message: _projects.isEmpty
                        ? 'Create a campaign project to connect talent, crew, locations and equipment.'
                        : 'Try a different search or status filter.',
                    actionLabel: _projects.isEmpty ? 'Create project' : null,
                    onAction: _projects.isEmpty ? _createProject : null,
                  )
                else
                  for (final project in _visibleProjects)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: _ProjectRow(
                        project: project,
                        selected: project.publicId == _selected?.publicId,
                        onTap: () => _selectProject(project.publicId),
                      ),
                    ),
              ],
            ),
          ),
          right: _selected == null
              ? const BrandSectionCard(
                  title: 'Project builder',
                  icon: Icons.account_tree_outlined,
                  child: CoreEmptyState(
                    icon: Icons.add_business_outlined,
                    title: 'Select a project',
                    message:
                        'Open a project to manage its production requirements and connected bookings.',
                  ),
                )
              : TourTarget(
                  id: 'brand:demo:project-brief',
                  child: TourTarget(
                    id: 'brand:demo:requirements',
                    child: _ProjectDetail(
                      project: _selected!,
                      bookings: _selectedBookings,
                      shortlists: _shortlists
                          .where(
                            (board) => board.projectId == _selected!.publicId,
                          )
                          .toList(),
                      busy: _loading,
                      onEdit: () => _editProject(_selected!),
                      onAddRequirement: _addRequirement,
                      onStatus: (status) => _setStatus(_selected!, status),
                      onDuplicate: () => _duplicate(_selected!),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  Future<void> _selectProject(String publicId) async {
    setState(() => _loading = true);
    try {
      final project = await _projectsController!.project(publicId);
      if (mounted) setState(() => _selected = project);
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _createProject() async {
    final draft = await _showProjectDialog(context, cities: _cities);
    if (draft == null || !mounted) return;
    setState(() => _loading = true);
    try {
      final project = await _projectsController!.createProject(
        title: draft.title,
        projectType: draft.type,
        description: draft.description,
        cityId: draft.cityId.isEmpty ? null : draft.cityId,
        startDate: draft.startDate,
        endDate: draft.endDate,
        estimatedBudgetMinor: draft.budgetMinor,
        status: draft.status,
      );
      await _load(force: true, selectId: project.publicId);
      if (mounted) brandSnack(context, 'Project saved to the backend');
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _editProject(Project project) async {
    final draft = await _showProjectDialog(
      context,
      cities: _cities,
      existing: project,
    );
    if (draft == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await _projectsController!.updateProject(
        projectId: project.publicId,
        title: draft.title,
        projectType: draft.type,
        description: draft.description,
        cityId: draft.cityId.isEmpty ? null : draft.cityId,
        startDate: draft.startDate,
        endDate: draft.endDate,
        estimatedBudgetMinor: draft.budgetMinor,
      );
      await _load(force: true, selectId: project.publicId);
      if (mounted) brandSnack(context, 'Project details updated');
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _addRequirement() async {
    final project = _selected;
    if (project == null) return;
    final draft = await _showRequirementDialog(context);
    if (draft == null || !mounted) return;
    setState(() => _loading = true);
    try {
      await _projectsController!.createRequirement(
        projectId: project.publicId,
        category: draft.category,
        title: draft.title,
        summary: draft.summary,
        budgetMaxMinor: draft.budgetMinor,
        startDate: project.startDate?.toIso8601String().split('T').first,
        endDate: project.endDate?.toIso8601String().split('T').first,
        quantity: draft.quantity,
      );
      await _load(force: true, selectId: project.publicId);
      if (mounted) brandSnack(context, 'Requirement added to the project');
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _setStatus(Project project, String status) async {
    setState(() => _loading = true);
    try {
      await _projectsController!.updateProject(
        projectId: project.publicId,
        status: status,
        progressPercent: switch (status) {
          'active' =>
            project.progressPercent == 0 ? 10 : project.progressPercent,
          'completed' => 100,
          _ => project.progressPercent,
        },
      );
      await _load(force: true, selectId: project.publicId);
      if (mounted) {
        brandSnack(context, 'Project marked ${readableBrandStatus(status)}');
      }
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _duplicate(Project project) async {
    setState(() => _loading = true);
    try {
      final duplicate =
          await _projectsController!.duplicateProject(project.publicId);
      await _load(force: true, selectId: duplicate.publicId);
      if (mounted) brandSnack(context, 'Project duplicated as a draft');
    } catch (error) {
      if (mounted) setState(() => _error = brandApiMessage(error));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }
}

class _MetricTile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;

  const _MetricTile({
    required this.label,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return BrandSectionCard(
      title: label,
      icon: icon,
      child: Text(
        value,
        style: AppTextStyles.heroSerifNumber.copyWith(
          color: context.appColors.textPrimary,
          fontSize: 28,
        ),
      ),
    );
  }
}

class _ProjectRow extends StatelessWidget {
  final Project project;
  final bool selected;
  final VoidCallback onTap;

  const _ProjectRow({
    required this.project,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Material(
      color: selected
          ? colors.goldMid.withValues(alpha: 0.11)
          : colors.softSurface,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Icon(Icons.movie_creation_outlined, color: colors.goldDark),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      project.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.cardLabel.copyWith(
                        color: colors.textPrimary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '${readableBrandStatus(project.projectType)} · ${project.requirementCount} requirements',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              BrandLiveStatusChip(status: project.status),
            ],
          ),
        ),
      ),
    );
  }
}

class _ProjectDetail extends StatelessWidget {
  final Project project;
  final List<Booking> bookings;
  final List<MarketplaceShortlist> shortlists;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onAddRequirement;
  final ValueChanged<String> onStatus;
  final VoidCallback onDuplicate;

  const _ProjectDetail({
    required this.project,
    required this.bookings,
    required this.shortlists,
    required this.busy,
    required this.onEdit,
    required this.onAddRequirement,
    required this.onStatus,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final confirmed = bookings
        .where((row) => {'accepted', 'secured'}.contains(row.status))
        .length;
    final selectedResources = shortlists
        .expand((board) => board.items)
        .where((item) => item.status == 'selected')
        .toList();
    final candidateCount = shortlists.fold<int>(
      0,
      (total, board) => total + board.items.length,
    );
    return BrandSectionCard(
      title: project.title,
      icon: Icons.account_tree_outlined,
      tone: BrandTone.blue,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 7,
            runSpacing: 7,
            children: [
              BrandLiveStatusChip(status: project.status),
              Chip(label: Text('${project.progressPercent}% complete')),
              Chip(label: Text('$confirmed confirmed')),
              Chip(label: Text('$candidateCount shortlisted')),
            ],
          ),
          const SizedBox(height: 10),
          BrandInfoRow(
            icon: Icons.category_outlined,
            label: 'Project type',
            value: readableBrandStatus(project.projectType),
          ),
          BrandInfoRow(
            icon: Icons.location_city_outlined,
            label: 'City',
            value: project.city?.name ?? 'Not set',
          ),
          BrandInfoRow(
            icon: Icons.event_outlined,
            label: 'Shoot dates',
            value:
                '${_shortDate(project.startDate)} – ${_shortDate(project.endDate)}',
          ),
          BrandInfoRow(
            icon: Icons.payments_outlined,
            label: 'Working budget',
            value: brandMoney(
              project.estimatedBudgetMinor,
              currency: project.currency,
            ),
          ),
          if (project.description?.isNotEmpty == true) ...[
            const SizedBox(height: 4),
            Text(
              project.description!,
              maxLines: 4,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: context.appColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
          const SizedBox(height: 14),
          Row(
            children: [
              Text(
                'Production requirements',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: busy ? null : onAddRequirement,
                icon: const Icon(Icons.add_rounded),
                label: const Text('Add'),
              ),
            ],
          ),
          if (project.requirements.isEmpty)
            const Text('No requirements added yet.')
          else
            for (final requirement in project.requirements)
              ListTile(
                dense: true,
                contentPadding: EdgeInsets.zero,
                leading: Icon(
                  _categoryIcon(requirement.category),
                  color: context.appColors.goldDark,
                ),
                title: Text(requirement.title),
                subtitle: Text(
                  '${requirement.displayCategory} · qty ${requirement.quantity}',
                ),
                trailing: BrandLiveStatusChip(status: requirement.status),
              ),
          const SizedBox(height: 12),
          Text(
            'Attached production resources',
            style: AppTextStyles.cardLabel.copyWith(
              color: context.appColors.textPrimary,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          if (candidateCount == 0)
            const Text(
              'No resources shortlisted yet. Use Discover to build the production team.',
            )
          else
            for (final board in shortlists)
              for (final item in board.items)
                ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: Icon(
                    _categoryIcon(item.listing.listingType),
                    color: context.appColors.goldDark,
                  ),
                  title: Text(item.listing.title),
                  subtitle: Text(
                    '${readableBrandStatus(item.listing.listingType)} · ${item.listing.cityName}',
                  ),
                  trailing: BrandLiveStatusChip(status: item.status),
                ),
          if (selectedResources.isNotEmpty) ...[
            const SizedBox(height: 4),
            InlineNotice(
              message:
                  '${selectedResources.length} production resource${selectedResources.length == 1 ? '' : 's'} selected for this project.',
              icon: Icons.groups_2_outlined,
              tone: CoreStatusTone.success,
            ),
          ],
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              OutlinedButton.icon(
                onPressed: busy ? null : onEdit,
                icon: const Icon(Icons.edit_outlined),
                label: const Text('Edit'),
              ),
              FilledButton.icon(
                onPressed: busy || project.status == 'active'
                    ? null
                    : () => onStatus('active'),
                icon: const Icon(Icons.publish_outlined),
                label: const Text('Publish'),
              ),
              OutlinedButton.icon(
                onPressed: busy ? null : onDuplicate,
                icon: const Icon(Icons.copy_outlined),
                label: const Text('Duplicate'),
              ),
              OutlinedButton.icon(
                onPressed: busy || project.status == 'archived'
                    ? null
                    : () => onStatus('archived'),
                icon: const Icon(Icons.archive_outlined),
                label: const Text('Archive'),
              ),
              TextButton.icon(
                onPressed: busy || project.status == 'cancelled'
                    ? null
                    : () => onStatus('cancelled'),
                icon: const Icon(Icons.cancel_outlined),
                label: const Text('Cancel'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

typedef _ProjectDraft = ({
  String title,
  String type,
  String description,
  String cityId,
  String? startDate,
  String? endDate,
  int? budgetMinor,
  String status,
});

Future<_ProjectDraft?> _showProjectDialog(
  BuildContext context, {
  required List<ProfileCity> cities,
  Project? existing,
}) async {
  final title = TextEditingController(text: existing?.title ?? '');
  final description = TextEditingController(text: existing?.description ?? '');
  final start = TextEditingController(text: _dateInput(existing?.startDate));
  final end = TextEditingController(text: _dateInput(existing?.endDate));
  final budget = TextEditingController(
    text: existing?.estimatedBudgetMinor == null
        ? ''
        : '${existing!.estimatedBudgetMinor! ~/ 100}',
  );
  var type = existing?.projectType ?? 'tvc';
  var cityId = existing?.city?.publicId ?? '';
  if (cityId.isNotEmpty && !cities.any((city) => city.publicId == cityId)) {
    cityId = '';
  }
  var status = existing?.status ?? 'draft';
  String? error;
  final result = await showDialog<_ProjectDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text(existing == null
            ? 'Create campaign project'
            : 'Edit campaign project'),
        content: SizedBox(
          width: 560,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CoreTextField(
                  controller: title,
                  label: 'Project or campaign name',
                  icon: Icons.movie_creation_outlined,
                ),
                const SizedBox(height: 10),
                CoreDropdownField<String>(
                  value: type,
                  values: const [
                    'tvc',
                    'digital_advertisement',
                    'social_media_campaign',
                    'product_shoot',
                    'fashion_shoot',
                    'brand_film',
                    'promotional_video',
                    'corporate_film',
                    'music_video',
                    'other',
                  ],
                  label: 'Project type',
                  icon: Icons.category_outlined,
                  labelBuilder: readableBrandStatus,
                  onChanged: (value) => setState(() => type = value ?? type),
                ),
                const SizedBox(height: 10),
                CoreDropdownField<String>(
                  value: cityId,
                  values: ['', ...cities.map((city) => city.publicId)],
                  label: 'Production city',
                  icon: Icons.location_city_outlined,
                  labelBuilder: (value) {
                    if (value.isEmpty) return 'Not set';
                    return cities
                        .firstWhere((city) => city.publicId == value)
                        .name;
                  },
                  onChanged: (value) =>
                      setState(() => cityId = value ?? cityId),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: description,
                  label: 'Description and production requirements',
                  icon: Icons.notes_outlined,
                  maxLines: 4,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CoreTextField(
                        controller: start,
                        label: 'Start (YYYY-MM-DD)',
                        icon: Icons.event_outlined,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CoreTextField(
                        controller: end,
                        label: 'End (YYYY-MM-DD)',
                        icon: Icons.event_available_outlined,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: budget,
                  label: 'Expected budget (PKR)',
                  icon: Icons.payments_outlined,
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 10),
                if (existing == null)
                  CoreDropdownField<String>(
                    value: status,
                    values: const ['draft', 'active'],
                    label: 'Save mode',
                    icon: Icons.save_outlined,
                    labelBuilder: (value) =>
                        value == 'draft' ? 'Save draft' : 'Publish now',
                    onChanged: (value) =>
                        setState(() => status = value ?? status),
                  ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  InlineNotice(
                    message: error!,
                    icon: Icons.error_outline_rounded,
                    tone: CoreStatusTone.danger,
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsedStart = start.text.trim().isEmpty
                  ? null
                  : DateTime.tryParse(start.text.trim());
              final parsedEnd = end.text.trim().isEmpty
                  ? null
                  : DateTime.tryParse(end.text.trim());
              final wholeBudget = budget.text.trim().isEmpty
                  ? null
                  : int.tryParse(budget.text.trim().replaceAll(',', ''));
              if (title.text.trim().length < 2) {
                setState(() => error = 'Enter a project name.');
                return;
              }
              if (description.text.trim().length < 10) {
                setState(() => error = 'Add a useful project description.');
                return;
              }
              if ((start.text.trim().isNotEmpty && parsedStart == null) ||
                  (end.text.trim().isNotEmpty && parsedEnd == null)) {
                setState(() => error = 'Use YYYY-MM-DD for project dates.');
                return;
              }
              if (parsedStart != null &&
                  parsedEnd != null &&
                  parsedEnd.isBefore(parsedStart)) {
                setState(() => error = 'End date cannot be before start date.');
                return;
              }
              if (budget.text.trim().isNotEmpty &&
                  (wholeBudget == null || wholeBudget < 0)) {
                setState(() => error = 'Enter a valid budget.');
                return;
              }
              Navigator.pop(dialogContext, (
                title: title.text.trim(),
                type: type,
                description: description.text.trim(),
                cityId: cityId,
                startDate: start.text.trim().isEmpty ? null : start.text.trim(),
                endDate: end.text.trim().isEmpty ? null : end.text.trim(),
                budgetMinor: wholeBudget == null ? null : wholeBudget * 100,
                status: status,
              ));
            },
            child: Text(existing != null
                ? 'Save changes'
                : status == 'draft'
                    ? 'Save draft'
                    : 'Publish'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  description.dispose();
  start.dispose();
  end.dispose();
  budget.dispose();
  return result;
}

String _dateInput(DateTime? value) =>
    value == null ? '' : value.toIso8601String().split('T').first;

typedef _RequirementDraft = ({
  String category,
  String title,
  String summary,
  int quantity,
  int? budgetMinor,
});

Future<_RequirementDraft?> _showRequirementDialog(BuildContext context) async {
  final title = TextEditingController();
  final summary = TextEditingController();
  final quantity = TextEditingController(text: '1');
  final budget = TextEditingController();
  var category = 'talent';
  String? error;
  final result = await showDialog<_RequirementDraft>(
    context: context,
    builder: (dialogContext) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: const Text('Add production requirement'),
        content: SizedBox(
          width: 520,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CoreDropdownField<String>(
                  value: category,
                  values: const [
                    'talent',
                    'model',
                    'crew',
                    'location',
                    'equipment',
                  ],
                  label: 'Resource category',
                  icon: Icons.category_outlined,
                  labelBuilder: readableBrandStatus,
                  onChanged: (value) =>
                      setState(() => category = value ?? category),
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: title,
                  label: 'Requirement title',
                  icon: Icons.title_outlined,
                ),
                const SizedBox(height: 10),
                CoreTextField(
                  controller: summary,
                  label: 'Skills, specifications or facilities',
                  icon: Icons.notes_outlined,
                  maxLines: 3,
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: CoreTextField(
                        controller: quantity,
                        label: 'Quantity',
                        icon: Icons.numbers_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CoreTextField(
                        controller: budget,
                        label: 'Max budget (PKR)',
                        icon: Icons.payments_outlined,
                        keyboardType: TextInputType.number,
                      ),
                    ),
                  ],
                ),
                if (error != null) ...[
                  const SizedBox(height: 10),
                  Text(error!,
                      style: TextStyle(color: context.appColors.danger)),
                ],
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsedQuantity = int.tryParse(quantity.text.trim());
              final wholeBudget = budget.text.trim().isEmpty
                  ? null
                  : int.tryParse(budget.text.trim().replaceAll(',', ''));
              if (title.text.trim().length < 2) {
                setState(() => error = 'Enter a requirement title.');
                return;
              }
              if (parsedQuantity == null || parsedQuantity < 1) {
                setState(() => error = 'Quantity must be at least 1.');
                return;
              }
              if (budget.text.trim().isNotEmpty &&
                  (wholeBudget == null || wholeBudget < 0)) {
                setState(() => error = 'Enter a valid maximum budget.');
                return;
              }
              Navigator.pop(dialogContext, (
                category: category,
                title: title.text.trim(),
                summary: summary.text.trim(),
                quantity: parsedQuantity,
                budgetMinor: wholeBudget == null ? null : wholeBudget * 100,
              ));
            },
            child: const Text('Add requirement'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  summary.dispose();
  quantity.dispose();
  budget.dispose();
  return result;
}

String _shortDate(DateTime? value) {
  if (value == null) return 'Not set';
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}

IconData _categoryIcon(String category) {
  return switch (category) {
    'talent' => Icons.theater_comedy_outlined,
    'model' => Icons.accessibility_new_outlined,
    'crew' || 'service' => Icons.groups_outlined,
    'location' => Icons.location_on_outlined,
    'equipment' => Icons.videocam_outlined,
    _ => Icons.checklist_outlined,
  };
}
