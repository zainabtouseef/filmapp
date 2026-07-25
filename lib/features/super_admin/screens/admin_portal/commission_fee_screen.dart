part of '../super_admin_screens.dart';

class CommissionFeeScreen extends StatefulWidget {
  const CommissionFeeScreen({super.key});

  @override
  State<CommissionFeeScreen> createState() => _CommissionFeeScreenState();
}

class _CommissionFeeScreenState extends State<CommissionFeeScreen> {
  Future<List<AdminFeeRuleDto>>? _future;
  String _filter = 'All';
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _future ??= AdminScope.of(context).feeRules();
  }

  void _refresh() {
    setState(() => _future = AdminScope.of(context).feeRules(force: true));
  }

  Future<void> _create() async {
    final value = await _feeRuleDialog(context);
    if (!mounted || value == null) return;
    try {
      await AdminScope.of(context).createFeeRule(
        name: value.$1,
        category: value.$2,
        basisPoints: value.$3,
        fixedMinor: value.$4,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Fee rule created.');
      _refresh();
    } on ApiException catch (error) {
      if (mounted) showCoreSnack(context, error.message);
    }
  }

  Future<void> _edit(AdminFeeRuleDto item) async {
    final value = await _feeRuleDialog(context, existing: item);
    if (!mounted || value == null) return;
    await _update(
      item,
      name: value.$1,
      category: value.$2,
      basisPoints: value.$3,
      fixedMinor: value.$4,
    );
  }

  Future<void> _update(
    AdminFeeRuleDto item, {
    String? name,
    String? category,
    int? basisPoints,
    int? fixedMinor,
    bool? active,
  }) async {
    if (_busyId != null) return;
    setState(() => _busyId = item.publicId);
    try {
      await AdminScope.of(context).updateFeeRule(
        item.publicId,
        name: name,
        category: category,
        basisPoints: basisPoints,
        fixedMinor: fixedMinor,
        active: active,
      );
      if (!mounted) return;
      showCoreSnack(context, 'Fee rule updated.');
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
          child: Column(
            children: [
              AdminFilterBar(
                filters: const ['All', 'Active', 'Inactive'],
                selected: _filter,
                onSelected: (value) => setState(() => _filter = value),
              ),
              const SizedBox(height: 12),
              Align(
                alignment: Alignment.centerRight,
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    AdminActionButton(
                      icon: Icons.add_rounded,
                      label: 'New fee rule',
                      onTap: _create,
                    ),
                    AdminActionButton(
                      icon: Icons.refresh_rounded,
                      label: 'Refresh',
                      secondary: true,
                      onTap: _refresh,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        FutureBuilder<List<AdminFeeRuleDto>>(
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
                      icon: Icons.percent_rounded,
                      title: 'Could not load fee rules',
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
            final rows = (snapshot.data ?? const []).where((item) {
              return switch (_filter) {
                'Active' => item.active,
                'Inactive' => !item.active,
                _ => true,
              };
            }).toList();
            if (rows.isEmpty) {
              return const AdminEmptyState(
                icon: Icons.percent_rounded,
                title: 'No fee rules',
                message: 'Create the first platform commission rule.',
              );
            }
            return AdminSurface(
              padding: const EdgeInsets.all(12),
              child: Column(
                children: [
                  for (var index = 0; index < rows.length; index++) ...[
                    if (index > 0) _reviewDivider(context),
                    _LiveFeeRuleRow(
                      item: rows[index],
                      busy: _busyId == rows[index].publicId,
                      onEdit: () => _edit(rows[index]),
                      onToggle: (value) => _update(rows[index], active: value),
                    ),
                  ],
                ],
              ),
            );
          },
        ),
      ],
    );
  }
}

class _LiveFeeRuleRow extends StatelessWidget {
  final AdminFeeRuleDto item;
  final bool busy;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;

  const _LiveFeeRuleRow({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final percentage = '${(item.basisPoints / 100).toStringAsFixed(2)}%';
    final fixed = item.fixedMinor == 0
        ? 'No fixed charge'
        : '${item.currency} ${(item.fixedMinor / 100).toStringAsFixed(0)} fixed';
    return Container(
      decoration: BoxDecoration(
        border: Border(
          left: BorderSide(
            width: 4,
            color: item.active ? colors.goldMid : colors.iconMuted,
          ),
        ),
      ),
      padding: const EdgeInsets.fromLTRB(12, 8, 4, 8),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final details = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.cardTitle.copyWith(
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${item.category} · $fixed',
                style: AppTextStyles.caption.copyWith(
                  color: colors.textSecondary,
                ),
              ),
            ],
          );
          final controls = Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              AdminStatusBadge(
                label: percentage,
                tone: AdminDecisionTone.warning,
              ),
              const SizedBox(width: 6),
              AdminIconButton(
                icon: Icons.edit_outlined,
                tooltip: 'Edit fee rule',
                onTap: busy ? null : onEdit,
              ),
              Switch(
                value: item.active,
                onChanged: busy ? null : onToggle,
                activeThumbColor: colors.goldDark,
              ),
            ],
          );
          if (constraints.maxWidth < 560) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                details,
                const SizedBox(height: 8),
                controls,
              ],
            );
          }
          return Row(
            children: [
              Expanded(child: details),
              const SizedBox(width: 12),
              controls,
            ],
          );
        },
      ),
    );
  }
}

