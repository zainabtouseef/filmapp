import 'package:flutter/material.dart';

import '../models/model_extension_models.dart';

class ModelExtensionDemoData {
  ModelExtensionDemoData._();

  static const heroImage =
      'https://images.unsplash.com/photo-1496747611176-843222e1e57c?auto=format&fit=crop&w=1200&q=80';

  static const seedCategories = [
    ModelCampaignCategory(
      id: 'fashion',
      label: 'Fashion',
      icon: Icons.checkroom_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'beauty',
      label: 'Beauty',
      icon: Icons.face_retouching_natural_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'commercial',
      label: 'Commercial',
      icon: Icons.campaign_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'lifestyle',
      label: 'Lifestyle',
      icon: Icons.local_florist_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'bridal',
      label: 'Bridal',
      icon: Icons.diamond_outlined,
      selected: false,
      publicVisible: false,
    ),
    ModelCampaignCategory(
      id: 'product',
      label: 'Product',
      icon: Icons.shopping_bag_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'fitness',
      label: 'Fitness',
      icon: Icons.fitness_center_outlined,
      selected: false,
      publicVisible: false,
    ),
    ModelCampaignCategory(
      id: 'ecommerce',
      label: 'Ecommerce',
      icon: Icons.storefront_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'billboard',
      label: 'Billboard',
      icon: Icons.signpost_outlined,
      selected: true,
      publicVisible: false,
    ),
    ModelCampaignCategory(
      id: 'print',
      label: 'Print',
      icon: Icons.newspaper_outlined,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'social',
      label: 'Social Media',
      icon: Icons.alternate_email_rounded,
      selected: true,
      publicVisible: true,
    ),
    ModelCampaignCategory(
      id: 'tvc',
      label: 'TVC',
      icon: Icons.live_tv_outlined,
      selected: true,
      publicVisible: true,
    ),
  ];

  static const seedUsageRights = [
    ModelUsageRight(
      id: 'UR-IG-6M',
      platform: ModelUsagePlatform.instagram,
      territory: 'Pakistan',
      duration: '6 months',
      exclusive: false,
      status: ModelUsageStatus.active,
    ),
    ModelUsageRight(
      id: 'UR-BB-3M',
      platform: ModelUsagePlatform.billboard,
      territory: 'Lahore only',
      duration: '3 months',
      exclusive: true,
      status: ModelUsageStatus.contractLocked,
    ),
    ModelUsageRight(
      id: 'UR-TV-1Y',
      platform: ModelUsagePlatform.tv,
      territory: 'South Asia',
      duration: '1 year',
      exclusive: true,
      status: ModelUsageStatus.draft,
    ),
    ModelUsageRight(
      id: 'UR-PACK-2Y',
      platform: ModelUsagePlatform.packaging,
      territory: 'GCC',
      duration: '2 years',
      exclusive: false,
      status: ModelUsageStatus.active,
    ),
  ];

  static const seedPortfolio = [
    ModelPortfolioAsset(
      id: 'mp-headshot',
      title: 'Clean Beauty Headshot',
      category: 'Headshots',
      imageUrl:
          'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=900&q=80',
      status: 'Public',
      cover: true,
    ),
    ModelPortfolioAsset(
      id: 'mp-full',
      title: 'Full-length Neutral',
      category: 'Full-length',
      imageUrl:
          'https://images.unsplash.com/photo-1517841905240-472988babdf9?auto=format&fit=crop&w=900&q=80',
      status: 'Public',
    ),
    ModelPortfolioAsset(
      id: 'mp-editorial',
      title: 'Editorial Monochrome',
      category: 'Editorial',
      imageUrl:
          'https://images.unsplash.com/photo-1512316609839-ce289d3eba0a?auto=format&fit=crop&w=900&q=80',
      status: 'Moderation',
    ),
    ModelPortfolioAsset(
      id: 'mp-bridal',
      title: 'Ethnic Bridal Look',
      category: 'Ethnic Wear',
      imageUrl:
          'https://images.unsplash.com/photo-1515886657613-9f3515b0c78f?auto=format&fit=crop&w=900&q=80',
      status: 'Private',
    ),
    ModelPortfolioAsset(
      id: 'mp-product',
      title: 'Product Beauty Frame',
      category: 'Product Shoots',
      imageUrl:
          'https://images.unsplash.com/photo-1522335789203-aabd1fc54bc9?auto=format&fit=crop&w=900&q=80',
      status: 'Public',
    ),
  ];

