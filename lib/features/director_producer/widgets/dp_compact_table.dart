import 'package:flutter/material.dart';

import '../../../shared/widgets/premium_data_table.dart';

class DPCompactTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<VoidCallback?>? rowActions;

  const DPCompactTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowActions,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumDataTable(
      columns: columns,
      rows: rows,
      rowActions: rowActions,
    );
  }
}
