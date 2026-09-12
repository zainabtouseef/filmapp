import '../../../core/reputation/reputation_safety_models.dart';

class DpCandidate {
  final String id;
  final String name;
  final String category;
  final String city;
  final String rateRange;
  final String pricingMode;
  final bool showsPrice;
  final bool allowsBargaining;
  final double rating;
  final bool verified;
  final bool available;
  final List<String> skills;
  final String avatarLabel;
  final String? imageUrl;
  final String notes;
  final String profileId;
  final String? marketplaceListingId;
  final int joinedDaysAgo;
  final int completedBookings;
  final String instagramHandle;
  final int instagramFollowers;
  final ReputationSafetyMetrics? trustMetrics;

  const DpCandidate({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.rateRange,
    this.pricingMode = 'negotiable',
    this.showsPrice = true,
    this.allowsBargaining = true,
    required this.rating,
    required this.verified,
    required this.available,
    required this.skills,
    required this.avatarLabel,
    this.imageUrl,
    required this.notes,
    String? profileId,
    this.marketplaceListingId,
    this.joinedDaysAgo = 45,
    this.completedBookings = 18,
    this.instagramHandle = '@cineconnect.profile',
    this.instagramFollowers = 12800,
    this.trustMetrics,
  }) : profileId = profileId ?? id;

  bool get isNew => joinedDaysAgo < 30;
}
