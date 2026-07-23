import 'package:flutter/material.dart';

import '../widgets/equipment_inspection_workspace.dart';

class ME09ReturnChecklistScreen extends StatelessWidget {
  const ME09ReturnChecklistScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const EquipmentInspectionWorkspace(inspectionType: 'return');
  }
}
