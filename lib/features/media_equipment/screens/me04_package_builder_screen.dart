import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/glass_section_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../widgets/media_equipment_components.dart';

class ME04PackageBuilderScreen extends StatefulWidget {
  const ME04PackageBuilderScreen({super.key});

  @override
  State<ME04PackageBuilderScreen> createState() =>
      _ME04PackageBuilderScreenState();
}

class _ME04PackageBuilderScreenState extends State<ME04PackageBuilderScreen> {
  Future<_PackageData>? _dataFuture;
  String? _busyId;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_dataFuture != null) return;
    _reload();
  }

  void _reload() {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    _dataFuture = _load(operations);
  }

  Future<_PackageData> _load(OperationsController operations) async {
    final values = await Future.wait([
      operations.equipmentItems(force: true),
      operations.equipmentPackages(force: true),
    ]);
    return _PackageData(
      items: values[0] as List<EquipmentItemDto>,
      packages: values[1] as List<EquipmentPackageDto>,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MediaSectionCard(
          title: 'Package Strategy',
          icon: Icons.inventory_2_outlined,
          selected: true,
          child: const MediaResponsiveGrid(
            minWidth: 220,
            children: [
              MediaInfoRow(
                icon: Icons.video_library_outlined,
                label: 'Bundle',
                value: 'Choose live inventory assets',
              ),
              MediaInfoRow(
                icon: Icons.engineering_outlined,
                label: 'Crew',
                value: 'Set operator inclusion clearly',
              ),
              MediaInfoRow(
                icon: Icons.rule_folder_outlined,
                label: 'Contract',
                value: 'Package terms flow into booking',
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_dataFuture == null)
          const InlineNotice(
            message: 'Preview mode. Sign in to manage rental packages.',
            icon: Icons.visibility_outlined,
          )
        else
          FutureBuilder<_PackageData>(
            future: _dataFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const InlineNotice(
                  message: 'Loading inventory and packages...',
                  icon: Icons.hourglass_top_rounded,
                );
              }
              if (snapshot.hasError) {
                return InlineNotice(
                  message: 'Could not load packages: ${snapshot.error}',
                  icon: Icons.cloud_off_outlined,
                );
              }
              final data = snapshot.data!;
              return MediaTwoColumn(
                left: MediaSectionCard(
                  title: 'Published Packages',
                  icon: Icons.widgets_outlined,
                  child: data.packages.isEmpty
                      ? CoreEmptyState(
                          icon: Icons.inventory_2_outlined,
                          title: 'No rental packages',
                          message:
                              'Bundle compatible equipment with an operator option and clear terms.',
                          actionLabel: 'Create package',
                          onAction: data.items.isEmpty
                              ? null
                              : () => _showBuilder(data),
                        )
                      : Column(
                          children: [
                            for (final package in data.packages)
                              Padding(
                                padding: const EdgeInsets.only(bottom: 10),
                                child: _PackageCard(
                                  package: package,
                                  busy: _busyId == package.publicId,
                                  onStatus: () => _toggleStatus(package),
                                ),
                              ),
                          ],
                        ),
                ),
                right: MediaSectionCard(
                  title: 'Build a Package',
                  icon: Icons.add_box_outlined,
                  selected: true,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      MediaInfoRow(
                        icon: Icons.inventory_outlined,
                        label: 'Available inventory',
                        value:
                            '${data.items.where((item) => item.status == 'available').length} assets',
                      ),
                      MediaInfoRow(
                        icon: Icons.layers_outlined,
                        label: 'Existing packages',
                        value: '${data.packages.length} bundles',
                      ),
                      const SizedBox(height: 10),
                      if (data.items.isEmpty)
                        const InlineNotice(
                          message:
                              'Add inventory before creating a rental package.',
                          icon: Icons.info_outline,
                        )
                      else
                        CorePrimaryButton(
                          icon: Icons.add_rounded,
                          label: 'Create rental package',
                          compact: true,
                          onTap: () => _showBuilder(data),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
      ],
    );
  }

  Future<void> _toggleStatus(EquipmentPackageDto package) async {
    final operations = OperationsScope.maybeOf(context);
    if (operations == null) return;
    final next = package.status == 'published' ? 'draft' : 'published';
    setState(() => _busyId = package.publicId);
    try {
      await operations.updateEquipmentPackage(
        package.publicId,
        {'status': next},
      );
      if (!mounted) return;
      setState(_reload);
      mediaSnack(
        context,
        next == 'published' ? 'Package published' : 'Package moved to draft',
      );
    } catch (error) {
      if (mounted) mediaSnack(context, 'Could not update package: $error');
    } finally {
      if (mounted) setState(() => _busyId = null);
    }
  }

  void _showBuilder(_PackageData data) {
    final name = TextEditingController();
    final description = TextEditingController();
    final price = TextEditingController();
    final terms = TextEditingController(
      text: '10-hour rental day. Overtime and transport billed separately.',
    );
    final selected = <String>{};
    var operatorIncluded = false;
    var publish = true;
    showMediaSheet(
      context,
      title: 'Create rental package',
      child: StatefulBuilder(
        builder: (context, setSheetState) {
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CoreTextField(
                controller: name,
                label: 'Package name',
                icon: Icons.inventory_2_outlined,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: description,
                label: 'Producer-facing description',
                icon: Icons.notes_outlined,
                maxLines: 2,
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: price,
                label: 'Package day price in PKR',
                icon: Icons.payments_outlined,
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 12),
              Text(
                'Included inventory',
                style: AppTextStyles.cardLabel.copyWith(
                  color: context.appColors.textPrimary,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 8),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 240),
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: data.items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final item = data.items[index];
                    final enabled = item.status == 'available';
                    return CheckboxListTile(
                      contentPadding: EdgeInsets.zero,
                      dense: true,
                      title: Text(item.modelName),
                      subtitle: Text(
                        '${item.category} · ${mediaMoney(item.dayRateMinor ~/ 100)}/day',
                      ),
                      value: selected.contains(item.publicId),
                      onChanged: enabled
                          ? (value) => setSheetState(() {
                                if (value == true) {
                                  selected.add(item.publicId);
                                } else {
                                  selected.remove(item.publicId);
                                }
                              })
                          : null,
                    );
                  },
                ),
              ),
              const SizedBox(height: 10),
              CoreTextField(
                controller: terms,
                label: 'Package terms',
                icon: Icons.rule_folder_outlined,
                maxLines: 3,
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Operator included'),
                value: operatorIncluded,
                onChanged: (value) =>
                    setSheetState(() => operatorIncluded = value),
              ),
              SwitchListTile.adaptive(
                contentPadding: EdgeInsets.zero,
                title: const Text('Publish immediately'),
                value: publish,
                onChanged: (value) => setSheetState(() => publish = value),
              ),
              const SizedBox(height: 10),
              CorePrimaryButton(
                icon: publish ? Icons.publish_outlined : Icons.save_outlined,
                label: publish ? 'Publish package' : 'Save draft',
                onTap: () async {
                  final amount = int.tryParse(price.text.trim());
                  if (name.text.trim().length < 2 ||
                      amount == null ||
                      amount <= 0 ||
                      selected.isEmpty) {
                    mediaSnack(
                      context,
                      'Enter package name, price, and included inventory',
                    );
                    return;
                  }
                  final operations = OperationsScope.maybeOf(context);
                  if (operations == null) return;
                  try {
                    final package = await operations.createEquipmentPackage({
                      'name': name.text.trim(),
                      'description': description.text.trim(),
                      'operator_included': operatorIncluded,
                      'price_minor': amount * 100,
                      'currency': 'PKR',
                      'terms': terms.text.trim(),
                      'status': publish ? 'published' : 'draft',
                    });
                    for (final itemId in selected) {
                      await operations.addEquipmentPackageItem(
                        package.publicId,
                        itemId,
                      );
                    }
                    if (!mounted || !context.mounted) return;
                    Navigator.pop(context);
                    setState(_reload);
                    mediaSnack(this.context, 'Rental package saved');
                  } catch (error) {
                    if (context.mounted) {
                      mediaSnack(context, 'Could not save package: $error');
                    }
                  }
                },
              ),
            ],
          );
        },
      ),
    ).whenComplete(() {
      name.dispose();
      description.dispose();
      price.dispose();
      terms.dispose();
    });
  }
}

