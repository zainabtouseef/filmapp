import 'package:flutter/material.dart';

enum ModelUsagePlatform { instagram, website, print, billboard, tv, packaging }

enum ModelUsageStatus { active, draft, contractLocked, disputed }

class ModelCampaignCategory {
  final String id;
  final String label;
  final IconData icon;
  final bool selected;
  final bool publicVisible;

  const ModelCampaignCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.selected,
    required this.publicVisible,
  });

  ModelCampaignCategory copyWith({
    bool? selected,
    bool? publicVisible,
  }) {
    return ModelCampaignCategory(
      id: id,
      label: label,
      icon: icon,
      selected: selected ?? this.selected,
      publicVisible: publicVisible ?? this.publicVisible,
    );
  }
}

class ModelUsageRight {
  final String id;
  final ModelUsagePlatform platform;
  final String territory;
  final String duration;
  final bool exclusive;
  final ModelUsageStatus status;

  const ModelUsageRight({
    required this.id,
    required this.platform,
    required this.territory,
    required this.duration,
    required this.exclusive,
    required this.status,
  });

  ModelUsageRight copyWith({
    bool? exclusive,
    ModelUsageStatus? status,
  }) {
    return ModelUsageRight(
      id: id,
      platform: platform,
      territory: territory,
      duration: duration,
      exclusive: exclusive ?? this.exclusive,
      status: status ?? this.status,
    );
  }
}

class ModelPortfolioAsset {
  final String id;
  final String title;
  final String category;
  final String imageUrl;
  final String status;
  final bool cover;

  const ModelPortfolioAsset({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.status,
    this.cover = false,
  });

  ModelPortfolioAsset copyWith({
    String? status,
    bool? cover,
  }) {
    return ModelPortfolioAsset(
      id: id,
      title: title,
      category: category,
      imageUrl: imageUrl,
      status: status ?? this.status,
      cover: cover ?? this.cover,
    );
  }
}

class ModelUsageRate {
  final String id;
  final String label;
  final String scope;
  final int amount;
  final bool requiresReview;
  final bool negotiable;

  const ModelUsageRate({
    required this.id,
    required this.label,
    required this.scope,
    required this.amount,
    required this.requiresReview,
    required this.negotiable,
  });

  ModelUsageRate copyWith({
    int? amount,
    bool? requiresReview,
    bool? negotiable,
  }) {
    return ModelUsageRate(
      id: id,
      label: label,
      scope: scope,
      amount: amount ?? this.amount,
      requiresReview: requiresReview ?? this.requiresReview,
      negotiable: negotiable ?? this.negotiable,
    );
  }
}

class ModelRestrictedCategory {
  final String id;
  final String label;
  final bool blocked;

  const ModelRestrictedCategory({
    required this.id,
    required this.label,
    required this.blocked,
  });

  ModelRestrictedCategory copyWith({bool? blocked}) {
    return ModelRestrictedCategory(
      id: id,
      label: label,
      blocked: blocked ?? this.blocked,
    );
  }
}
