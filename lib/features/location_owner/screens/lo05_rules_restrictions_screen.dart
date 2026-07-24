import 'package:flutter/material.dart';

import '../../../core/core_ui/widgets/core_widgets.dart';
import '../../../core/operations/operations_controller.dart';
import '../../../core/operations/operations_models.dart';
import '../../../core/theme/app_color_scheme.dart';
import '../../../core/theme/app_text_styles.dart';
import '../../../shared/cards/metric_action_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';
import '../widgets/location_owner_components.dart';
import '../widgets/location_owner_live.dart';

class LO05RulesRestrictionsScreen extends StatefulWidget {
  const LO05RulesRestrictionsScreen({super.key});

  @override
  State<LO05RulesRestrictionsScreen> createState() =>
      _LO05RulesRestrictionsScreenState();
}

class _LO05RulesRestrictionsScreenState
    extends State<LO05RulesRestrictionsScreen> {
  OperationsController? _operations;
  Future<List<LocationPropertyDto>>? _future;
  LocationPropertyDto? _property;
  List<_RuleDraft> _rules = const [];
  bool _saving = false;
  String? _error;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final operations = OperationsScope.maybeOf(context);
    if (operations == null || identical(operations, _operations)) return;
    _operations = operations;
    _future = _load();
  }

  Future<List<LocationPropertyDto>> _load({bool force = false}) async {
    final properties = await _operations!.locationProperties(force: force);
    final property = activeLocationProperty(properties);
    if (mounted) {
      setState(() {
        _property = property;
        _rules = _draftsFor(property);
      });
    }
    return properties;
  }

  List<_RuleDraft> _draftsFor(LocationPropertyDto? property) {
    if (property == null) return const [];
    final existing = {
      for (final rule in property.rules) rule.ruleType: rule,
    };
    return [
      _draft(
        existing['smoking'],
        'smoking',
        'Smoking',
        'Outdoor only with cleanup and written approval.',
        false,
        Icons.smoke_free_outlined,
      ),
      _draft(
        existing['animals'],
        'animals',
        'Animals',
        'Trained animals require advance notice and supervision.',
        true,
        Icons.pets_outlined,
      ),
      _draft(
        existing['noise'],
        'noise',
        'Amplified sound',
        'No amplified sound after the agreed quiet-hour cutoff.',
        false,
        Icons.volume_up_outlined,
      ),
      _draft(
        existing['equipment'],
        'equipment',
        'Heavy equipment',
        'Floor protection and an approved load plan are required.',
        true,
        Icons.construction_outlined,
      ),
      _draft(
        existing['food'],
        'food',
        'Kitchen and catering',
        'Cooking and catering areas must be confirmed before arrival.',
        true,
        Icons.kitchen_outlined,
      ),
      _draft(
        existing['access'],
        'access',
        'Restricted rooms',
        'Private rooms remain locked unless included in the booking.',
        false,
        Icons.meeting_room_outlined,
      ),
      _draft(
        existing['exterior'],
        'exterior',
        'Roof and exterior access',
        'Safety controls are required for elevated exterior areas.',
        true,
        Icons.roofing_outlined,
      ),
      _draft(
        existing['crew'],
        'crew',
        'Crew capacity',
        'Cast, crew, vendors and visitors count toward capacity.',
        true,
        Icons.groups_2_outlined,
      ),
    ];
  }

  _RuleDraft _draft(
    LocationRuleDto? value,
    String type,
    String label,
    String note,
    bool allowed,
    IconData icon,
  ) {
    return _RuleDraft(
      publicId: value?.publicId,
      ruleType: type,
      label: value?.label ?? label,
      note: value?.note.isNotEmpty == true ? value!.note : note,
      allowed: value?.allowed ?? allowed,
      icon: icon,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_future == null) {
      return const CoreEmptyState(
        icon: Icons.cloud_sync_outlined,
        title: 'Sign in to manage rules',
        message:
            'Property rules and restrictions are loaded from backend property records.',
      );
    }
    return FutureBuilder<List<LocationPropertyDto>>(
      future: _future,
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
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
            title: 'Rules unavailable',
            message: locationApiMessage(snapshot.error!),
            actionLabel: 'Try again',
            onAction: () => setState(() => _future = _load(force: true)),
          );
        }
        if (_property == null) {
          return CoreEmptyState(
            icon: Icons.add_location_alt_outlined,
            title: 'Create a property first',
            message: 'Rules are stored against a specific property.',
            actionLabel: 'Create property',
            onAction: () => Navigator.pushNamed(
              context,
              LocationOwnerRoutes.listing,
            ),
          );
        }
        return _buildRules();
      },
    );
  }

  Widget _buildRules() {
    final colors = context.appColors;
    final allowed = _rules.where((rule) => rule.allowed).length;
    final restricted = _rules.length - allowed;
    final saved =
        _rules.where((rule) => rule.publicId?.isNotEmpty == true).length;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        MetricActionRail(
          items: [
            MetricActionItem(
              value: '$allowed',
              icon: Icons.check_circle_outline,
              title: 'Allowed',
              subtitle: 'Current draft',
              accentColor: colors.success,
            ),
            MetricActionItem(
              value: '$restricted',
              icon: Icons.block_rounded,
              title: 'Restricted',
              subtitle: 'Current draft',
              accentColor: colors.goldMid,
            ),
            MetricActionItem(
              value: '$saved/${_rules.length}',
              icon: Icons.cloud_done_outlined,
              title: 'Saved rules',
              subtitle: 'Live property data',
              accentColor: colors.infoBlue,
            ),
          ],
        ),
        const SizedBox(height: 12),
        LocationTwoColumn(
          left: LocationSectionCard(
            title: 'Rules and restrictions',
            icon: Icons.rule_folder_outlined,
            selected: true,
            child: Column(
              children: [
                for (var index = 0; index < _rules.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _RuleRow(
                      rule: _rules[index],
                      onChanged: (value) => _setAllowed(index, value),
                      onEdit: () => _editRule(index),
                    ),
                  ),
                if (_error != null) ...[
                  InlineNotice(
                    icon: Icons.error_outline_rounded,
                    message: 'Could not save rules: $_error',
                    tone: CoreStatusTone.danger,
                  ),
                  const SizedBox(height: 10),
                ],
                CorePrimaryButton(
                  icon: Icons.save_outlined,
                  label: _saving ? 'Saving...' : 'Save property rules',
                  compact: true,
                  onTap: _saving ? null : _saveRules,
                ),
              ],
            ),
          ),
          right: Column(
            children: [
              LocationSectionCard(
                title: 'Where rules apply',
                icon: Icons.policy_outlined,
                tone: LocationTone.blue,
                child: Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.public_outlined,
                      label: 'Property profile',
                      value: 'Public summary',
                    ),
                    LocationInfoRow(
                      icon: Icons.request_quote_outlined,
                      label: 'Offer review',
                      value: 'Confirm exceptions',
                    ),
                    LocationInfoRow(
                      icon: Icons.fact_check_outlined,
                      label: 'Check-in',
                      value: 'Condition record',
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Rules saved here describe the property. Any exception must be written into the booking offer before acceptance.',
                      style: AppTextStyles.smallMeta.copyWith(
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              LocationSectionCard(
                title: 'Owner checklist',
                icon: Icons.checklist_outlined,
                tone: LocationTone.green,
                child: const Column(
                  children: [
                    LocationInfoRow(
                      icon: Icons.groups_2_outlined,
                      label: 'Crew limit',
                      value: 'State total occupancy',
                    ),
                    LocationInfoRow(
                      icon: Icons.schedule_outlined,
                      label: 'Quiet hours',
                      value: 'Set a clear cutoff',
                    ),
                    LocationInfoRow(
                      icon: Icons.security_outlined,
                      label: 'Restricted areas',
                      value: 'Name excluded rooms',
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _setAllowed(int index, bool value) {
    final updated = List<_RuleDraft>.of(_rules);
    updated[index] = updated[index].copyWith(allowed: value);
    setState(() => _rules = updated);
  }

  void _editRule(int index) {
    final rule = _rules[index];
    final note = TextEditingController(text: rule.note);
    showLocationSheet(
      context,
      title: rule.label,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          CoreTextField(
            controller: note,
            label: 'Rule details',
            icon: Icons.edit_note_outlined,
            maxLines: 3,
          ),
          const SizedBox(height: 12),
          CorePrimaryButton(
            icon: Icons.check_rounded,
            label: 'Update draft',
            onTap: () {
              final value = note.text.trim();
              if (value.length < 3) {
                locationSnack(context, 'Add a clear rule description');
                return;
              }
              final updated = List<_RuleDraft>.of(_rules);
              updated[index] = rule.copyWith(note: value);
              setState(() => _rules = updated);
              Navigator.pop(context);
            },
          ),
        ],
      ),
    ).whenComplete(note.dispose);
  }

  Future<void> _saveRules() async {
    final operations = _operations;
    final property = _property;
    if (operations == null || property == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      for (final rule in _rules) {
        final body = {
          'rule_type': rule.ruleType,
          'label': rule.label,
          'note': rule.note,
          'allowed': rule.allowed,
        };
        if (rule.publicId == null) {
          await operations.createLocationRule(
            property.publicId,
            body,
            refresh: false,
          );
        } else {
          await operations.updateLocationRule(
            rule.publicId!,
            body,
            refresh: false,
          );
        }
      }
      final properties = await operations.locationProperties(force: true);
      final active = activeLocationProperty(properties);
      if (!mounted) return;
      setState(() {
        _property = active;
        _rules = _draftsFor(active);
      });
      locationSnack(context, 'Property rules saved');
    } catch (error) {
      if (!mounted) return;
      setState(() => _error = locationApiMessage(error));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }
}

class _RuleRow extends StatelessWidget {
  final _RuleDraft rule;
  final ValueChanged<bool> onChanged;
  final VoidCallback onEdit;

  const _RuleRow({
    required this.rule,
    required this.onChanged,
    required this.onEdit,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final tone = rule.allowed ? colors.success : colors.goldMid;
    return Container(
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        gradient: colors.inactiveChipGradient,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Icon(rule.icon, color: tone, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        rule.label,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.cardLabel.copyWith(
                          color: colors.textPrimary,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                    StatusChip(
                      label: rule.allowed ? 'ALLOWED' : 'RESTRICTED',
                      color: tone,
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                Text(
                  rule.note,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.smallMeta.copyWith(
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Edit rule details',
            onPressed: onEdit,
            icon: Icon(Icons.edit_outlined, color: colors.iconMuted),
          ),
          Switch.adaptive(value: rule.allowed, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _RuleDraft {
  final String? publicId;
  final String ruleType;
  final String label;
  final String note;
  final bool allowed;
  final IconData icon;

  const _RuleDraft({
    required this.publicId,
    required this.ruleType,
    required this.label,
    required this.note,
    required this.allowed,
    required this.icon,
  });

  _RuleDraft copyWith({String? note, bool? allowed}) {
    return _RuleDraft(
      publicId: publicId,
      ruleType: ruleType,
      label: label,
      note: note ?? this.note,
      allowed: allowed ?? this.allowed,
      icon: icon,
    );
  }
}
