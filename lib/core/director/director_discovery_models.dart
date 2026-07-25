import '../../features/director_producer/models/dp_candidate.dart';
import '../marketplace/marketplace_models.dart';
import '../verification/verification_models.dart';

class DirectorDiscoveryBundle {
  final List<DirectorDiscoveryItem> items;
  final Map<String, int> kindCounts;
  final Map<String, int> cityCounts;
  final Map<String, String> unsupportedCategories;

  const DirectorDiscoveryBundle({
    required this.items,
    required this.kindCounts,
    required this.cityCounts,
    required this.unsupportedCategories,
  });

  factory DirectorDiscoveryBundle.fromJson(Map<String, dynamic> json) {
    final facets = json['facets'] as Map<String, dynamic>? ?? const {};
    return DirectorDiscoveryBundle(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorDiscoveryItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      kindCounts: _intMap(facets['kind_counts']),
      cityCounts: _intMap(facets['city_counts']),
      unsupportedCategories: _stringMap(facets['unsupported_categories']),
    );
  }
}

class DirectorDiscoveryItem {
  final String publicId;
  final String? listingId;
  final String kind;
  final String category;
  final String title;
  final String subtitle;
  final String summary;
  final String cityName;
  final String? ownerName;
  final String? ownerAvatarUrl;
  final int? rateFromMinor;
  final String currency;
  final String rateLabel;
  final String verificationStatus;
  final int ratingAverage;
  final bool available;
  final List<String> tags;
  final List<MarketplaceListingMedia> media;
  final List<DirectorDiscoverySection> sections;
  final UploadedFile? resumeFile;

  const DirectorDiscoveryItem({
    required this.publicId,
    required this.listingId,
    required this.kind,
    required this.category,
    required this.title,
    required this.subtitle,
    required this.summary,
    required this.cityName,
    required this.ownerName,
    this.ownerAvatarUrl,
    required this.rateFromMinor,
    required this.currency,
    required this.rateLabel,
    required this.verificationStatus,
    required this.ratingAverage,
    required this.available,
    required this.tags,
    required this.media,
    required this.sections,
    this.resumeFile,
  });

  factory DirectorDiscoveryItem.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>?;
    return DirectorDiscoveryItem(
      publicId: json['public_id'] as String? ?? '',
      listingId: json['listing_id'] as String?,
      kind: json['kind'] as String? ?? 'provider',
      category: json['category'] as String? ?? 'Provider',
      title: json['title'] as String? ?? 'Provider',
      subtitle: json['subtitle'] as String? ?? '',
      summary: json['summary'] as String? ?? '',
      cityName: city?['name'] as String? ?? 'Pakistan',
      ownerName: owner?['display_name'] as String?,
      ownerAvatarUrl: owner?['avatar_url'] as String?,
      rateFromMinor: (json['rate_from_minor'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'PKR',
      rateLabel: json['rate_label'] as String? ?? 'Rate on request',
      verificationStatus: json['verification_status'] as String? ?? 'pending',
      ratingAverage: (json['rating_average'] as num?)?.toInt() ?? 0,
      available: json['available'] as bool? ?? true,
      tags: (json['tags'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .where((item) => item.trim().isNotEmpty)
          .toList(),
      media: (json['media'] as List<dynamic>? ?? const [])
          .map((item) =>
              MarketplaceListingMedia.fromJson(item as Map<String, dynamic>))
          .toList(),
      sections: (json['sections'] as List<dynamic>? ?? const [])
          .map((item) => DirectorDiscoverySection.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      resumeFile: json['resume_file'] == null
          ? null
          : UploadedFile.fromJson(json['resume_file'] as Map<String, dynamic>),
    );
  }

  DpCandidate toCandidate() {
    final words =
        title.split(RegExp(r'\s+')).where((word) => word.isNotEmpty).toList();
    final initials = words.take(2).map((word) => word[0].toUpperCase()).join();
    return DpCandidate(
      id: listingId ?? 'director:$kind:$publicId',
      profileId: 'director:$kind:$publicId',
      marketplaceListingId: listingId,
      name: title,
      category: category,
      city: cityName,
      rateRange: rateLabel,
      rating: ratingAverage.toDouble(),
      verified: verificationStatus == 'approved' ||
          verificationStatus == 'verified' ||
          verificationStatus == 'published',
      available: available,
      skills: tags.isEmpty
          ? [
              if (subtitle.isNotEmpty) subtitle,
              if (ownerName?.isNotEmpty == true) ownerName!,
            ]
          : tags,
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
}

class DirectorDiscoverySection {
  final String title;
  final List<DirectorDiscoveryRow> rows;

  const DirectorDiscoverySection({
    required this.title,
    required this.rows,
  });

  factory DirectorDiscoverySection.fromJson(Map<String, dynamic> json) {
    return DirectorDiscoverySection(
      title: json['title'] as String? ?? 'Details',
      rows: (json['rows'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorDiscoveryRow.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class DirectorDiscoveryRow {
  final String label;
  final String value;

  const DirectorDiscoveryRow({
    required this.label,
    required this.value,
  });

  factory DirectorDiscoveryRow.fromJson(Map<String, dynamic> json) {
    return DirectorDiscoveryRow(
      label: json['label'] as String? ?? '',
      value: json['value'] as String? ?? '',
    );
  }
}

Map<String, int> _intMap(Object? value) {
  final raw = value as Map<String, dynamic>? ?? const {};
  return raw.map((key, value) => MapEntry(key, (value as num?)?.toInt() ?? 0));
}

Map<String, String> _stringMap(Object? value) {
  final raw = value as Map<String, dynamic>? ?? const {};
  return raw.map((key, value) => MapEntry(key, '$value'));
}
