import 'package:flutter/material.dart';

import '../../../core/theme/app_color_scheme.dart';
import '../../../shared/formatters/cine_format.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../actor_talent/models/actor_talent_models.dart';
import '../../actor_talent/widgets/actor_talent_components.dart';
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
    label: modelUsageStatusLabel(status),
    color: modelStatusColor(context, status),
  );
}

String modelUsageStatusLabel(ModelUsageStatus status) {
  return switch (status) {
    ModelUsageStatus.active => 'ACTIVE',
    ModelUsageStatus.draft => 'DRAFT',
    ModelUsageStatus.contractLocked => 'CONTRACT LOCKED',
    ModelUsageStatus.disputed => 'DISPUTED',
  };
}

String modelPlatformLabel(ModelUsagePlatform platform) {
  return switch (platform) {
    ModelUsagePlatform.instagram => 'Instagram',
    ModelUsagePlatform.website => 'Website',
    ModelUsagePlatform.print => 'Print',
    ModelUsagePlatform.billboard => 'Billboard',
    ModelUsagePlatform.tv => 'TV',
    ModelUsagePlatform.packaging => 'Packaging',
  };
}

Color modelToneColor(BuildContext context, ActorTone tone) {
  return actorToneColor(context, tone);
}

String modelMoney(int amount) {
  return CineFormat.currency(amount, compact: true);
}
