import 'package:flutter/material.dart';

import '../widgets/cine_animated_filter_rail.dart';

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
    return CineAnimatedFilterRail<String>(
      values: filters,
      selected: selected,
      onSelected: onSelected,
      labelFor: (filter) => filter,
    );
  }
}
