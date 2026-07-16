import 'package:flutter/material.dart';

import '../../core/theme/app_color_scheme.dart';
import '../../core/theme/app_text_styles.dart';
import '../cards/glass_section_card.dart';

class PremiumDataTable extends StatelessWidget {
  final List<String> columns;
  final List<List<Widget>> rows;
  final List<VoidCallback?>? rowActions;
  final double minColumnWidth;

  const PremiumDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.rowActions,
    this.minColumnWidth = 118,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    return LayoutBuilder(
      builder: (context, constraints) {
        final availableWidth = constraints.maxWidth.isFinite
            ? constraints.maxWidth
            : MediaQuery.sizeOf(context).width - 36;
        final tableWidth = availableWidth > columns.length * minColumnWidth
            ? availableWidth
            : columns.length * minColumnWidth;

        return GlassSectionCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: SizedBox(
              width: tableWidth,
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      border: Border(bottom: BorderSide(color: colors.border)),
                    ),
                    child: Row(
                      children: columns
                          .map(
                            (column) => Expanded(
                              child: Text(
                                column.toUpperCase(),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.smallMeta.copyWith(
                                  color: colors.goldDark,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                  ...rows.asMap().entries.map((entry) {
                    final index = entry.key;
                    final row = entry.value;
                    return InkWell(
                      onTap: rowActions == null ? null : rowActions![index],
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 13,
                        ),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(color: colors.borderMuted),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: row
                              .map(
                                (cell) => Expanded(
                                  child: Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: DefaultTextStyle.merge(
                                      style: AppTextStyles.cardLabel.copyWith(
                                        color: colors.textPrimary,
                                      ),
                                      child: cell,
                                    ),
                                  ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
