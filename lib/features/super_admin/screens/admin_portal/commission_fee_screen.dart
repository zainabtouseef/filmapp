part of '../super_admin_screens.dart';

class CommissionFeeScreen extends StatefulWidget {
  const CommissionFeeScreen({super.key});

  @override
  State<CommissionFeeScreen> createState() => _CommissionFeeScreenState();
}

class _CommissionFeeScreenState extends State<CommissionFeeScreen> {
  int _preview = 2800000;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _feeSection(context, 'Platform Commission by Category',
            AdminMockData.commissionRules),
        const SizedBox(height: 12),
        _feeSection(context, 'Subscription Plans', const [
          ('Free', 'PKR 0', 'Basic listing'),
          ('Verified Pro', 'PKR 4,500/mo', 'Boosted profile'),
          ('Production House', 'PKR 18,000/mo', 'Team controls'),
          ('Agency Pro', 'PKR 14,000/mo', 'Roster management'),
          ('Featured Partner', 'PKR 30,000/mo', 'Premium tools'),
        ]),
        const SizedBox(height: 12),
        _feeSection(context, 'Featured Listing Pricing', const [
          ('Homepage featured', 'PKR 25,000', '7 days'),
          ('City top listing', 'PKR 12,000', '5 days'),
          ('Search boost', 'PKR 7,500', '72 hours'),
          ('Category spotlight', 'PKR 18,000', '7 days'),
        ]),
        const SizedBox(height: 12),
        AdminSurface(
          padding: const EdgeInsets.all(13),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Revenue preview: PKR $_preview',
                  style: AppTextStyles.cardTitle
                      .copyWith(color: context.appColors.textPrimary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  AdminActionButton(
                      icon: Icons.receipt_long_outlined,
                      label: 'Generate monthly invoice',
                      onTap: () => showCoreSnack(context, 'Invoice generated')),
                  AdminActionButton(
                      icon: Icons.download_outlined,
                      label: 'Export CSV/PDF',
                      secondary: true,
                      onTap: () =>
                          showCoreSnack(context, 'Commission export prepared')),
                  AdminActionButton(
                      icon: Icons.tune_rounded,
                      label: 'Revenue Settings',
                      secondary: true,
                      onTap: () => Navigator.pushNamed(
                          context, SuperAdminRoutes.paymentRevenue)),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _feeSection(
      BuildContext context, String title, List<(String, String, String)> rows) {
    final colors = context.appColors;
    return AdminSurface(
      padding: const EdgeInsets.all(13),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AdminSectionHeader(title: title),
          const SizedBox(height: 4),
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) _reviewDivider(context),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(rows[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.cardTitle
                              .copyWith(color: colors.textPrimary)),
                      const SizedBox(height: 3),
                      _text(context, rows[i].$3),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                AdminStatusBadge(
                    label: rows[i].$2, tone: AdminDecisionTone.warning),
                const SizedBox(width: 4),
                CoreIconButton(
                  icon: Icons.edit_outlined,
                  tooltip: 'Edit',
                  onTap: () => _noteDialog(
                    context,
                    'Edit ${rows[i].$1}',
                    onSave: () => setState(() => _preview += 25000),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}
