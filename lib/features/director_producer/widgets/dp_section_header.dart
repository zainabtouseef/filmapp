import 'package:flutter/material.dart';

import '../../../shared/layout/admin_section_header.dart' as admin;

class DPSectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? actionText;
  final VoidCallback? onActionTap;

  const DPSectionHeader({
    super.key,
    required this.title,
    required this.icon,
    this.actionText,
    this.onActionTap,
  });

  @override
  Widget build(BuildContext context) {
    return admin.AdminSectionHeader(
      icon: icon,
      title: title,
      actionText: actionText,
      onActionTap: onActionTap,
    );
  }
}