  static const seedRates = [
    ModelUsageRate(
      id: 'one-day',
      label: 'One-day shoot',
      scope: 'Shoot fee only',
      amount: 120000,
      requiresReview: false,
      negotiable: true,
    ),
    ModelUsageRate(
      id: 'social-media',
      label: 'Social media usage',
      scope: 'Instagram, TikTok, Facebook',
      amount: 180000,
      requiresReview: true,
      negotiable: true,
    ),
    ModelUsageRate(
      id: 'billboard',
      label: 'Billboard',
      scope: 'Outdoor visibility',
      amount: 420000,
      requiresReview: true,
      negotiable: false,
    ),
    ModelUsageRate(
      id: 'tvc',
      label: 'TVC',
      scope: 'Broadcast and digital cutdowns',
      amount: 520000,
      requiresReview: true,
      negotiable: true,
    ),
    ModelUsageRate(
      id: 'exclusive',
      label: 'Exclusive brand use',
      scope: 'Category lockout',
      amount: 850000,
      requiresReview: true,
      negotiable: false,
    ),
    ModelUsageRate(
      id: 'long-campaign',
      label: 'Long-term campaign',
      scope: '6-12 month campaign',
      amount: 1100000,
      requiresReview: true,
      negotiable: true,
    ),
  ];

  static const seedRestricted = [
    ModelRestrictedCategory(id: 'tobacco', label: 'Tobacco', blocked: true),
    ModelRestrictedCategory(id: 'political', label: 'Political', blocked: true),
    ModelRestrictedCategory(id: 'adult', label: 'Adult content', blocked: true),
    ModelRestrictedCategory(
        id: 'skin', label: 'Skin-lightening', blocked: true),
    ModelRestrictedCategory(id: 'crypto', label: 'Crypto ads', blocked: false),
    ModelRestrictedCategory(
        id: 'fast-fashion', label: 'Fast fashion', blocked: false),
  ];

  static String platformLabel(ModelUsagePlatform platform) {
    return switch (platform) {
      ModelUsagePlatform.instagram => 'Instagram',
      ModelUsagePlatform.website => 'Website',
      ModelUsagePlatform.print => 'Print',
      ModelUsagePlatform.billboard => 'Billboard',
      ModelUsagePlatform.tv => 'TV',
      ModelUsagePlatform.packaging => 'Packaging',
    };
  }

  static String statusLabel(ModelUsageStatus status) {
    return switch (status) {
      ModelUsageStatus.active => 'ACTIVE',
      ModelUsageStatus.draft => 'DRAFT',
      ModelUsageStatus.contractLocked => 'CONTRACT LOCKED',
      ModelUsageStatus.disputed => 'DISPUTED',
    };
  }
}

class ModelExtensionDemoStore extends ChangeNotifier {
  ModelExtensionDemoStore._()
      : categories = List.of(ModelExtensionDemoData.seedCategories),
        usageRights = List.of(ModelExtensionDemoData.seedUsageRights),
        portfolio = List.of(ModelExtensionDemoData.seedPortfolio),
        rates = List.of(ModelExtensionDemoData.seedRates),
        restricted = List.of(ModelExtensionDemoData.seedRestricted);

  static final instance = ModelExtensionDemoStore._();

  List<ModelCampaignCategory> categories;
  List<ModelUsageRight> usageRights;
  List<ModelPortfolioAsset> portfolio;
  List<ModelUsageRate> rates;
  List<ModelRestrictedCategory> restricted;
  bool requireReview = true;
  bool autoFlagViolations = true;
  bool savedToContractRules = false;
  bool ratesPublished = false;
  int _newRightCount = 0;
  int _newPortfolioCount = 0;