// Matches the marketplace listing categories used elsewhere (marketplace.py
// `supported_listing_types`), plus `general` for a platform-wide default
// rule and `crew` for crew/service bookings — a fixed list so fee rules
// stay consistent instead of accumulating typo'd/duplicate category names.
const _feeCategories = [
  'general',
  'talent',
  'model',
  'location',
  'equipment',
  'crew',
  'agency',
  'distribution',
];

Future<(String, String, int, int)?> _feeRuleDialog(
  BuildContext context, {
  AdminFeeRuleDto? existing,
}) async {
  final name = TextEditingController(text: existing?.name);
  var category = existing?.category ?? 'general';
  final categoryOptions = [
    ..._feeCategories,
    if (existing != null && !_feeCategories.contains(existing.category))
      existing.category,
  ];
  final percentage = TextEditingController(
    text: existing == null
        ? '5.00'
        : (existing.basisPoints / 100).toStringAsFixed(2),
  );
  final fixed = TextEditingController(
    text:
        existing == null ? '0' : (existing.fixedMinor / 100).toStringAsFixed(0),
  );
  final result = await showDialog<(String, String, int, int)>(
    context: context,
    builder: (context) => StatefulBuilder(
      builder: (context, setDialogState) => AlertDialog(
        title: Text(existing == null ? 'New fee rule' : 'Edit fee rule'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: name,
                autofocus: true,
                decoration: const InputDecoration(labelText: 'Rule name'),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                initialValue: category,
                decoration: const InputDecoration(labelText: 'Category'),
                items: [
                  for (final option in categoryOptions)
                    DropdownMenuItem(value: option, child: Text(option)),
                ],
                onChanged: (value) {
                  if (value == null) return;
                  setDialogState(() => category = value);
                },
              ),
              const SizedBox(height: 10),
              TextField(
                controller: percentage,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(labelText: 'Commission %'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: fixed,
                keyboardType: TextInputType.number,
                decoration:
                    const InputDecoration(labelText: 'Fixed charge (PKR)'),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final percent = double.tryParse(percentage.text.trim());
              final fixedValue = int.tryParse(fixed.text.trim());
              if (name.text.trim().isEmpty ||
                  percent == null ||
                  percent < 0 ||
                  fixedValue == null ||
                  fixedValue < 0) {
                return;
              }
              Navigator.pop(
                context,
                (
                  name.text.trim(),
                  category,
                  (percent * 100).round(),
                  fixedValue * 100,
                ),
              );
            },
            child: const Text('Save'),
          ),
        ],
      ),
    ),
  );
  name.dispose();
  percentage.dispose();
  fixed.dispose();
  return result;
}
