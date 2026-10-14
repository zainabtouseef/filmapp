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
