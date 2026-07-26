import '../profile/profile_models.dart';
import '../scheduling/meeting_models.dart';
import '../verification/verification_models.dart';

class CastingRoleProject {
  final String publicId;
  final String title;
  final String projectType;
  final String? description;
  final ProfileCity? city;
  final UploadedFile? coverFile;
  final String ownerId;
  final String ownerName;

  const CastingRoleProject({
    required this.publicId,
    required this.title,
    required this.projectType,
    required this.description,
    required this.city,
    required this.coverFile,
    required this.ownerId,
    required this.ownerName,
  });

  factory CastingRoleProject.fromJson(Map<String, dynamic> json) {
    final city = json['city'] as Map<String, dynamic>?;
    final cover = json['cover_file'] as Map<String, dynamic>?;
    final owner = json['owner'] as Map<String, dynamic>? ?? const {};
    return CastingRoleProject(
      publicId: json['public_id'] as String? ?? '',
      title: json['title'] as String? ?? 'Untitled project',
      projectType: json['project_type'] as String? ?? 'production',
      description: json['description'] as String?,
      city: city == null ? null : ProfileCity.fromJson(city),
      coverFile: cover == null ? null : UploadedFile.fromJson(cover),
      ownerId: owner['public_id'] as String? ?? '',
      ownerName: owner['display_name'] as String? ?? 'Production team',
    );
  }
}

class CastingRoleSkill {
  final String publicId;
  final String name;
  final String category;
  final bool required;
  final String? minimumLevel;

  const CastingRoleSkill({
    required this.publicId,
    required this.name,
    required this.category,
    required this.required,
    required this.minimumLevel,
  });

  factory CastingRoleSkill.fromJson(Map<String, dynamic> json) {
    return CastingRoleSkill(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Skill',
      category: json['category'] as String? ?? 'acting',
      required: json['required'] as bool? ?? true,
      minimumLevel: json['minimum_level'] as String?,
    );
  }
}

class CastingRole {
  final String publicId;
  final CastingRoleProject project;
  final String title;
  final String? summary;
  final String? roleType;
  final String? workLocation;
  final String? auditionMode;
  final String? instructions;
  final List<String> eligibility;
  final List<String> castingQuestions;
  final DateTime? applicationDueAt;
  final UploadedFile? sidesFile;
  final String? contactName;
  final String? contactEmail;
  final DateTime? publishedAt;
  final int? budgetMinMinor;
  final int? budgetMaxMinor;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final List<CastingRoleSkill> skills;
  final int applicationCount;
  final bool saved;
  final String? applicationId;
  final String? applicationStatus;
  final String visibility;
  final int quantity;
  final List<String> requiredDocuments;

  const CastingRole({
    required this.publicId,
    required this.project,
    required this.title,
    required this.summary,
    required this.roleType,
    required this.workLocation,
    required this.auditionMode,
    required this.instructions,
    required this.eligibility,
    required this.castingQuestions,
    required this.applicationDueAt,
    required this.sidesFile,
    required this.contactName,
    required this.contactEmail,
    required this.publishedAt,
    required this.budgetMinMinor,
    required this.budgetMaxMinor,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.skills,
    required this.applicationCount,
    required this.saved,
    required this.applicationId,
    required this.applicationStatus,
    this.visibility = 'all',
    this.quantity = 1,
    this.requiredDocuments = const [],
  });

