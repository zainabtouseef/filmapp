import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../data/media_equipment_demo_data.dart';
import '../routes/media_equipment_routes.dart';
import '../widgets/media_equipment_components.dart';

class ME04PackageBuilderScreen extends StatefulWidget {
  const ME04PackageBuilderScreen({super.key});

  @override
  State<ME04PackageBuilderScreen> createState() =>
      _ME04PackageBuilderScreenState();
}

class _ME04PackageBuilderScreenState extends State<ME04PackageBuilderScreen> {
  late final TextEditingController _name;
  late final TextEditingController _price;
  late final TextEditingController _terms;
  late bool _operatorIncluded;

  @override
  void initState() {
    super.initState();
    final store = MediaEquipmentDemoStore.instance;
    _name = TextEditingController(text: store.packageDraftName);
    _price = TextEditingController(text: store.packageDraftPrice);
    _terms = TextEditingController(text: store.packageDraftTerms);
    _operatorIncluded = store.packageDraftOperatorIncluded;
  }

  @override
  void dispose() {
    _name.dispose();
    _price.dispose();
    _terms.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final store = MediaEquipmentDemoStore.instance;
    final colors = context.appColors;
    return AnimatedBuilder(
      animation: store,
      builder: (context, _) {
        final selected = store.inventory
            .where((item) => store.selectedPackageItems.contains(item.id))
            .toList();
        final operatorFee =
            store.terms.firstWhere((term) => term.id == 'operator').amount;
        final total = selected.fold<int>(0, (sum, item) => sum + item.dayRate) +
            (_operatorIncluded ? operatorFee : 0);
        return MediaTwoColumn(
          left: MediaSectionCard(
            title: 'Package builder',
            icon: Icons.inventory_2_outlined,
            selected: true,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                StepWizardIndicator(
                  currentStep: store.packageStep - 1,
                  totalSteps: 3,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    StatusChip(
                      label: 'STEP ${store.packageStep} OF 3',
                      color: colors.goldMid,
                    ),
                    StatusChip(
                      label: store.packageSubmitted ? 'PUBLISHED' : 'DRAFT',
                      color: store.packageSubmitted
                          ? colors.success
                          : colors.infoBlue,
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                _step(store),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: CoreSecondaryButton(
                        icon: Icons.arrow_back_rounded,
                        label: 'Back',
                        compact: true,
                        onTap: store.packageStep == 1
                            ? () => Navigator.pushNamed(
                                  context,
                                  MediaEquipmentRoutes.inventory,
                                )
                            : () => store.setPackageStep(store.packageStep - 1),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: CorePrimaryButton(
                        icon: store.packageStep == 3
                            ? Icons.verified_outlined
                            : Icons.arrow_forward_rounded,
                        label: store.packageStep == 3 ? 'Publish' : 'Continue',
                        compact: true,
                        onTap: () => _advance(store),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          right: MediaSectionCard(
            title: 'Live package preview',
            icon: Icons.visibility_outlined,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _name.text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  selected.map((item) => item.modelName).join(', '),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 10),
                MediaInfoRow(
                  icon: Icons.payments_outlined,
                  label: 'Suggested base',
                  value: mediaMoney(total),
                ),
                MediaInfoRow(
                  icon: Icons.engineering_outlined,
                  label: 'Operator',
                  value: _operatorIncluded ? 'Included' : 'Extra',
                ),
                MediaInfoRow(
                  icon: Icons.rule_folder_outlined,
                  label: 'Terms',
                  value: _terms.text,
                ),
                const SizedBox(height: 10),
                CoreSecondaryButton(
                  icon: Icons.save_outlined,
                  label: 'Save draft',
                  compact: true,
                  onTap: () {
                    store.savePackageDraft(
                      name: _name.text.trim(),
                      price: _price.text.trim(),
                      terms: _terms.text.trim(),
                      operatorIncluded: _operatorIncluded,
                    );
                    mediaSnack(context, 'Package draft saved');
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _step(MediaEquipmentDemoStore store) {
    return switch (store.packageStep) {
      1 => Column(
          children: [
            for (final item in store.inventory)
              Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _SelectableItemRow(
                  itemName: item.modelName,
                  serial: item.serial,
                  selected: store.selectedPackageItems.contains(item.id),
                  onTap: () => store.togglePackageItem(item.id),
                ),
              ),
          ],
        ),
      2 => Column(
          children: [
            CoreTextField(
              controller: _name,
              label: 'Package name',
              icon: Icons.inventory_2_outlined,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            CoreTextField(
              controller: _price,
              label: 'Package price',
              icon: Icons.payments_outlined,
              keyboardType: TextInputType.number,
              onChanged: (_) => setState(() {}),
            ),
            SwitchListTile.adaptive(
              dense: true,
              contentPadding: EdgeInsets.zero,
              value: _operatorIncluded,
              onChanged: (value) => setState(() => _operatorIncluded = value),
              title: const Text('Operator included'),
            ),
          ],
        ),
      _ => Column(
          children: [
            CoreTextField(
              controller: _terms,
              label: 'Package terms',
              icon: Icons.rule_folder_outlined,
              maxLines: 2,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 10),
            UploadCard(
              title: 'Package cover',
              subtitle: 'Preview image ready',
              uploaded: true,
              onTap: () => mediaSnack(context, 'Cover image refreshed'),
            ),
          ],
        ),
    };
  }

  void _advance(MediaEquipmentDemoStore store) {
    if (store.packageStep == 1) {
      if (store.selectedPackageItems.isEmpty) {
        mediaSnack(context, 'Select at least one inventory item');
        return;
      }
      store.setPackageStep(2);
      return;
    }
    if (store.packageStep == 2) {
      if (_name.text.trim().isEmpty || int.tryParse(_price.text) == null) {
        mediaSnack(context, 'Enter package name and valid price');
        return;
      }
      store.setPackageStep(3);
      return;
    }
    store.submitPackage(
      label: _name.text.trim(),
      price: int.tryParse(_price.text.trim()) ??
          store.inventory
                  .where((item) => store.selectedPackageItems.contains(item.id))
                  .fold<int>(0, (sum, item) => sum + item.dayRate) +
              (_operatorIncluded
                  ? store.terms
                      .firstWhere((term) => term.id == 'operator')
                      .amount
                  : 0),
      terms: _terms.text.trim(),
      operatorIncluded: _operatorIncluded,
    );
    showCoreSuccessDialog(
      context,
      title: 'Package published',
      message: 'The package is now available in director marketplace search.',
      buttonLabel: 'Open requests',
      onDone: () => Navigator.pushNamed(context, MediaEquipmentRoutes.requests),
    );
  }
}

class _SelectableItemRow extends StatelessWidget {
  final String itemName;
  final String serial;
  final bool selected;
  final VoidCallback onTap;

  const _SelectableItemRow({
    required this.itemName,
    required this.serial,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          gradient: selected
              ? colors.activeChipGradient
              : colors.inactiveChipGradient,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: selected ? colors.goldMid : colors.border),
        ),
        child: Row(
          children: [
            Icon(
              selected ? Icons.check_circle_outline : Icons.circle_outlined,
              color: selected ? colors.success : colors.iconMuted,
              size: 20,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    itemName,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.cardLabel.copyWith(
                      color: colors.textPrimary,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    serial,
                    style: AppTextStyles.smallMeta.copyWith(
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