  int get selectedCategoryCount =>
      categories.where((category) => category.selected).length;

  int get publicCategoryCount =>
      categories.where((category) => category.publicVisible).length;

  void toggleCategory(String id) {
    categories = categories
        .map(
          (category) => category.id == id
              ? category.copyWith(
                  selected: !category.selected,
                  publicVisible:
                      !category.selected ? category.publicVisible : false,
                )
              : category,
        )
        .toList();
    savedToContractRules = false;
    notifyListeners();
  }

  void toggleCategoryVisibility(String id) {
    categories = categories
        .map(
          (category) => category.id == id
              ? category.copyWith(publicVisible: !category.publicVisible)
              : category,
        )
        .toList();
    savedToContractRules = false;
    notifyListeners();
  }

  void saveCategories() {
    savedToContractRules = true;
    notifyListeners();
  }

  void toggleUsageExclusive(String id) {
    usageRights = usageRights
        .map(
          (right) => right.id == id
              ? right.copyWith(exclusive: !right.exclusive)
              : right,
        )
        .toList();
    notifyListeners();
  }

  void lockUsageRight(String id) {
    usageRights = usageRights
        .map(
          (right) => right.id == id
              ? right.copyWith(status: ModelUsageStatus.contractLocked)
              : right,
        )
        .toList();
    notifyListeners();
  }

  void addUsageRight() {
    _newRightCount += 1;
    usageRights = [
      ModelUsageRight(
        id: 'UR-WEB-NEW-$_newRightCount',
        platform: ModelUsagePlatform.website,
        territory: 'Worldwide',
        duration: '3 months',
        exclusive: false,
        status: ModelUsageStatus.draft,
      ),
      ...usageRights,
    ];
    notifyListeners();
  }

  void setPortfolioCover(String id) {
    portfolio =
        portfolio.map((item) => item.copyWith(cover: item.id == id)).toList();
    notifyListeners();
  }

  void togglePortfolioStatus(String id) {
    portfolio = portfolio
        .map(
          (item) => item.id == id
              ? item.copyWith(
                  status: item.status == 'Public' ? 'Private' : 'Public')
              : item,
        )
        .toList();
    notifyListeners();
  }

  void addPortfolioPreview() {
    _newPortfolioCount += 1;
    portfolio = [
      ModelPortfolioAsset(
        id: 'mp-new-preview-$_newPortfolioCount',
        title: 'Ramp Walk Preview',
        category: 'Ramp',
        imageUrl:
            'https://images.unsplash.com/photo-1503342217505-b0a15ec3261c?auto=format&fit=crop&w=900&q=80',
        status: 'Moderation',
      ),
      ...portfolio,
    ];
    notifyListeners();
  }

  void updateRate(
    String id, {
    int? amount,
    bool? requiresReview,
    bool? negotiable,
  }) {
    rates = rates
        .map(
          (rate) => rate.id == id
              ? rate.copyWith(
                  amount: amount,
                  requiresReview: requiresReview,
                  negotiable: negotiable,
                )
              : rate,
        )
        .toList();
    ratesPublished = false;
    notifyListeners();
  }

  void resetRates() {
    rates = List.of(ModelExtensionDemoData.seedRates);
    ratesPublished = false;
    notifyListeners();
  }

  void publishRates() {
    ratesPublished = true;
    notifyListeners();
  }

  void toggleRestricted(String id) {
    restricted = restricted
        .map(
          (item) =>
              item.id == id ? item.copyWith(blocked: !item.blocked) : item,
        )
        .toList();
    notifyListeners();
  }

  void toggleRequireReview(bool value) {
    requireReview = value;
    notifyListeners();
  }

  void toggleAutoFlag(bool value) {
    autoFlagViolations = value;
    notifyListeners();
  }
}
