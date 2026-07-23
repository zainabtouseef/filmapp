class ProfileCity {
  final String publicId;
  final String name;
  final String? province;
  final String timezone;

  const ProfileCity({
    required this.publicId,
    required this.name,
    required this.province,
    required this.timezone,
  });

  factory ProfileCity.fromJson(Map<String, dynamic> json) {
    return ProfileCity(
      publicId: json['public_id'] as String,
      name: json['name'] as String,
      province: json['province'] as String?,
      timezone: json['timezone'] as String? ?? 'Asia/Karachi',
    );
  }
}

class UserProfile {
  final String? bio;
  final ProfileCity? city;
  final String? websiteUrl;
  final String visibility;
  final double ratingAverage;
  final int reviewCount;

  const UserProfile({
    required this.bio,
    required this.city,
    required this.websiteUrl,
    required this.visibility,
    required this.ratingAverage,
    required this.reviewCount,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>?;
    return UserProfile(
      bio: json['bio'] as String?,
      city: city == null ? null : ProfileCity.fromJson(city),
      websiteUrl: json['website_url'] as String?,
      visibility: json['profile_visibility'] as String? ?? 'private',
      ratingAverage: (json['rating_average'] as num?)?.toDouble() ?? 0,
      reviewCount: json['review_count'] as int? ?? 0,
    );
  }
}

class TalentLanguage {
  final String language;
  final String proficiency;

  const TalentLanguage({
    required this.language,
    this.proficiency = 'conversational',
  });

  factory TalentLanguage.fromJson(Map<String, dynamic> json) {
    return TalentLanguage(
      language: json['language'] as String,
      proficiency: json['proficiency'] as String? ?? 'conversational',
    );
  }

  Map<String, String> toJson() {
    return {'language': language, 'proficiency': proficiency};
  }
}

class TalentProfile {
  final String? publicId;
  final String? screenName;
  final String? ageRange;
  final String? genderIdentity;
  final int? heightCm;
  final String? unionNote;
  final int? experienceYears;
  final String availabilityStatus;
  final int? dayRateMinor;
  final String currency;
  final List<TalentLanguage> languages;

  const TalentProfile({
    required this.publicId,
    required this.screenName,
    required this.ageRange,
    required this.genderIdentity,
    required this.heightCm,
    required this.unionNote,
    required this.experienceYears,
    required this.availabilityStatus,
    required this.dayRateMinor,
    required this.currency,
    required this.languages,
  });

  factory TalentProfile.fromJson(Map<String, dynamic>? json) {
    if (json == null) {
      return const TalentProfile(
        publicId: null,
        screenName: null,
        ageRange: null,
        genderIdentity: null,
        heightCm: null,
        unionNote: null,
        experienceYears: null,
        availabilityStatus: 'available',
        dayRateMinor: null,
        currency: 'PKR',
        languages: [],
      );
    }
    return TalentProfile(
      publicId: json['public_id'] as String?,
      screenName: json['screen_name'] as String?,
      ageRange: json['age_range'] as String?,
      genderIdentity: json['gender_identity'] as String?,
      heightCm: json['height_cm'] as int?,
      unionNote: json['union_note'] as String?,
      experienceYears: json['experience_years'] as int?,
      availabilityStatus: json['availability_status'] as String? ?? 'available',
      dayRateMinor: json['day_rate_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      languages: (json['languages'] as List<dynamic>? ?? const [])
          .map((item) => TalentLanguage.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
