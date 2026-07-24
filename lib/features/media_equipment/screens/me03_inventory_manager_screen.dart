import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/media_equipment_components.dart';

class ME03InventoryManagerScreen extends StatefulWidget {
  const ME03InventoryManagerScreen({super.key});

  @override
  State<ME03InventoryManagerScreen> createState() =>
      _ME03InventoryManagerScreenState();
}

class _ME03InventoryManagerScreenState
    extends State<ME03InventoryManagerScreen> {
  String _query = '';
  String _filter = 'All';
  String _sort = 'Category';
  Future<List<EquipmentItemDto>>? _itemsFuture;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_itemsFuture != null) return;
    final operations = OperationsScope.maybeOf(context);
    _itemsFuture = operations?.equipmentItems(force: true);
  }

  void _reload() {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    _itemsFuture = operations.equipmentItems(force: true);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaSectionCard(
          title: 'Inventory Command',
          icon: Icons.videocam_outlined,
          selected: true,
          child: Column(
            children: [
              _SearchField(
                onChanged: (value) => setState(() => _query = value),
              ),
              const SizedBox(height: 10),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final filter in const [
                      'All',
                      'Camera',
                      'Lens',
                      'Lighting',
                      'Drone',
                      'Audio',
                      'Grip',
                    ])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label: filter,
                          selected: _filter == filter,
                          onTap: () => setState(() => _filter = filter),
                        ),
                      ),
                    const SizedBox(width: 8),
                    for (final sort in const ['Category', 'Rate'])
                      Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: CoreChip(
                          label: sort,
                          icon: Icons.sort_rounded,
                          selected: _sort == sort,
                          onTap: () => setState(() => _sort = sort),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_itemsFuture == null)
          const CoreEmptyState(
            icon: Icons.lock_outline_rounded,
            title: 'Sign in to manage live inventory',
            message:
                'Equipment inventory is loaded from the backend database after authentication.',
          )
        else
          FutureBuilder<List<EquipmentItemDto>>(
            future: _itemsFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const MediaSectionCard(
                  title: 'Live Inventory',
                  icon: Icons.cloud_sync_outlined,
                  child: InlineNotice(
                    message: 'Loading equipment inventory...',
                    icon: Icons.hourglass_top_rounded,
                  ),
                );
              }
              if (snapshot.hasError) {
                return MediaSectionCard(
                  title: 'Live Inventory',
                  icon: Icons.cloud_off_outlined,
                  child: Column(
                    children: [
                      const CoreEmptyState(
                        icon: Icons.cloud_off_outlined,
                        title: 'Could not load live inventory',
                        message:
                            'No static preview items are shown. Retry the database-backed inventory request.',
                      ),
                      const SizedBox(height: 10),
                      CoreSecondaryButton(
                        icon: Icons.refresh_rounded,
                        label: 'Retry',
                        onTap: () => setState(_reload),
                      ),
                    ],
                  ),
                );
              }
              final rows = _filtered(snapshot.data ?? const []);
              if (rows.isEmpty) {
                return CoreEmptyState(
                  icon: Icons.video_library_outlined,
                  title: 'No matching inventory',
                  message: snapshot.data?.isEmpty == true
                      ? 'Add the first rentable camera, lens, light, audio, grip, or drone asset.'
                      : 'Change search or category filters.',
                  actionLabel: snapshot.data?.isEmpty == true
                      ? 'Add inventory item'
                      : null,
                  onAction: snapshot.data?.isEmpty == true
                      ? () => _showEditor()
                      : null,
                );
              }
              return MediaResponsiveGrid(
                minWidth: 300,
                children: [
                  for (final item in rows)
                    _LiveInventoryCard(
                      item: item,
                      busy: _busyId == item.publicId,
                      onEdit: () => _showEditor(item),
                      onStatus: () => _toggleStatus(item),
                    ),
                ],
              );
            },
          ),
        const SizedBox(height: 12),
        CorePrimaryButton(
          icon: Icons.add_box_outlined,
          label: 'Add inventory item',
          compact: true,
          onTap: _showEditor,
        ),
      ],
    );
  }

  List<EquipmentItemDto> _filtered(List<EquipmentItemDto> values) {
    final query = _query.trim().toLowerCase();
    final rows = values.where((item) {
      final category = item.category.toLowerCase();
      final filterMatch = _filter == 'All' ||
          category == _filter.toLowerCase() ||
          (_filter == 'Lighting' && category == 'light');
      final searchMatch = query.isEmpty ||
          '${item.category} ${item.brand} ${item.modelName} ${item.condition}'
              .toLowerCase()
              .contains(query);
      return filterMatch && searchMatch;
    }).toList();
    if (_sort == 'Rate') {
      rows.sort((a, b) => b.dayRateMinor.compareTo(a.dayRateMinor));
    } else {
      rows.sort((a, b) {
        final category = a.category.compareTo(b.category);
        return category == 0 ? a.modelName.compareTo(b.modelName) : category;
      });
    }
    return rows;
  }

  Future<void> _toggleStatus(EquipmentItemDto item) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    final next = item.status == 'available' ? 'maintenance' : 'available';
    setState(() => _busyId = item.publicId);
    try {
      await operations.updateEquipmentItem(item.publicId, {'status': next});
      if (!mounted) return;
      setState(_reload);
      mediaSnack(
        context,
        next == 'available'
            ? '${item.modelName} is available'
            : '${item.modelName} moved to maintenance',
      );
    } catch (error) {
      if (mounted) mediaSnack(context, 'Could not update item: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showEditor([EquipmentItemDto? item]) {
    final category = TextEditingController(text: item?.category ?? 'Camera');
    final brand = TextEditingController(text: item?.brand ?? '');
    final model = TextEditingController(text: item?.modelName ?? '');
    final serial = TextEditingController();
    final condition =
        TextEditingController(text: item?.condition ?? 'excellent');
    final rate = TextEditingController(
      text: item == null ? '' : '${item.dayRateMinor ~/ 100}',
    );
    final deposit = TextEditingController(
      text: item == null ? '' : '${item.depositMinor ~/ 100}',
    );
    var status = item?.status ?? 'available';
    showMediaSheet(
      context,
      title: item == null ? 'Add inventory item' : 'Edit inventory item',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CoreTextField(
                controller: category,
                label: 'Category',
                icon: Icons.category_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: brand,
                label: 'Brand',
                icon: Icons.sell_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: model,
                label: 'Model / kit name',
                icon: Icons.videocam_outlined,
              ),
              if (item == null) ...[
                const SizedBox(height: 10),
                CoreTextField(
                  controller: serial,
                  label: 'Serial number (private)',
                  icon: Icons.qr_code_rounded,
                ),
              ],
              const SizedBox(height: 10),
              CoreTextField(
                controller: condition,
                label: 'Condition',
                icon: Icons.fact_check_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: rate,
                label: 'Day rate in PKR',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: deposit,
                label: 'Security deposit in PKR',
                icon: Icons.account_balance_wallet_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final value in const [
                    'available',
                    'reserved',
                    'maintenance',
                  ])
                    CoreChip(
                      label: _title(value),
                      selected: status == value,
                      onTap: () => setSheetState(() => status = value),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              CorePrimaryButton(
                icon: item == null ? Icons.add_rounded : Icons.save_outlined,
                label: item == null ? 'Add item' : 'Save item',
                onTap: () async {
                  final dayRate = int.tryParse(rate.text.trim());
                  final depositAmount = int.tryParse(deposit.text.trim());
                  if (category.text.trim().isEmpty ||
                      model.text.trim().length < 2 ||
                      dayRate == null ||
                      dayRate <= 0 ||
                      depositAmount == null ||
                      depositAmount < 0) {
                    mediaSnack(context, 'Complete model, rates, and condition');
                    return;
                  }
                  final operations = OperationsScope.maybeOf(context);
                  if (operations == null) {
                    Navigator.pop(context);
                    mediaSnack(
                      this.context,
                      'Sign in to manage backend inventory.',
                    );
                    return;
                  }
                  final body = <String, dynamic>{
                    'category': category.text.trim(),
                    'brand': brand.text.trim(),
                    'model_name': model.text.trim(),
                    if (item == null) 'serial': serial.text.trim(),
                    'condition': condition.text.trim(),
                    'day_rate_minor': dayRate * 100,
                    'deposit_minor': depositAmount * 100,
                    'currency': 'PKR',
                    'status': status,
                  };
                  try {
                    if (item == null) {
                      await operations.createEquipmentItem(body);
                    } else {
                      await operations.updateEquipmentItem(item.publicId, body);
                    }
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    mediaSnack(
                      this.context,
                      item == null
                          ? 'Inventory item published'
                          : 'Inventory item updated',
                    );
                  } catch (error) {
                    if (context.mounted) {
                      mediaSnack(context, 'Could not save item: $error');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      category.dispose();
      brand.dispose();
      model.dispose();
      serial.dispose();
      condition.dispose();
      rate.dispose();
      deposit.dispose();
    });
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return TextField(
      onChanged: onChanged,
      decoration: const InputDecoration(
        prefixIcon: Icon(Icons.search_rounded),
        hintText: 'Search model, category, brand, condition...',
      ),
    );
  }
}

class _LiveInventoryCard extends StatelessWidget {
  final EquipmentItemDto item;
  final bool busy;
  final VoidCallback onEdit;
  final VoidCallback onStatus;

  const _LiveInventoryCard({
    required this.item,
    required this.busy,
    required this.onEdit,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final available = item.status == 'available';
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 112,
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.softSurface,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: colors.border),
            ),
            child: Icon(
              _categoryIcon(item.category),
              color: colors.goldDark,
              size: 42,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: Text(
                  item.modelName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: _title(item.status),
                color: available
                    ? colors.success
                    : item.status == 'maintenance'
                        ? colors.danger
                        : colors.goldMid,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            '${item.brand.isEmpty ? item.category : item.brand} · ${_title(item.condition)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: '${mediaMoney(item.dayRateMinor ~/ 100)}/day',
                color: colors.goldMid,
              ),
              StatusChip(
                label: '${mediaMoney(item.depositMinor ~/ 100)} deposit',
                color: colors.infoBlue,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.edit_outlined,
                  label: 'Edit',
                  compact: true,
                  onTap: busy ? null : onEdit,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: available
                      ? Icons.build_outlined
                      : Icons.check_circle_outline,
                  label: available ? 'Service' : 'Available',
                  compact: true,
                  onTap: busy ? null : onStatus,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

IconData _categoryIcon(String category) {
  return switch (category.toLowerCase()) {
    'lens' => Icons.camera_outlined,
    'light' || 'lighting' => Icons.lightbulb_outline,
    'audio' => Icons.mic_none_outlined,
    'drone' => Icons.flight_outlined,
    'grip' => Icons.handyman_outlined,
    _ => Icons.videocam_outlined,
  };
}

String _title(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
