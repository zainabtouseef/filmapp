import 'package:flutter/material.dart';

import '../layout/admin_section_header.dart';
import '../widgets/premium_data_table.dart';

class AdminTableSection extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<VoidCallback?>? rowActions;
  final Widget? filterBar;

  const AdminTableSection({
    super.key,
    required this.title,
    required this.columns,
    required this.rows,
    this.icon = Icons.table_chart_outlined,
    this.actionText,
    this.onActionTap,
    this.rowActions,
    this.filterBar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AdminSectionHeader(
          icon: icon,
          title: title,
          actionText: actionText,
          onActionTap: onActionTap,
        ),
        const SizedBox(height: 10),
        if (filterBar != null) ...[
          filterBar!,
          const SizedBox(height: 10),
        ],
        PremiumDataTable(
          columns: columns,
          rows: rows,
          rowActions: rowActions,
        ),
      ],
    );
  }
}
