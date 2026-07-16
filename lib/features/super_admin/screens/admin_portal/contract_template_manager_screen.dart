part of '../super_admin_screens.dart';

class ContractTemplateManagerScreen extends StatefulWidget {
  const ContractTemplateManagerScreen({super.key});

  @override
  State<ContractTemplateManagerScreen> createState() =>
      _ContractTemplateManagerScreenState();
}

class _ContractTemplateManagerScreenState
    extends State<ContractTemplateManagerScreen> {
  int _selected = 0;
  bool _hasUsageRights = true;
  String _version = 'v1.0';

  final _templates = const [
    'Actor Booking Agreement',
    'Model Release / Campaign Agreement',
    'Location / Home Booking Agreement',
    'Media / Equipment Rental Agreement',
    'Production Crew Agreement',
    'Sponsorship / Brand Integration Agreement',
    'Addendum / Change Order',
    'Cancellation / Rescheduling Agreement',
    'Damage Claim / Deposit Adjustment Record',
  ];

  @override
  Widget build(BuildContext context) {
    return _ThreePane(
      left: AdminSurface(
        padding: const EdgeInsets.all(12),
        child: SizedBox(
          height: 112,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: _templates.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return _TemplatePill(
                label: _templates[index],
                selected: index == _selected,
                onTap: () => setState(() => _selected = index),
              );
            },
          ),
        ),
      ),
      center: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _headline(context, _templates[_selected]),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              children: [
                AdminStatusBadge(label: _version, tone: AdminDecisionTone.info),
                const AdminStatusBadge(
                    label: 'Draft', tone: AdminDecisionTone.warning),
              ],
            ),
            const SizedBox(height: 10),
            ...[
              'Parties',
              'Project',
              'Dates',
              'Fee',
              'Payment Schedule',
              'Deliverables',
              if (_hasUsageRights) 'Usage Rights',
              'Cancellation',
              'Overtime',
              'Dispute Process',
              'Special Conditions',
            ].map((clause) => _clauseEditor(context, clause)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                AdminStatusBadge(
                    label: '{{fee}}', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{dates}}', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{usage_rights}}', tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{payment_schedule}}',
                    tone: AdminDecisionTone.neutral),
                AdminStatusBadge(
                    label: '{{deliverables}}', tone: AdminDecisionTone.neutral),
              ],
            ),
          ],
        ),
      ),
      right: AdminSurface(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const AdminSectionHeader(title: 'Mandatory Rules'),
            const SizedBox(height: 8),
            ...const [
              'Model contracts must include usage rights',
              'Location contracts must include damage deposit',
              'Equipment contracts must include handover/return checklist',
              'Sponsorship contracts must include brand usage and deliverables',
            ].map((rule) => _bullet(context, rule)),
            if (!_hasUsageRights) ...[
              const SizedBox(height: 12),
              const AdminStatusBadge(
                label:
                    'Generation blocked until usage rights block is included.',
                icon: Icons.block_rounded,
                tone: AdminDecisionTone.danger,
              ),
            ],
            const SizedBox(height: 14),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                _tinyAction(context, 'Save Draft',
                    () => showCoreSnack(context, 'Draft saved to audit log')),
                _tinyAction(context, 'Publish Version', () {
                  if (!_hasUsageRights) {
                    showCoreSnack(context,
                        'Generation blocked until usage rights block is included.');
                    return;
                  }
                  setState(() => _version = 'v1.1');
                  showCoreSnack(
                      context, 'v1.1 published and audit log written');
                }),
                _tinyAction(context, 'Preview Contract',
                    () => Navigator.pushNamed(context, CoreRoutes.contract)),
                _tinyAction(
                    context,
                    'Open Full Detail',
                    () => Navigator.pushNamed(
                        context, SuperAdminRoutes.contractTemplateDetail)),
                _tinyAction(context, 'Duplicate',
                    () => showCoreSnack(context, 'Template duplicated')),
                _tinyAction(context, 'Archive',
                    () => showCoreSnack(context, 'Template archived')),
                _tinyAction(context, 'Version History',
                    () => showCoreSnack(context, 'Version history opened')),
                _tinyAction(
                    context,
                    _hasUsageRights
                        ? 'Remove Usage Rights'
                        : 'Restore Usage Rights',
                    () => setState(() => _hasUsageRights = !_hasUsageRights)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _TemplatePill extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TemplatePill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 152,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: selected
              ? colors.activeChipGradient
              : colors.inactiveChipGradient,
          border: Border.all(
            color: selected ? colors.goldMid : colors.border,
            width: selected ? 1.25 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                      color: colors.goldGlow, blurRadius: 16, spreadRadius: -4)
                ]
              : null,
        ),
        alignment: Alignment.centerLeft,
        child: Text(
          label,
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.caption.copyWith(
            color: selected ? colors.goldDark : colors.textPrimary,
            fontWeight: selected ? FontWeight.w900 : FontWeight.w700,
            height: 1.25,
          ),
        ),
      ),
    );
  }
}
