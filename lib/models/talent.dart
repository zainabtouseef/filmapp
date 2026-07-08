import '../core/constants/app_assets.dart';

/// Simple data model for a talent profile.
class Talent {
  final String name;
  final String role; // e.g. "Actor · Urdu, Punjabi · Lahore"
  final int ratePerDay; // in Rs
  final double rating;
  final int reviews;
  final int bookings;
  final bool verified;
  final bool available;
  final List<String> tags;
  final String imageAsset; // asset path (may be empty -> placeholder)

  const Talent({
    required this.name,
    required this.role,
    required this.ratePerDay,
    required this.rating,
    this.reviews = 0,
    this.bookings = 0,
    this.verified = true,
    this.available = true,
    this.tags = const [],
    this.imageAsset = '',
  });
}

/// Sample data matching the reference design.
class TalentData {
  static const featured = Talent(
    name: 'Sana Khalid',
    role: 'Actor · Urdu, Punjabi · Lahore',
    ratePerDay: 12000,
    rating: 4.8,
    reviews: 18,
    bookings: 18,
    tags: ['Drama Serial', 'TVC', 'Theatre'],
    imageAsset: AppAssets.sanaKhalid,
  );

  static const carousel = <Talent>[
    Talent(
        name: 'Sana Khalid',
        role: 'Actor',
        ratePerDay: 12000,
        rating: 4.8,
        imageAsset: AppAssets.sanaKhalid),
    Talent(
        name: 'Danish Taimoor',
        role: 'Actor',
        ratePerDay: 15000,
        rating: 4.7,
        imageAsset: AppAssets.danishTaimoor),
    Talent(
        name: 'Hira Mani',
        role: 'Actor',
        ratePerDay: 11000,
        rating: 4.6,
        imageAsset: AppAssets.hiraMani),
    Talent(
        name: 'Bilal Abbas',
        role: 'Actor',
        ratePerDay: 13000,
        rating: 4.9,
        imageAsset: AppAssets.bilalAbbas),
    Talent(
        name: 'Ayeza Khan',
        role: 'Actor',
        ratePerDay: 10000,
        rating: 4.5,
        imageAsset: AppAssets.ayezaKhan),
  ];
}
