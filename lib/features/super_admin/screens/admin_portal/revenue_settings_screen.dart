part of '../super_admin_screens.dart';

class RevenueSettingsScreen extends StatelessWidget {
  const RevenueSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSurface(
          padding: EdgeInsets.zero,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: 6,
                  decoration: BoxDecoration(
                    color: context.appColors.goldMid,
                    borderRadius: const BorderRadius.horizontal(
                      left: Radius.circular(8),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _headline(context, 'Revenue controls'),
                        const SizedBox(height: 6),
                        _text(
                          context,
                          'Commission calculations are governed by the active '
                          'backend fee rules below. Payment verification and '
                          'settlement release remain separate approval steps.',
                        ),
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            AdminActionButton(
                              icon: Icons.receipt_long_outlined,
                              label: 'Payment ledger',
                              secondary: true,
                              onTap: () => Navigator.pushNamed(
                                context,
                                SuperAdminRoutes.paymentLedger,
                              ),
                            ),
                            AdminActionButton(
                              icon: Icons.analytics_outlined,
                              label: 'Revenue analytics',
                              secondary: true,
                              onTap: () => Navigator.pushNamed(
                                context,
                                SuperAdminRoutes.analytics,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 14),
        const CommissionFeeScreen(),
      ],
    );
  }
}
