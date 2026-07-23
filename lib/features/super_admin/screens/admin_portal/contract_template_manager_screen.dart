part of '../super_admin_screens.dart';

class ContractTemplateManagerScreen extends StatefulWidget {
  const ContractTemplateManagerScreen({super.key});

  @override
  State<ContractTemplateManagerScreen> createState() =>
      _ContractTemplateManagerScreenState();
}

class _ContractTemplateManagerScreenState
    extends State<ContractTemplateManagerScreen> {
  Future<List<AdminContractTemplateDto>>? _future;
  String _filter = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).contractTemplates();
  }

  void _refresh() {
    setState(
      () => _future = AdminScope.of(context).contractTemplates(force: true),
    );
  }

  Future<void> _create() async {
    final values = await _templateFormDialog(context);
    if (!mounted || values == null) return;
    try {
      final template = await AdminScope.of(context).createContractTemplate(
        name: values.$1,
        category: values.$2,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Contract template created as a draft.');
      _refresh();
      Navigator.pushNamed(
        context,
        SuperAdminRoutes.contractTemplatePath(template.publicId),
      );
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    }
  }

  Future<void> _setStatus(
    AdminContractTemplateDto template,
    String status,
  ) async {
    if (_busyId != null) return;
    setState(() => _busyId = template.publicId);
    try {
      await AdminScope.of(context).updateContractTemplate(
        template.publicId,
        status: status,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Template changed to $status.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  Future<void> _duplicate(AdminContractTemplateDto template) async {
    if (_busyId != null) return;
    setState(() => _busyId = template.publicId);
    final admin = AdminScope.of(context);
    try {
      final copy = await admin.createContractTemplate(
        name: '${template.name} Copy',
        category: template.category,
        jurisdiction: template.jurisdiction,
      );
      await admin.updateContractTemplate(
        copy.publicId,
        clauses: template.clauses,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Template duplicated as a draft.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final controls = Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminActionButton(
                    icon: Icons.add_rounded,
                    label: 'New template',
                    onTap: _create,
                  ),
                  AdminActionButton(
                    icon: Icons.refresh_rounded,
                    label: 'Refresh',
                    secondary: true,
                    onTap: _refresh,
                  ),
                ],
              );
              if (constraints.maxWidth < 640) {
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AdminFilterBar(
                      filters: const [
                        'All',
                        'draft',
                        'published',
                        'archived',
                      ],
                      selected: _filter,
                      onSelected: (value) => setState(() => _filter = value),
                    ),
                    const SizedBox(height: 12),
                    controls,
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: AdminFilterBar(
                      filters: const [
                        'All',
                        'draft',
                        'published',
                        'archived',
                      ],
                      selected: _filter,
                      onSelected: (value) => setState(() => _filter = value),
                    ),
                  ),
                  const SizedBox(width: 12),
                  controls,
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<AdminContractTemplateDto>>(
          future: _future,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const AdminSurface(
                child: Center(child: CircularProgressIndicator()),
              );
            }
            if (snapshot.hasError) {
              final error = snapshot.error;
              return AdminSurface(
                child: Column(
                  children: [
                    AdminEmptyState(
                      icon: Icons.article_outlined,
                      title: 'Could not load contract templates',
                      message: error is ApiException
                          ? error.message
                          : 'Check the backend connection and try again.',
                    ),
                    const SizedBox(height: 12),
                    AdminActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Retry',
                      secondary: true,
                      onTap: _refresh,
                    ),
                  ],
                ),
              );
            }
            final rows = (snapshot.data ?? const [])
                .where(
                  (item) => _filter == 'All' || item.status == _filter,
                )
                .toList();
            if (rows.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.article_outlined,
                title: 'No contract templates',
                message: 'Create the first governed contract template.',
              );
            }
            return Column(
              children: [
                for (final template in rows)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _TemplateControlCard(
                      template: template,
                      busy: _busyId == template.publicId,
                      onOpen: () => Navigator.pushNamed(
                        context,
                        SuperAdminRoutes.contractTemplatePath(
                          template.publicId,
                        ),
                      ),
                      onPublish: () => _setStatus(template, 'published'),
                      onArchive: () => _setStatus(template, 'archived'),
                      onDuplicate: () => _duplicate(template),
                    ),
                  ),
              ],
            );
          },
        ),
      ],
    );
  }
}

class _TemplateControlCard extends StatelessWidget {
  final AdminContractTemplateDto template;
  final bool busy;
  final VoidCallback onOpen;
  final VoidCallback onPublish;
  final VoidCallback onArchive;
  final VoidCallback onDuplicate;

  const _TemplateControlCard({
    required this.template,
    required this.busy,
    required this.onOpen,
    required this.onPublish,
    required this.onArchive,
    required this.onDuplicate,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final published = template.status == 'published';
    return AdminSurface(
      padding: EdgeInsets.zero,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: published ? colors.success : colors.goldMid,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(8),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final details = Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          template.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle.copyWith(
                            color: colors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            AdminStatusBadge(
                              label: template.status,
                              tone: published
                                  ? AdminDecisionTone.success
                                  : AdminDecisionTone.warning,
                            ),
                            AdminStatusBadge(
                              label: 'v${template.versionNumber}',
                              tone: AdminDecisionTone.info,
                            ),
                            AdminStatusBadge(
                              label: template.category,
                              tone: AdminDecisionTone.neutral,
                            ),
                            AdminStatusBadge(
                              label: '${template.clauses.length} clauses',
                              tone: AdminDecisionTone.neutral,
                            ),
                          ],
                        ),
                      ],
                    );
                    final actions = Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: [
                        _tinyAction(context, 'Open', busy ? null : onOpen),
                        _tinyAction(
                          context,
                          'Publish',
                          busy || published ? null : onPublish,
                        ),
                        _tinyAction(
                          context,
                          'Duplicate',
                          busy ? null : onDuplicate,
                        ),
                        _tinyAction(
                          context,
                          'Archive',
                          busy || template.status == 'archived'
                              ? null
                              : onArchive,
                        ),
                      ],
                    );
                    if (constraints.maxWidth < 720) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          details,
                          const SizedBox(height: 10),
                          actions,
                        ],
                      );
                    }
                    return Row(
                      children: [
                        Expanded(child: details),
                        const SizedBox(width: 12),
                        actions,
                      ],
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

Future<(String, String)?> _templateFormDialog(BuildContext context) async {
  final name = TextEditingController();
  final category = TextEditingController(text: 'general');
  final result = await showDialog<(String, String)>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('New contract template'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: name,
            autofocus: true,
            decoration: const InputDecoration(labelText: 'Template name'),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: category,
            decoration: const InputDecoration(labelText: 'Category'),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (name.text.trim().isEmpty || category.text.trim().isEmpty) {
              return;
            }
            Navigator.pop(
              context,
              (name.text.trim(), category.text.trim()),
            );
          },
          child: const Text('Create'),
        ),
      ],
    ),
  );
  name.dispose();
  category.dispose();
  return result;
}
