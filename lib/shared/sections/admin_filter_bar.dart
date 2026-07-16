import 'package:flutter/material.dart';

import '../../core/core_ui/widgets/core_widgets.dart';

class AdminCompactFilterBar extends StatelessWidget {
  final List<String> filters;
  final String selected;
  final ValueChanged<String> onSelected;

  const AdminCompactFilterBar({
    super.key,
    required this.filters,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: filters
            .map(
              (filter) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: CoreChip(
                  label: filter,
                  selected: selected == filter,
                  onTap: () => onSelected(filter),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
