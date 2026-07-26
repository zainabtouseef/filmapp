import '../casting/casting_models.dart' show CastingRoleProject;
import '../scheduling/meeting_models.dart';
import '../verification/verification_models.dart';

class OpportunityRole {
  final String publicId;
  final String category;
  final CastingRoleProject project;
  final String title;
  final String? summary;
  final String visibility;
  final int quantity;
  final List<String> requiredDocuments;
  final int? budgetMinMinor;
  final int? budgetMaxMinor;
  final String currency;
  final DateTime? startDate;
  final DateTime? endDate;
  final String status;
  final int applicationCount;
  final bool saved;
  final String? applicationId;
  final String? applicationStatus;
  final DateTime createdAt;

  const OpportunityRole({
    required this.publicId,
    required this.category,
    required this.project,
    required this.title,
    required this.summary,
    required this.visibility,
    required this.quantity,
    required this.requiredDocuments,
    required this.budgetMinMinor,
    required this.budgetMaxMinor,
    required this.currency,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.applicationCount,
    required this.saved,
    required this.applicationId,
    required this.applicationStatus,
    required this.createdAt,
  });

  bool get isVerifiedOnly => visibility == 'verified_only';

  String get budgetLabel {
    if (budgetMinMinor == null && budgetMaxMinor == null) return 'Rate on request';
    final min = budgetMinMinor == null ? null : (budgetMinMinor! / 100).round();
    final max = budgetMaxMinor == null ? null : (budgetMaxMinor! / 100).round();
    if (min != null && max != null) return '$currency $min - $max';
    return '$currency ${min ?? max}';
  }

  factory OpportunityRole.fromJson(Map<String, dynamic> json) {
    return OpportunityRole(
      publicId: json['public_id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      project: CastingRoleProject.fromJson(
        json['project'] as Map<String, dynamic>? ?? const {},
      ),
      title: json['title'] as String? ?? 'Untitled opportunity',
      summary: json['summary'] as String?,
      visibility: json['visibility'] as String? ?? 'all',
      quantity: json['quantity'] as int? ?? 1,
      requiredDocuments: (json['required_documents'] as List<dynamic>? ?? const [])
          .map((item) => item.toString())
          .toList(),
      budgetMinMinor: json['budget_min_minor'] as int?,
      budgetMaxMinor: json['budget_max_minor'] as int?,
      currency: json['currency'] as String? ?? 'PKR',
      startDate: json['start_date'] == null
          ? null
          : DateTime.tryParse(json['start_date'] as String),
      endDate: json['end_date'] == null
          ? null
          : DateTime.tryParse(json['end_date'] as String),
      status: json['status'] as String? ?? 'open',
      applicationCount: json['application_count'] as int? ?? 0,
      saved: json['saved'] as bool? ?? false,
      applicationId: json['application_id'] as String?,
      applicationStatus: json['application_status'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OpportunityRolePage {
  final List<OpportunityRole> roles;
  final int page;
  final int perPage;
  final int total;

  const OpportunityRolePage({
    required this.roles,
    required this.page,
    required this.perPage,
    required this.total,
  });
}

class OpportunityStatusEvent {
  final String? fromStatus;
  final String toStatus;
  final String? note;
  final DateTime createdAt;

  const OpportunityStatusEvent({
    required this.fromStatus,
    required this.toStatus,
    required this.note,
    required this.createdAt,
  });

  factory OpportunityStatusEvent.fromJson(Map<String, dynamic> json) {
    return OpportunityStatusEvent(
      fromStatus: json['from_status'] as String?,
      toStatus: json['to_status'] as String? ?? 'submitted',
      note: json['note'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class OpportunityApplicant {
  final String publicId;
  final String displayName;

  const OpportunityApplicant({
    required this.publicId,
    required this.displayName,
  });

  factory OpportunityApplicant.fromJson(Map<String, dynamic> json) {
    return OpportunityApplicant(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? 'Applicant',
    );
  }
}

class OpportunityMeetingSnapshot {
  final DateTime? at;
  final String? location;
  final String? onlineUrl;
  final String? instructions;
  final String? contact;
  final DateTime? confirmedAt;

  const OpportunityMeetingSnapshot({
    required this.at,
    required this.location,
    required this.onlineUrl,
    required this.instructions,
    required this.contact,
    required this.confirmedAt,
  });

  factory OpportunityMeetingSnapshot.fromJson(Map<String, dynamic> json) {
    return OpportunityMeetingSnapshot(
      at: json['at'] == null ? null : DateTime.tryParse(json['at'] as String),
      location: json['location'] as String?,
      onlineUrl: json['online_url'] as String?,
      instructions: json['instructions'] as String?,
      contact: json['contact'] as String?,
      confirmedAt: json['confirmed_at'] == null
          ? null
          : DateTime.tryParse(json['confirmed_at'] as String),
    );
  }
}

class OpportunityApplication {
  final String publicId;
  final OpportunityRole role;
  final OpportunityApplicant applicant;
  final String status;
  final String? coverNote;
  final List<UploadedFile?> attachmentFiles;
  final String? rejectionReason;
  final DateTime? submittedAt;
  final DateTime? withdrawnAt;
  final OpportunityMeetingSnapshot? meeting;
  final MeetingThread? meetingThread;
  final List<OpportunityStatusEvent> statusEvents;

  const OpportunityApplication({
    required this.publicId,
    required this.role,
    required this.applicant,
    required this.status,
    required this.coverNote,
    required this.attachmentFiles,
    required this.rejectionReason,
    required this.submittedAt,
    required this.withdrawnAt,
    required this.meeting,
    required this.meetingThread,
    required this.statusEvents,
  });

  String get statusLabel => status.replaceAll('_', ' ');

  factory OpportunityApplication.fromJson(Map<String, dynamic> json) {
    final meeting = json['meeting'] as Map<String, dynamic>?;
    return OpportunityApplication(
      publicId: json['public_id'] as String? ?? '',
      role: OpportunityRole.fromJson(
        json['role'] as Map<String, dynamic>? ?? const {},
      ),
      applicant: OpportunityApplicant.fromJson(
        json['applicant'] as Map<String, dynamic>? ?? const {},
      ),
      status: json['status'] as String? ?? 'draft',
      coverNote: json['cover_note'] as String?,
      attachmentFiles: (json['attachment_files'] as List<dynamic>? ?? const [])
          .map(
            (item) => item == null
                ? null
                : UploadedFile.fromJson(item as Map<String, dynamic>),
          )
          .toList(),
      rejectionReason: json['rejection_reason'] as String?,
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.tryParse(json['submitted_at'] as String),
      withdrawnAt: json['withdrawn_at'] == null
          ? null
          : DateTime.tryParse(json['withdrawn_at'] as String),
      meeting: meeting == null
          ? null
          : OpportunityMeetingSnapshot.fromJson(meeting),
      meetingThread: MeetingThread.fromJsonOrNull(
        json['meeting_thread'] as Map<String, dynamic>?,
      ),
      statusEvents: (json['status_events'] as List<dynamic>? ?? const [])
          .map((item) =>
              OpportunityStatusEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}