class _PackageCard extends StatelessWidget {
  final EquipmentPackageDto package;
  final bool busy;
  final VoidCallback onStatus;

  const _PackageCard({
    required this.package,
    required this.busy,
    required this.onStatus,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final published = package.status == 'published';
    return GlassSectionCard(
      radius: 8,
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.inventory_2_outlined, color: colors.goldDark),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  package.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              StatusChip(
                label: package.status.toUpperCase(),
                color: published ? colors.success : colors.infoBlue,
              ),
            ],
          ),
          if (package.description.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              package.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.smallMeta.copyWith(
                color: colors.textSecondary,
              ),
            ),
          ],
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              StatusChip(
                label: mediaMoney(package.priceMinor ~/ 100),
                color: colors.goldMid,
              ),
              StatusChip(
                label: '${package.items.length} item(s)',
                color: colors.infoBlue,
              ),
              if (package.operatorIncluded)
                StatusChip(label: 'Operator', color: colors.infoPurple),
            ],
          ),
          const SizedBox(height: 10),
          CoreSecondaryButton(
            icon: published
                ? Icons.visibility_off_outlined
                : Icons.publish_outlined,
            label: published ? 'Move to draft' : 'Publish',
            compact: true,
            onTap: busy ? null : onStatus,
          ),
        ],
      ),
    );
  }
}

class _PackageData {
  final List<EquipmentItemDto> items;
  final List<EquipmentPackageDto> packages;

  const _PackageData({
    required this.items,
    required this.packages,
  });
}
