import 'package:flutter/material.dart';

import '../widgets/glass_card.dart';

class AdminTopBarFrame extends StatelessWidget {
  final bool compact;
  final Widget child;

  const AdminTopBarFrame({
    super.key,
    required this.compact,
    required this.child,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(compact ? 12 : 18, 12, compact ? 12 : 18, 0),
      child: GlassContainer(
        radius: compact ? 18 : 22,
        padding: EdgeInsets.symmetric(
          horizontal: compact ? 10 : 14,
          vertical: compact ? 9 : 12,
        ),
        child: child,
      ),
    );
  }
}
