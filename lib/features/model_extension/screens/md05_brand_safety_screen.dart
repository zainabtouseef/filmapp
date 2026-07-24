import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/specialist/specialist_controller.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';

class MD05BrandSafetyScreen extends StatefulWidget {
  const MD05BrandSafetyScreen({super.key});

  @override
  State<MD05BrandSafetyScreen> createState() => _MD05BrandSafetyScreenState();
}

class _MD05BrandSafetyScreenState extends State<MD05BrandSafetyScreen> {
  SpecialistController? _specialist;
  Future<_SafetyData>? _future;
  List<_RestrictionDraft> _restricted = const [];
  bool _saving = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final specialist = SpecialistScope.maybeOf(context);
    if (specialist == null || identical(specialist, _specialist)) return;
    _specialist = specialist;
    _future = _load(specialist);
  }

  Future<_SafetyData> _load(SpecialistController specialist) async {
    final profile = await specialist.modelProfile(force: true);
    final restricted = await specialist.modelRestrictedCategories(force: true);
    return _SafetyData(profile: profile, restricted: restricted);
  }

  @override
  Widget build(BuildContext context) {
    final future = _future;
    if (future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to load brand safety',
        message:
            'Model visibility, private safety notes and restricted categories are fetched from the backend.',
      );
    }
    return FutureBuilder<_SafetyData>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(32),
              child: CircularProgressIndicator(),
            ),
          );
        }
        if (snapshot.hasError) {
          return CoreEmptyState(
            icon: Icons.cloud_off_outlined,
            title: 'Brand safety unavailable',
            message: 'Could not load live brand safety preferences.',
            actionLabel: 'Try again',
            onAction: _reload,
          );
        }
        final data = snapshot.data!;
        if (_restricted.isEmpty) {
          _restricted = _draftsFor(data.restricted);
        }
        final blocked = _restricted.where((item) => item.blocked).toList();
        return Column(
          children: [
            ActorSectionCard(
              title: 'Offer Screening',
              icon: Icons.shield_outlined,
              selected: blocked.isNotEmpty,
              child: Column(
                children: [
                  _ModelSafetySwitch(
                    label: 'Public model discovery',
                    subtitle: data.profile?.publicVisibility == true
                        ? 'Directors can discover this model extension.'
                        : 'The model extension is hidden from discovery.',
                    value: data.profile?.publicVisibility ?? false,
                    onChanged: _updateVisibility,
                  ),
                  ActorInfoRow(
                    icon: Icons.notes_outlined,
                    label: 'Safety notes',
                    value: data.profile?.brandSafetyNotes?.trim().isNotEmpty ==
                            true
                        ? data.profile!.brandSafetyNotes!
                        : 'No private review notes added',
                  ),
                  const SizedBox(height: 8),
                  CoreSecondaryButton(
                    icon: Icons.edit_note_outlined,
                    label: 'Edit safety notes',
                    compact: true,
                    onTap: () => _showNotes(data.profile),
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      StatusChip(
                        label: '${blocked.length} blocked',
                        color: context.appColors.danger,
                      ),
                      StatusChip(
                        label: 'Backend restrictions',
                        color: context.appColors.infoBlue,
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Restricted Categories',
              icon: Icons.block_rounded,
              actionText: _saving ? 'Saving...' : 'Save',
              onActionTap: _saving ? null : _saveRestrictions,
              child: Column(
                children: [
                  InlineNotice(
                    message:
                        'Live brand safety connected: ${blocked.length}/${_restricted.length} restricted.',
                    icon: Icons.cloud_done_outlined,
                    tone: CoreStatusTone.success,
                  ),
                  const SizedBox(height: 10),
                  for (final category in _restricted)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _RestrictedRow(
                        item: category,
                        onChanged: () => _toggleRestricted(category.id),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            ActorSectionCard(
              title: 'Offer Flagging Rules',
              icon: Icons.flag_outlined,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    blocked.isEmpty
                        ? 'No categories are currently blocked, so offers are not pre-filtered by model brand-safety preference.'
                        : 'Offers tagged ${blocked.map((item) => item.label).join(", ")} should be reviewed before reaching the opportunity inbox.',
                    style: AppTextStyles.body.copyWith(
                      color: context.appColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                  const SizedBox(height: 12),
                  CorePrimaryButton(
                    icon: Icons.save_outlined,
                    label: _saving ? 'Saving...' : 'Save live restrictions',
                    compact: true,
                    onTap: _saving ? null : _saveRestrictions,
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  List<_RestrictionDraft> _draftsFor(
    List<ModelRestrictedCategoryDto> restricted,
  ) {
    final existing = {
      for (final item in restricted) _normalize(item.category): item,
    };
    return _restrictionConfigs.map((config) {
      final live = existing[_normalize(config.label)];
      return _RestrictionDraft(
        id: config.id,
        label: config.label,
        blocked: live?.blocked ?? false,
      );
    }).toList();
  }

  void _toggleRestricted(String id) {
    setState(() {
      _restricted = _restricted.map((item) {
        if (item.id != id) return item;
        return item.copyWith(blocked: !item.blocked);
      }).toList();
    });
  }

  Future<void> _saveRestrictions() async {
    final specialist = _specialist;
    if (specialist == null) {
      actorSnack(context, 'Sign in to save brand safety restrictions');
      return;
    }
    setState(() => _saving = true);
    try {
      await specialist.updateModelRestrictedCategories(
        _restricted
            .map(
              (item) => {
                'category': item.label,
                'blocked': item.blocked,
                'reason': item.blocked ? 'Model preference' : null,
              },
            )
            .toList(),
      );
      if (!mounted) return;
      actorSnack(context, 'Live restrictions saved');
      _reload();
    } catch (error) {
      if (mounted) actorSnack(context, 'Could not save restrictions: $error');
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _updateVisibility(bool value) async {
    final specialist = _specialist;
    if (specialist == null) return;
    try {
      await specialist.upsertModelProfile({'public_visibility': value});
      if (!mounted) return;
      actorSnack(
        context,
        value ? 'Model discovery enabled' : 'Model discovery hidden',
      );
      _reload();
    } catch (error) {
      if (mounted) actorSnack(context, 'Could not update visibility: $error');
    }
  }

  void _showNotes(ModelProfileDto? profile) {
    final pageContext = context;
    final notes = TextEditingController(text: profile?.brandSafetyNotes ?? '');
    showActorSheet(
      context,
      title: 'Private brand safety notes',
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: notes,
            label: 'Review guidance',
            icon: Icons.shield_outlined,
            maxLines: 4,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.save_outlined,
            label: 'Save notes',
            onTap: () async {
              final specialist = _specialist;
              if (specialist == null) return;
              try {
                await specialist.upsertModelProfile({
                  'brand_safety_notes': notes.text.trim(),
                });
                if (!mounted || !context.mounted) return;
                Navigator.pop(context);
                actorSnack(pageContext, 'Brand safety notes saved');
                _reload();
              } catch (error) {
                if (context.mounted) {
                  actorSnack(context, 'Could not save notes: $error');
                }
              }
            },
          ),
        ],
      ),
    ).whenComplete(notes.dispose);
  }

  void _reload() {
    final specialist = _specialist;
    if (specialist == null) return;
    setState(() {
      _restricted = const [];
      _future = _load(specialist);
    });
  }
}

class _ModelSafetySwitch extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ModelSafetySwitch({
    required this.label,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTextStyles.cardLabel.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                    height: 1.25,
                  ),
                ),
              ],
            ),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RestrictedRow extends StatelessWidget {
  final _RestrictionDraft item;
  final VoidCallback onChanged;

  const _RestrictedRow({
    required this.item,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: item.blocked ? colors.danger : colors.border),
      ),
      child: Row(
        children: [
          Icon(
            item.blocked ? Icons.block_rounded : Icons.check_circle_outline,
            color: item.blocked ? colors.danger : colors.success,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              item.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.cardLabel.copyWith(
                color: colors.textPrimary,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          Switch(value: item.blocked, onChanged: (_) => onChanged()),
        ],
      ),
    );
  }
}

class _SafetyData {
  final ModelProfileDto? profile;
  final List<ModelRestrictedCategoryDto> restricted;

  const _SafetyData({
    required this.profile,
    required this.restricted,
  });
}

class _RestrictionDraft {
  final String id;
  final String label;
  final bool blocked;

  const _RestrictionDraft({
    required this.id,
    required this.label,
    required this.blocked,
  });

  _RestrictionDraft copyWith({bool? blocked}) {
    return _RestrictionDraft(
      id: id,
      label: label,
      blocked: blocked ?? this.blocked,
    );
  }
}

typedef _RestrictionConfig = ({String id, String label});

const _restrictionConfigs = <_RestrictionConfig>[
  (id: 'tobacco', label: 'Tobacco'),
  (id: 'political', label: 'Political'),
  (id: 'adult', label: 'Adult content'),
  (id: 'gambling', label: 'Gambling'),
  (id: 'crypto', label: 'Crypto ads'),
  (id: 'skin_lightening', label: 'Skin-lightening products'),
  (id: 'weapons', label: 'Weapons'),
  (id: 'alcohol', label: 'Alcohol'),
];

String _normalize(String value) =>
    value.toLowerCase().replaceAll(RegExp(r'[^a-z0-9]+'), '');
