part of '../super_admin_screens.dart';

class RevenueSettingsScreen extends StatefulWidget {
  const RevenueSettingsScreen({super.key});

  @override
  State<RevenueSettingsScreen> createState() => _RevenueSettingsScreenState();
}

class _RevenueSettingsScreenState extends State<RevenueSettingsScreen> {
  bool _autoInvoice = true;
  bool _autoSettlement = false;
  bool _holdHighValue = true;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionHeader(title: 'This Month'),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: const [
                  AdminStatusBadge(
                      label: 'Revenue PKR 2.8M',
                      tone: AdminDecisionTone.success),
                  AdminStatusBadge(
                      label: '+22% vs last month',
                      tone: AdminDecisionTone.info),
                  AdminStatusBadge(
                      label: '14 invoices generated',
                      tone: AdminDecisionTone.neutral),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminSurface(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AdminSectionHeader(title: 'Fee Rules'),
              const SizedBox(height: 6),
              _settingsToggle(
                context,
                title: 'Auto-generate monthly invoices',
                subtitle:
                    'Create invoices for all settled bookings automatically.',
                value: _autoInvoice,
                onChanged: (v) => setState(() => _autoInvoice = v),
              ),
              _settingsToggle(
                context,
                title: 'Auto-release settlements',
                subtitle:
                    'Release verified payouts without a manual review step.',
                value: _autoSettlement,
                onChanged: (v) => setState(() => _autoSettlement = v),
              ),
              _settingsToggle(
                context,
                title: 'Hold high-value proofs for review',
                subtitle:
                    'Proofs above PKR 200,000 always require manual sign-off.',
                value: _holdHighValue,
                onChanged: (v) => setState(() => _holdHighValue = v),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AdminSurface(
          child: Wrap(
            spacing: 10,
            runSpacing: 10,
            children: [
              AdminActionButton(
                icon: Icons.save_outlined,
                label: 'Save Settings',
                onTap: () => showCoreSnack(context, 'Revenue settings saved'),
              ),
              AdminActionButton(
                icon: Icons.percent_rounded,
                label: 'Open Commission & Fees',
                secondary: true,
                onTap: () =>
                    Navigator.pushNamed(context, SuperAdminRoutes.fees),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _settingsToggle(
    BuildContext context, {
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    final colors = context.appColors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppTextStyles.label.copyWith(
                    color: colors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.caption
                      .copyWith(color: colors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: colors.goldDark,
          ),
        ],
      ),
    );
  }
}
