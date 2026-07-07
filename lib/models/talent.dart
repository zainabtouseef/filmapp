import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

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
    imageAsset: 'assets/images/sana_khalid.jpg',
  );

  static const carousel = <Talent>[
    Talent(name: 'Sana Khalid', role: 'Actor', ratePerDay: 12000, rating: 4.8, imageAsset: 'assets/images/sana_khalid.jpg'),
    Talent(name: 'Danish Taimoor', role: 'Actor', ratePerDay: 15000, rating: 4.7, imageAsset: 'assets/images/danish.jpg'),
    Talent(name: 'Hira Mani', role: 'Actor', ratePerDay: 11000, rating: 4.6, imageAsset: 'assets/images/hira.jpg'),
    Talent(name: 'Bilal Abbas', role: 'Actor', ratePerDay: 13000, rating: 4.9, imageAsset: 'assets/images/bilal.jpg'),
    Talent(name: 'Ayeza Khan', role: 'Actor', ratePerDay: 10000, rating: 4.5, imageAsset: 'assets/images/ayeza.jpg'),
  ];
}

/// A talent portrait that gracefully falls back to a cinematic
/// placeholder if the asset is missing (so the app runs before you
/// drop real photos into assets/images/).
class PortraitImage extends StatelessWidget {
  final String asset;
  final BoxFit fit;
  final String? label;

  const PortraitImage({
    super.key,
    required this.asset,
    this.fit = BoxFit.cover,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    final placeholder = _placeholder();
    if (asset.isEmpty) return placeholder;
    return Image.asset(
      asset,
      fit: fit,
      errorBuilder: (_, __, ___) => placeholder,
    );
  }

  Widget _placeholder() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Color(0xFF262019), Color(0xFF15110C)],
        ),
      ),
      alignment: Alignment.center,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.person_outline_rounded,
              color: AppColors.textTertiary, size: 34),
          if (label != null) ...[
            const SizedBox(height: 6),
            Text(label!, style: AppTextStyles.micro),
          ],
        ],
      ),
    );
  }
}
