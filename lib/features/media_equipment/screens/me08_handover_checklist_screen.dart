import 'package:flutter/material.dart';

import '../widgets/equipment_inspection_workspace.dart';

class ME08HandoverChecklistScreen extends StatelessWidget {
  const ME08HandoverChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EquipmentInspectionWorkspace(inspectionType: 'handover');
  }
}
