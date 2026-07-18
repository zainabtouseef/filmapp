import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../models/media_equipment_models.dart';
import '../routes/media_equipment_routes.dart';
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
  String _sort = 'Category';
  Future<List<EquipmentItemDto>>? _itemsFuture;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    _itemsFuture ??= operations?.equipmentItems(force: true);
  }

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final rows = _filteredItems(store).toList();
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            MediaSectionCard(
              title: 'Inventory command',
              icon: Icons.videocam_outlined,
              selected: true,
              child: Column(
                children: [
                  if (_itemsFuture != null)
                    FutureBuilder<List<EquipmentItemDto>>(
                      future: _itemsFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const Padding(
                            padding: EdgeInsets.only(bottom: 10),
                            child: InlineNotice(
                              message: 'Loading live equipment inventory...',
                              icon: Icons.hourglass_top_rounded,
                            ),
                          );
                        }
                        final rows = snapshot.data ?? const [];
                        if (rows.isEmpty) return const SizedBox.shrink();
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: InlineNotice(
                            message:
                                'Live inventory connected: ${rows.length} item(s), latest ${rows.first.modelName}.',
                            icon: Icons.cloud_done_outlined,
                            tone: CoreStatusTone.success,
                          ),
                        );
                      },
                    ),
                  _SearchField(
                      onChanged: (value) => setState(() => _query = value)),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final filter in [
                          'All',
                          'Camera',
                          'Lens',
                          'Light',
                          'Drone',
                          'Audio',
                        ])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: filter,
                              selected: store.inventoryFilter == filter,
                              onTap: () => store.setInventoryFilter(filter),
                            ),
                          ),
                        const SizedBox(width: 8),
                        for (final sort in ['Category', 'Rate'])
                          Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: CoreChip(
                              label: sort,
                              selected: _sort == sort,
                              icon: Icons.sort_rounded,
                              onTap: () {
                                setState(() => _sort = sort);
                                mediaSnack(context, '$sort sorting applied');
                              },
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (rows.isEmpty)
              CoreEmptyState(
                icon: Icons.search_off_rounded,
                title: 'No matching inventory',
                message: 'Clear search or filters to show available equipment.',
                actionLabel: 'Add demo item',
                onAction: store.addDemoInventoryItem,
              )
            else
              MediaResponsiveGrid(
                minWidth: 310,
                children: [
                  for (final item in rows)
                    _InventoryCard(
                      item: item,
                      onOpen: () => _showDetail(context, item),
                      onAvailability: () {
                        store.toggleInventoryAvailability(item.id);
                        mediaSnack(
                            context, '${item.modelName} availability updated');
                      },
                    ),
                ],
              ),
            const SizedBox(height: 12),
            CorePrimaryButton(
              icon: Icons.add_box_outlined,
              label: 'Add inventory item',
              compact: true,
              onTap: () async {
                final operations = OperationsScope.maybeOf(context);
                if (operations != null) {
                  try {
                    await operations.createEquipmentItem({
                      'category': 'Camera',
                      'brand': 'Sony',
                      'model_name':
                          'FX6 Smoke Kit ${DateTime.now().millisecondsSinceEpoch % 1000}',
                      'serial_number': 'serial-tokenized',
                      'condition': 'excellent',
                      'day_rate_minor': 4500000,
                      'deposit_minor': 15000000,
                      'currency': 'PKR',
                      'status': 'available',
                    });
                    if (mounted) {
                      setState(() => _itemsFuture =
                          operations.equipmentItems(force: true));
                    }
                  } catch (error) {
                    if (context.mounted) {
                      mediaSnack(
                          context, 'Live inventory save skipped: $error');
                    }
                  }
                }
                final added = store.addDemoInventoryItem();
                if (!context.mounted) return;
                mediaSnack(
                  context,
                  added
                      ? 'Demo monitor added to inventory'
                      : 'Demo monitor already in inventory',
                );
              },
            ),
          ],
        );
      },
    );
  }

  Iterable<MediaInventoryItem> _filteredItems(MediaEquipmentDemoStore store) {
    final lower = _query.trim().toLowerCase();
    var result = store.inventory.where((item) {
      final filterMatch = store.inventoryFilter == 'All' ||
          item.category == store.inventoryFilter;
      final haystack =
          '${item.category} ${item.modelName} ${item.serial} ${item.city}'
              .toLowerCase();
      return filterMatch && haystack.contains(lower);
    }).toList();
    if (_sort == 'Rate') {
      result.sort((a, b) => b.dayRate.compareTo(a.dayRate));
    } else {
      result.sort((a, b) => a.category.compareTo(b.category));
    }
    return result;
  }

  void _showDetail(BuildContext context, MediaInventoryItem item) {
    showMediaSheet(
      context,
      title: item.modelName,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          MediaInfoRow(
            icon: Icons.confirmation_number_outlined,
            label: 'Serial number',
            value: item.serial,
          ),
          MediaInfoRow(
            icon: Icons.payments_outlined,
            label: 'Day rate',
            value: mediaMoney(item.dayRate),
          ),
          MediaInfoRow(
            icon: Icons.verified_user_outlined,
            label: 'Deposit',
            value: mediaMoney(item.deposit),
          ),
          const SizedBox(height: 8),
          CorePrimaryButton(
            icon: Icons.inventory_2_outlined,
            label: 'Use in package',
            onTap: () {
              Navigator.pop(context);
              Navigator.pushNamed(context, MediaEquipmentRoutes.packages);
            },
          ),
        ],
      ),
    );
  }
}

class _SearchField extends StatelessWidget {
  final ValueChanged<String> onChanged;

  const _SearchField({required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return TextField(
      onChanged: onChanged,
      style: AppTextStyles.body.copyWith(color: colors.textPrimary),
      decoration: InputDecoration(
        isDense: true,
        hintText: 'Search model, serial, city...',
        hintStyle: AppTextStyles.smallMeta.copyWith(
          color: colors.textSecondary,
        ),
        prefixIcon:
            Icon(Icons.search_rounded, color: colors.goldDark, size: 20),
        filled: true,
        fillColor:
            colors.surface.withValues(alpha: colors.isLight ? 0.74 : 0.36),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: colors.goldMid),
        ),
      ),
    );
  }
}

class _InventoryCard extends StatelessWidget {
  final MediaInventoryItem item;
  final VoidCallback onOpen;
  final VoidCallback onAvailability;

  const _InventoryCard({
    required this.item,
    required this.onOpen,
    required this.onAvailability,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GlassSectionCard(
      radius: 20,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          MediaFrame(
            imageUrl: item.imageUrl,
            title: item.modelName,
            badge: item.serial,
            fallbackIcon: Icons.videocam_outlined,
            aspectRatio: 16 / 9,
            compact: true,
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
                label: item.available ? 'READY' : 'BOOKED',
                color: item.available ? colors.success : colors.goldMid,
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            '${item.category} - ${item.condition} - ${mediaMoney(item.dayRate)}',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.smallMeta.copyWith(
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: CoreSecondaryButton(
                  icon: Icons.info_outline_rounded,
                  label: 'Details',
                  compact: true,
                  onTap: onOpen,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: CorePrimaryButton(
                  icon: Icons.published_with_changes_outlined,
                  label: 'Toggle',
                  compact: true,
                  onTap: onAvailability,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
