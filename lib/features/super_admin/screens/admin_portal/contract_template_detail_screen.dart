part of '../super_admin_screens.dart';

class ContractTemplateDetailScreen extends StatefulWidget {
  final String? templateId;

  const ContractTemplateDetailScreen({super.key, this.templateId});

  @override
  State<ContractTemplateDetailScreen> createState() =>
      _ContractTemplateDetailScreenState();
}

class _ContractTemplateDetailScreenState
    extends State<ContractTemplateDetailScreen> {
  Future<AdminContractTemplateDto>? _future;
  bool _busy = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= _load();
  }

  Future<AdminContractTemplateDto> _load({bool force = false}) async {
    final rows = await AdminScope.of(context).contractTemplates(force: force);
    final id = widget.templateId;
    if (id != null && id.isNotEmpty && id != ':id') {
      for (final item in rows) {
        if (item.publicId == id) return item;
      }
      throw const ApiException(
        code: 'admin.template_not_found',
        message: 'Contract template was not found.',
      );
    }
    if (rows.isEmpty) {
      throw const ApiException(
        code: 'admin.template_not_found',
        message: 'No contract template is available.',
      );
    }
    return rows.first;
  }

  void _refresh() {
    setState(() => _future = _load(force: true));
  }

  Future<void> _saveClauses(
    AdminContractTemplateDto template,
    List<AdminTemplateClauseDto> clauses,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
    try {
      await AdminScope.of(context).updateContractTemplate(
        template.publicId,
        clauses: clauses,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Contract clauses saved.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _addClause(AdminContractTemplateDto template) async {
    final clause = await _clauseFormDialog(context, template.clauses.length);
    if (!mounted || clause == null) return;
    await _saveClauses(template, [...template.clauses, clause]);
  }

  Future<void> _removeClause(
    AdminContractTemplateDto template,
    AdminTemplateClauseDto clause,
  ) async {
    await _saveClauses(
      template,
      template.clauses.where((item) => item != clause).toList(),
    );
  }

  Future<void> _setStatus(
    AdminContractTemplateDto template,
    String status,
  ) async {
    if (_busy) return;
    setState(() => _busy = true);
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
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<AdminContractTemplateDto>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const AdminSurface(
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          final error = snapshot.error;
          return AdminSurface(
            child: Column(
              children: [
                AdminEmptyState(
                  icon: Icons.article_outlined,
                  title: 'Template detail unavailable',
                  message: error is ApiException
                      ? error.message
                      : 'The contract template could not be loaded.',
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
        final template = snapshot.data!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AdminSurface(
              padding: EdgeInsets.zero,
              child: IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      width: 6,
                      decoration: BoxDecoration(
                        color: template.status == 'published'
                            ? context.appColors.success
                            : context.appColors.goldMid,
                        borderRadius: const BorderRadius.horizontal(
                          left: Radius.circular(8),
                        ),
                      ),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _headline(context, template.name),
                            const SizedBox(height: 9),
                            Wrap(
                              spacing: 7,
                              runSpacing: 7,
                              children: [
                                AdminStatusBadge(
                                  label: template.status,
                                  tone: template.status == 'published'
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
                                  label: template.jurisdiction,
                                  tone: AdminDecisionTone.neutral,
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 14),
            AdminSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Expanded(
                        child: AdminSectionHeader(
                          title: 'Governed clauses',
                          icon: Icons.rule_folder_outlined,
                        ),
                      ),
                      AdminActionButton(
                        icon: Icons.add_rounded,
                        label: 'Add clause',
                        secondary: true,
                        onTap: _busy ? null : () => _addClause(template),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  if (template.clauses.isEmpty)
                    const AdminEmptyState(
                      icon: Icons.rule_outlined,
                      title: 'No clauses configured',
                      message:
                          'Add the required legal and commercial controls.',
                    )
                  else
                    for (final clause in template.clauses) ...[
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 7,
                            height: 7,
                            margin: const EdgeInsets.only(top: 6),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: clause.required
                                  ? context.appColors.goldMid
                                  : context.appColors.iconMuted,
                            ),
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _text(context, clause.title, strong: true),
                                if (clause.bodyText.isNotEmpty)
                                  _text(context, clause.bodyText),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          AdminStatusBadge(
                            label: clause.required ? 'Required' : 'Optional',
                            tone: clause.required
                                ? AdminDecisionTone.warning
                                : AdminDecisionTone.neutral,
                          ),
                          AdminIconButton(
                            icon: Icons.delete_outline_rounded,
                            tooltip: 'Remove clause',
                            onTap: _busy
                                ? null
                                : () => _removeClause(template, clause),
                          ),
                        ],
                      ),
                      _reviewDivider(context),
                    ],
                ],
              ),
            ),
            const SizedBox(height: 14),
            AdminSurface(
              child: Wrap(
                spacing: 10,
                runSpacing: 10,
                children: [
                  AdminActionButton(
                    icon: Icons.publish_outlined,
                    label: 'Publish',
                    onTap: _busy || template.status == 'published'
                        ? null
                        : () => _setStatus(template, 'published'),
                  ),
                  AdminActionButton(
                    icon: Icons.archive_outlined,
                    label: 'Archive',
                    secondary: true,
                    onTap: _busy || template.status == 'archived'
                        ? null
                        : () => _setStatus(template, 'archived'),
                  ),
                  AdminActionButton(
                    icon: Icons.arrow_back_rounded,
                    label: 'All templates',
                    secondary: true,
                    onTap: () => Navigator.pushNamed(
                      context,
                      SuperAdminRoutes.contractTemplates,
                    ),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

Future<AdminTemplateClauseDto?> _clauseFormDialog(
  BuildContext context,
  int index,
) async {
  final title = TextEditingController();
  final body = TextEditingController();
  var required = true;
  final result = await showDialog<AdminTemplateClauseDto>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: const Text('Add contract clause'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: title,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Clause title'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: body,
              minLines: 3,
              maxLines: 5,
              decoration: const InputDecoration(labelText: 'Clause text'),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Required clause'),
              value: required,
              onChanged: (value) => setDialogState(() => required = value),
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
              if (title.text.trim().isEmpty) return;
              Navigator.pop(
                context,
                AdminTemplateClauseDto(
                  clauseKey: 'clause_${index + 1}',
                  title: title.text.trim(),
                  bodyText: body.text.trim(),
                  sortOrder: (index + 1) * 10,
                  required: required,
                  editable: false,
                ),
              );
            },
            child: const Text('Add'),
          ),
        ],
      ),
    ),
  );
  title.dispose();
  body.dispose();
  return result;
}
