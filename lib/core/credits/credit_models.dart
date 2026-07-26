import '../verification/verification_models.dart';

class CreditEntry {
  final String publicId;
  final String profileType;
  final String profileId;
  final String title;
  final String productionName;
  final String? roleLabel;
  final int? year;
  final String? description;
  final UploadedFile? coverFile;
  final int sortOrder;
  final DateTime createdAt;

  const CreditEntry({
    required this.publicId,
    required this.profileType,
    required this.profileId,
    required this.title,
    required this.productionName,
    required this.roleLabel,
    required this.year,
    required this.description,
    required this.coverFile,
    required this.sortOrder,
    required this.createdAt,
  });

  factory CreditEntry.fromJson(Map<String, dynamic> json) {
    final coverFile = json['cover_file'] as Map<String, dynamic>?;
    return CreditEntry(
      publicId: json['public_id'] as String? ?? '',
      profileType: json['profile_type'] as String? ?? '',
      profileId: json['profile_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      productionName: json['production_name'] as String? ?? '',
      roleLabel: json['role_label'] as String?,
      year: json['year'] as int?,
      description: json['description'] as String?,
      coverFile: coverFile == null ? null : UploadedFile.fromJson(coverFile),
      sortOrder: json['sort_order'] as int? ?? 100,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}
