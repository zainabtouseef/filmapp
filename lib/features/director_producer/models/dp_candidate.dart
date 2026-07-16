class DpCandidate {
  final String id;
  final String name;
  final String category;
  final String city;
  final String rateRange;
  final double rating;
  final bool verified;
  final bool available;
  final List<String> skills;
  final String avatarLabel;
  final String notes;

  const DpCandidate({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.rateRange,
    required this.rating,
    required this.verified,
    required this.available,
    required this.skills,
    required this.avatarLabel,
    required this.notes,
  });
}