  factory CastingRole.fromJson(Map<String, dynamic> json) {
    final sides = json['sides_file'] as Map<String, dynamic>?;
    return CastingRole(
      publicId: json['public_id'] as String? ?? '',
      project: CastingRoleProject.fromJson(
        json['project'] as Map<String, dynamic>? ?? const {},
      ),
      title: json['title'] as String? ?? 'Untitled role',
      summary: json['summary'] as String?,
      roleType: json['role_type'] as String?,
      workLocation: json['work_location'] as String?,
      auditionMode: json['audition_mode'] as String?,
      instructions: json['instructions'] as String?,
      eligibility: (json['eligibility'] as List<dynamic>? ?? const [])
          .map((value) => value.toString())
          .toList(),
      castingQuestions:
          (json['casting_questions'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
      applicationDueAt: DateTime.tryParse(
        json['application_due_at'] as String? ?? '',
      ),
      sidesFile: sides == null ? null : UploadedFile.fromJson(sides),
      contactName: json['contact_name'] as String?,
      contactEmail: json['contact_email'] as String?,
      publishedAt: DateTime.tryParse(
        json['published_at'] as String? ?? '',
      ),
      budgetMinMinor: json['budget_min_minor'] as int?,
      budgetMaxMinor: json['budget_max_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      startDate: DateTime.tryParse(json['start_date'] as String? ?? ''),
      endDate: DateTime.tryParse(json['end_date'] as String? ?? ''),
      status: json['status'] as String? ?? 'open',
      skills: (json['skills'] as List<dynamic>? ?? const [])
          .map(
              (item) => CastingRoleSkill.fromJson(item as Map<String, dynamic>))
          .toList(),
      applicationCount: json['application_count'] as int? ?? 0,
      saved: json['saved'] as bool? ?? false,
      applicationId: json['application_id'] as String?,
      applicationStatus: json['application_status'] as String?,
      visibility: json['visibility'] as String? ?? 'all',
      quantity: json['quantity'] as int? ?? 1,
      requiredDocuments:
          (json['required_documents'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
    );
  }

  String get feeLabel {
    final minimum = budgetMinMinor == null ? null : budgetMinMinor! ~/ 100;
    final maximum = budgetMaxMinor == null ? null : budgetMaxMinor! ~/ 100;
    if (minimum != null && maximum != null) {
      return '$currency ${_compactMoney(minimum)}-${_compactMoney(maximum)}';
    }
    if (minimum != null) return 'From $currency ${_compactMoney(minimum)}';
    if (maximum != null) return 'Up to $currency ${_compactMoney(maximum)}';
    return 'Rate on request';
  }

  bool get acceptingApplications {
    final due = applicationDueAt;
    return status == 'open' && (due == null || due.isAfter(DateTime.now()));
  }

  bool get verifiedOnly => visibility == 'verified_only';
}

class CastingRolePage {
  final List<CastingRole> roles;
  final int page;
  final int perPage;
  final int total;

  const CastingRolePage({
    required this.roles,
    required this.page,
    required this.perPage,
    required this.total,
  });
}

class CastingApplicationEvent {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final String? changedBy;
  final DateTime? createdAt;

  const CastingApplicationEvent({
    required this.fromStatus,
    required this.toStatus,
    required this.note,
    required this.changedBy,
    required this.createdAt,
  });

  factory CastingApplicationEvent.fromJson(Map<String, dynamic> json) {
    final actor = json['changed_by'] as Map<String, dynamic>?;
    return CastingApplicationEvent(
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String? ?? 'submitted',
      note: json['note'] as String?,
      changedBy: actor?['display_name'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class CastingAudition {
  final DateTime? at;
  final DateTime? dueAt;
  final String? location;
  final String? onlineUrl;
  final String? instructions;
  final String? contact;
  final DateTime? confirmedAt;

  const CastingAudition({
    required this.at,
    required this.dueAt,
    required this.location,
    required this.onlineUrl,
    required this.instructions,
    required this.contact,
    required this.confirmedAt,
  });

  factory CastingAudition.fromJson(Map<String, dynamic> json) {
    return CastingAudition(
      at: DateTime.tryParse(json['at'] as String? ?? ''),
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
      location: json['location'] as String?,
      onlineUrl: json['online_url'] as String?,
      instructions: json['instructions'] as String?,
      contact: json['contact'] as String?,
      confirmedAt: DateTime.tryParse(
        json['confirmed_at'] as String? ?? '',
      ),
    );
  }
}

class CastingApplication {
  final String publicId;
  final CastingRole role;
  final String actorId;
  final String actorName;
  final String? actorAvatarUrl;
  final String talentProfileId;
  final String? marketplaceListingId;
  final String screenName;
  final String? conversationId;
  final String status;
  final String? coverNote;
  final Map<String, String> answers;
  final String? availabilityNote;
  final List<String> portfolioItemIds;
  final UploadedFile? selfTapeFile;
  final DateTime? submittedAt;
  final DateTime? viewedAt;
  final DateTime? withdrawnAt;
  final CastingAudition audition;
  final DateTime? callbackAt;
  final String? callbackDetails;
  final MeetingThread? meetingThread;
  final String? rejectionReason;
  final List<CastingApplicationEvent> statusEvents;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  const CastingApplication({
    required this.publicId,
    required this.role,
    required this.actorId,
    required this.actorName,
    required this.actorAvatarUrl,
    required this.talentProfileId,
    required this.marketplaceListingId,
    required this.screenName,
    required this.conversationId,
    required this.status,
    required this.coverNote,
    required this.answers,
    required this.availabilityNote,
    required this.portfolioItemIds,
    required this.selfTapeFile,
    required this.submittedAt,
    required this.viewedAt,
    required this.withdrawnAt,
    required this.audition,
    required this.callbackAt,
    required this.callbackDetails,
    required this.meetingThread,
    required this.rejectionReason,
    required this.statusEvents,
    required this.createdAt,
    required this.updatedAt,
  });

  factory CastingApplication.fromJson(Map<String, dynamic> json) {
    final actor = json['actor'] as Map<String, dynamic>? ?? const {};
    final talent = json['talent_profile'] as Map<String, dynamic>? ?? const {};
    final selfTape = json['self_tape_file'] as Map<String, dynamic>?;
    final callback = json['callback'] as Map<String, dynamic>? ?? const {};
    final rawAnswers = json['answers'] as Map<String, dynamic>? ?? const {};
    return CastingApplication(
      publicId: json['public_id'] as String? ?? '',
      role: CastingRole.fromJson(
        json['role'] as Map<String, dynamic>? ?? const {},
      ),
      actorId: actor['public_id'] as String? ?? '',
      actorName: actor['display_name'] as String? ?? 'Actor',
      actorAvatarUrl: actor['avatar_url'] as String?,
      talentProfileId: talent['public_id'] as String? ?? '',
      marketplaceListingId: talent['marketplace_listing_id'] as String?,
      screenName: talent['screen_name'] as String? ?? 'Actor',
      conversationId: json['conversation_id'] as String?,
      status: json['status'] as String? ?? 'draft',
      coverNote: json['cover_note'] as String?,
      answers: rawAnswers.map(
        (key, value) => MapEntry(key, value.toString()),
      ),
      availabilityNote: json['availability_note'] as String?,
      portfolioItemIds:
          (json['portfolio_item_ids'] as List<dynamic>? ?? const [])
              .map((value) => value.toString())
              .toList(),
      selfTapeFile: selfTape == null ? null : UploadedFile.fromJson(selfTape),
      submittedAt: DateTime.tryParse(json['submitted_at'] as String? ?? ''),
      viewedAt: DateTime.tryParse(json['viewed_at'] as String? ?? ''),
      withdrawnAt: DateTime.tryParse(json['withdrawn_at'] as String? ?? ''),
      audition: CastingAudition.fromJson(
        json['audition'] as Map<String, dynamic>? ?? const {},
      ),
      callbackAt: DateTime.tryParse(callback['at'] as String? ?? ''),
      callbackDetails: callback['details'] as String?,
      meetingThread: MeetingThread.fromJsonOrNull(
        json['meeting_thread'] as Map<String, dynamic>?,
      ),
      rejectionReason: json['rejection_reason'] as String?,
      statusEvents: (json['status_events'] as List<dynamic>? ?? const [])
          .map((item) => CastingApplicationEvent.fromJson(
                item as Map<String, dynamic>,
              ))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
      updatedAt: DateTime.tryParse(json['updated_at'] as String? ?? ''),
    );
  }

  bool get isAudition => const {
        'audition_requested',
        'self_tape_requested',
        'callback',
      }.contains(status);

  bool get canWithdraw =>
      !const {'selected', 'rejected', 'withdrawn'}.contains(status);

  String get statusLabel => _titleCase(status);
}

String _compactMoney(int value) {
  if (value >= 1000000) {
    final amount = value / 1000000;
    return '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}m';
  }
  if (value >= 1000) {
    final amount = value / 1000;
    return '${amount.toStringAsFixed(amount % 1 == 0 ? 0 : 1)}k';
  }
  return '$value';
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((word) => word.isNotEmpty)
      .map((word) => '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
}
