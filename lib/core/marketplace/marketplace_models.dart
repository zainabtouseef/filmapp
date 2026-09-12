import '../../features/director_producer/models/dp_candidate.dart';
import '../verification/verification_models.dart';

class MarketplaceListing {
  final String publicId;
  final String listingType;
  final String title;
  final String summary;
  final String cityName;
  final int? priceFromMinor;
  final int? configuredPriceFromMinor;
  final String currency;
  final String pricingMode;
  final bool showsPrice;
  final bool allowsBargaining;
  final String verificationStatus;
  final String ownerName;
  final String? ownerAvatarUrl;
  final List<MarketplaceListingMedia> media;
  final VerifiedMediaKit? mediaKit;

  const MarketplaceListing({
    required this.publicId,
    required this.listingType,
    required this.title,
    required this.summary,
    required this.cityName,
    required this.priceFromMinor,
    this.configuredPriceFromMinor,
    required this.currency,
    this.pricingMode = 'negotiable',
    this.showsPrice = true,
    this.allowsBargaining = true,
    required this.verificationStatus,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.media,
    this.mediaKit,
  });

  factory MarketplaceListing.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    final rawMedia = json['media'] as List<dynamic>? ?? const [];
    return MarketplaceListing(
      publicId: json['public_id'] as String,
      listingType: json['listing_type'] as String,
      title: json['title'] as String,
      summary: json['summary'] as String,
      cityName: city?['name'] as String? ?? 'Pakistan',
      priceFromMinor: json['price_from_minor'] as int?,
      configuredPriceFromMinor:
          json['configured_price_from_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      pricingMode: json['pricing_mode'] as String? ?? 'negotiable',
      showsPrice: json['shows_price'] as bool? ?? true,
      allowsBargaining: json['allows_bargaining'] as bool? ?? true,
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      ownerName: owner['display_name'] as String? ?? 'CineConnect member',
      ownerAvatarUrl: owner['avatar_url'] as String?,
      media: rawMedia
          .map((item) =>
              MarketplaceListingMedia.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      mediaKit: json['media_kit'] is Map<String, dynamic>
          ? VerifiedMediaKit.fromJson(json['media_kit'] as Map<String, dynamic>)
          : null,
    );
  }

  DpCandidate toCandidate() {
    final words = title
        .split(RegExp(r'\s+'))
        .where((item) => item.trim().isNotEmpty)
        .toList();
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    return DpCandidate(
      id: publicId,
      profileId: publicId,
      marketplaceListingId: publicId,
      name: title,
      category: switch (listingType) {
        'talent' => 'Talent',
        'actor' => 'Actors',
        'model' => 'Models',
        'influencer' => 'Influencers',
        'location' => 'Locations',
        'equipment' => 'Media & Equipment',
        'agency' => 'Agencies',
        'distribution' => 'Distribution',
        _ => listingType,
      },
      city: cityName,
      rateRange: _priceLabel(),
      pricingMode: pricingMode,
      showsPrice: showsPrice,
      allowsBargaining: allowsBargaining,
      rating: 0,
      verified: verificationStatus == 'approved',
      available: true,
      skills: [currency, ownerName],
      avatarLabel: initials.isEmpty ? 'CC' : initials,
      imageUrl: coverImageUrl,
      notes: summary,
    );
  }

  String? get coverImageUrl {
    if (media.isEmpty) return ownerAvatarUrl;
    for (final item in media) {
      if (item.isCover) return item.file?.publicUrl ?? ownerAvatarUrl;
    }
    return media.first.file?.publicUrl ?? ownerAvatarUrl;
  }

  String _priceLabel() {
    if (!showsPrice) return 'Open to offers';
    final amount = priceFromMinor;
    if (amount == null) return 'Rate on request';
    final whole = (amount / 100).round();
    if (whole >= 1000000) {
      return '$currency ${(whole / 1000000).toStringAsFixed(1)}M';
    }
    if (whole >= 1000) {
      return '$currency ${(whole / 1000).round()}k';
    }
    return '$currency $whole';
  }

  String get pricingChoiceLabel => switch (pricingMode) {
        'fixed' => 'Fixed public price',
        'on_request' => 'Private price · bargaining',
        _ => 'Public price · bargaining',
      };
}

class VerifiedMediaKit {
  final bool verified;
  final String headline;
  final List<MediaKitReel> reels;
  final List<MediaKitMetric> metrics;
  final List<MediaKitMetric> audience;
  final List<MediaKitPlatform> platforms;
  final List<MediaKitRateCard> rateCards;
  final double ratingAverage;
  final int reviewCount;

  const VerifiedMediaKit({
    required this.verified,
    required this.headline,
    required this.reels,
    required this.metrics,
    required this.audience,
    required this.platforms,
    required this.rateCards,
    required this.ratingAverage,
    required this.reviewCount,
  });

