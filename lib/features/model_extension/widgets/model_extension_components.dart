import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/models/actor_talent_models.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
import '../data/model_extension_demo_data.dart';
import '../models/model_extension_models.dart';

Color modelStatusColor(BuildContext context, ModelUsageStatus status) {
  final colors = context.appColors;
  return switch (status) {
    ModelUsageStatus.active => colors.success,
    ModelUsageStatus.draft => colors.infoBlue,
    ModelUsageStatus.contractLocked => colors.goldMid,
    ModelUsageStatus.disputed => colors.danger,
  };
}

Widget modelUsageStatusChip(BuildContext context, ModelUsageStatus status) {
  return StatusChip(
    label: ModelExtensionDemoData.statusLabel(status),
    color: modelStatusColor(context, status),
  );
}

Color modelToneColor(BuildContext context, ActorTone tone) {
  return actorToneColor(context, tone);
}

String modelMoney(int amount) {
  if (amount >= 1000000) {
    return 'PKR ${(amount / 1000000).toStringAsFixed(1)}M';
  }
  if (amount >= 100000) return 'PKR ${(amount / 1000).round()}k';
  return 'PKR $amount';
}