  factory VerifiedMediaKit.fromJson(Map<String, dynamic> json) {
    final reviews = json['reviews'] as Map<String, dynamic>? ?? const {};
    return VerifiedMediaKit(
      verified: json['verified'] as bool? ?? false,
      headline: json['headline'] as String? ?? 'Verified media kit',
      reels: (json['reels'] as List<dynamic>? ?? const [])
          .map((item) => MediaKitReel.fromJson(item as Map<String, dynamic>))
          .toList(),
      metrics: (json['metrics'] as List<dynamic>? ?? const [])
          .map((item) => MediaKitMetric.fromJson(item as Map<String, dynamic>))
          .toList(),
      audience: (json['audience'] as List<dynamic>? ?? const [])
          .map((item) => MediaKitMetric.fromJson(item as Map<String, dynamic>))
          .toList(),
      platforms: (json['platforms'] as List<dynamic>? ?? const [])
          .map(
              (item) => MediaKitPlatform.fromJson(item as Map<String, dynamic>))
          .toList(),
      rateCards: (json['rate_cards'] as List<dynamic>? ?? const [])
          .map(
              (item) => MediaKitRateCard.fromJson(item as Map<String, dynamic>))
          .toList(),
      ratingAverage: (reviews['rating_average'] as num?)?.toDouble() ?? 0,
      reviewCount: (reviews['review_count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MediaKitReel {
  final String title;
  final String category;
  final int? durationSeconds;
  final UploadedFile? file;
  final UploadedFile? thumbnailFile;

  const MediaKitReel({
    required this.title,
    required this.category,
    required this.durationSeconds,
    required this.file,
    required this.thumbnailFile,
  });

  factory MediaKitReel.fromJson(Map<String, dynamic> json) {
    return MediaKitReel(
      title: json['title'] as String? ?? 'Portfolio reel',
      category: json['category'] as String? ?? 'showreel',
      durationSeconds: (json['duration_seconds'] as num?)?.toInt(),
      file: MarketplacePortfolioItem._uploadedFileOrNull(json['file']),
      thumbnailFile:
          MarketplacePortfolioItem._uploadedFileOrNull(json['thumbnail_file']),
    );
  }

  bool get isVideo => file?.mimeType.startsWith('video/') ?? false;
}

class MediaKitMetric {
  final String label;
  final String value;

  const MediaKitMetric({required this.label, required this.value});

  factory MediaKitMetric.fromJson(Map<String, dynamic> json) {
    return MediaKitMetric(
      label: json['label'] as String? ?? 'Metric',
      value: json['value'] as String? ?? 'Not provided',
    );
  }
}

class MediaKitPlatform {
  final String platform;
  final String url;

  const MediaKitPlatform({required this.platform, required this.url});

  factory MediaKitPlatform.fromJson(Map<String, dynamic> json) {
    return MediaKitPlatform(
      platform: json['platform'] as String? ?? 'Social',
      url: json['url'] as String? ?? '',
    );
  }
}

class MediaKitRateCard {
  final String label;
  final String priceLabel;
  final String scope;
  final bool negotiable;

  const MediaKitRateCard({
    required this.label,
    required this.priceLabel,
    required this.scope,
    required this.negotiable,
  });

  factory MediaKitRateCard.fromJson(Map<String, dynamic> json) {
    return MediaKitRateCard(
      label: json['label'] as String? ?? 'Package',
      priceLabel: json['price_label'] as String? ?? 'Rate on request',
      scope: json['scope'] as String? ?? 'Campaign package',
      negotiable: json['negotiable'] as bool? ?? true,
    );
  }
}

class MarketplaceListingMedia {
  final UploadedFile? file;
  final int sortOrder;
  final bool isCover;
  final String? caption;

  const MarketplaceListingMedia({
    required this.file,
    required this.sortOrder,
    required this.isCover,
    required this.caption,
  });

  factory MarketplaceListingMedia.fromJson(Map<String, dynamic> json) {
    return MarketplaceListingMedia(
      file: MarketplacePortfolioItem._uploadedFileOrNull(json['file']),
      sortOrder: json['sort_order'] as int? ?? 100,
      isCover: json['is_cover'] as bool? ?? false,
      caption: json['caption'] as String?,
    );
  }
}

class MarketplaceSavedSearch {
  final String publicId;
  final String name;
  final String? listingType;
  final String? queryText;
  final bool notifyEnabled;
  final DateTime? createdAt;

  const MarketplaceSavedSearch({
    required this.publicId,
    required this.name,
    required this.listingType,
    required this.queryText,
    required this.notifyEnabled,
    required this.createdAt,
  });

  factory MarketplaceSavedSearch.fromJson(Map<String, dynamic> json) {
    return MarketplaceSavedSearch(
      publicId: json['public_id'] as String,
      name: json['name'] as String,
      listingType: json['listing_type'] as String?,
      queryText: json['query_text'] as String?,
      notifyEnabled: json['notify_enabled'] as bool? ?? false,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  String get subtitle {
    final parts = <String>[
      if (listingType != null && listingType!.isNotEmpty) listingType!,
      if (queryText != null && queryText!.isNotEmpty) '"$queryText"',
      notifyEnabled ? 'alerts on' : 'alerts off',
    ];
    return parts.isEmpty ? 'Marketplace search' : parts.join(' · ');
  }
}

class MarketplaceShortlistItem {
  final String publicId;
  final MarketplaceListing listing;
  final int rank;
  final String? notes;
  final String status;

  const MarketplaceShortlistItem({
    required this.publicId,
    required this.listing,
    required this.rank,
    required this.notes,
    required this.status,
  });

  factory MarketplaceShortlistItem.fromJson(Map<String, dynamic> json) {
    return MarketplaceShortlistItem(
      publicId: json['public_id'] as String,
      listing: MarketplaceListing.fromJson(
        json['listing'] as Map<String, dynamic>,
      ),
      rank: json['rank'] as int? ?? 0,
      notes: json['notes'] as String?,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class MarketplaceShortlist {
  final String publicId;
  final String? projectId;
  final String? requirementId;
  final String name;
  final List<MarketplaceShortlistItem> items;
  final DateTime? createdAt;

  const MarketplaceShortlist({
    required this.publicId,
    required this.projectId,
    required this.requirementId,
    required this.name,
    required this.items,
    required this.createdAt,
  });

  factory MarketplaceShortlist.fromJson(Map<String, dynamic> json) {
    final rawItems = json['items'] as List<dynamic>? ?? const [];
    return MarketplaceShortlist(
      publicId: json['public_id'] as String,
      projectId: json['project_id'] as String?,
      requirementId: json['requirement_id'] as String?,
      name: json['name'] as String,
      items: rawItems
          .map((item) =>
              MarketplaceShortlistItem.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.rank.compareTo(b.rank)),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class MarketplaceShortlistBundle {
  final List<MarketplaceSavedSearch> savedSearches;
  final List<MarketplaceShortlist> shortlists;

  const MarketplaceShortlistBundle({
    required this.savedSearches,
    required this.shortlists,
  });
}

class MarketplacePortfolioItem {
  final String publicId;
  final String profileType;
  final String profileId;
  final String title;
  final String category;
  final UploadedFile? file;
  final UploadedFile? thumbnailFile;
  final int? durationSeconds;
  final String status;
  final bool isCover;
  final int sortOrder;
  final String moderationStatus;

  const MarketplacePortfolioItem({
    required this.publicId,
    required this.profileType,
    required this.profileId,
    required this.title,
    required this.category,
    required this.file,
    required this.thumbnailFile,
    required this.durationSeconds,
    required this.status,
    required this.isCover,
    required this.sortOrder,
    required this.moderationStatus,
  });

  factory MarketplacePortfolioItem.fromJson(Map<String, dynamic> json) {
    return MarketplacePortfolioItem(
      publicId: json['public_id'] as String,
      profileType: json['profile_type'] as String? ?? 'talent',
      profileId: json['profile_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled media',
      category: json['category'] as String? ?? 'showreel',
      file: _uploadedFileOrNull(json['file']),
      thumbnailFile: _uploadedFileOrNull(json['thumbnail_file']),
      durationSeconds: json['duration_seconds'] as int?,
      status: json['status'] as String? ?? 'draft',
      isCover: json['is_cover'] as bool? ?? false,
      sortOrder: json['sort_order'] as int? ?? 100,
      moderationStatus: json['moderation_status'] as String? ?? 'pending',
    );
  }

  static UploadedFile? _uploadedFileOrNull(Object? value) {
    if (value is Map<String, dynamic>) {
      return UploadedFile.fromJson(value);
    }
    return null;
  }

  bool get isImage => file?.mimeType.startsWith('image/') ?? false;

  String get displayCategory {
    return switch (category) {
      'headshot' || 'headshots' => 'Headshots',
      'ad' || 'ads' => 'Ads',
      'voice' || 'voice_sample' || 'voice_samples' => 'Voice Samples',
      'drama_clip' || 'drama_clips' || 'showreel' => 'Drama Clips',
      _ => category
          .replaceAll('_', ' ')
          .split(' ')
          .where((part) => part.trim().isNotEmpty)
          .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
          .join(' '),
    };
  }

  String get displayStatus {
    return switch (status) {
      'published' => 'Public',
      'draft' => 'Draft',
      _ => status,
    };
  }

  String get durationLabel {
    final seconds = durationSeconds;
    if (seconds != null && seconds > 0) {
      final minutes = seconds ~/ 60;
      final remainder = seconds % 60;
      return '$minutes:${remainder.toString().padLeft(2, '0')}';
    }
    final mime = file?.mimeType;
    if (mime == null || mime.isEmpty) return 'Media';
    if (mime.startsWith('image/')) return 'Image';
    if (mime.startsWith('video/')) return 'Video';
    return mime.split('/').last.toUpperCase();
  }
}
