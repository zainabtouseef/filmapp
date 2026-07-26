class MeetingParticipant {
  final String publicId;
  final String displayName;

  const MeetingParticipant({required this.publicId, required this.displayName});

  factory MeetingParticipant.fromJson(Map<String, dynamic> json) {
    return MeetingParticipant(
      publicId: json['public_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class MeetingRound {
  final String publicId;
  final int roundNumber;
  final MeetingParticipant proposedBy;
  final String? meetingKind;
  final DateTime meetingAt;
  final String? location;
  final String? onlineUrl;
  final String? instructions;
  final String? contact;
  final String? message;
  final String status;
  final String? declineReason;
  final MeetingParticipant? respondedBy;
  final DateTime? respondedAt;
  final DateTime createdAt;

  const MeetingRound({
    required this.publicId,
    required this.roundNumber,
    required this.proposedBy,
    required this.meetingKind,
    required this.meetingAt,
    required this.location,
    required this.onlineUrl,
    required this.instructions,
    required this.contact,
    required this.message,
    required this.status,
    required this.declineReason,
    required this.respondedBy,
    required this.respondedAt,
    required this.createdAt,
  });

  bool get isPending => status == 'pending';

  factory MeetingRound.fromJson(Map<String, dynamic> json) {
    final respondedBy = json['responded_by'] as Map<String, dynamic>?;
    return MeetingRound(
      publicId: json['public_id'] as String? ?? '',
      roundNumber: json['round_number'] as int? ?? 1,
      proposedBy: MeetingParticipant.fromJson(
        json['proposed_by'] as Map<String, dynamic>? ?? const {},
      ),
      meetingKind: json['meeting_kind'] as String?,
      meetingAt: DateTime.tryParse(json['meeting_at'] as String? ?? '') ??
          DateTime.now(),
      location: json['location'] as String?,
      onlineUrl: json['online_url'] as String?,
      instructions: json['instructions'] as String?,
      contact: json['contact'] as String?,
      message: json['message'] as String?,
      status: json['status'] as String? ?? 'pending',
      declineReason: json['decline_reason'] as String?,
      respondedBy:
          respondedBy == null ? null : MeetingParticipant.fromJson(respondedBy),
      respondedAt: json['responded_at'] == null
          ? null
          : DateTime.tryParse(json['responded_at'] as String),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }
}

class MeetingThread {
  final String publicId;
  final String status;
  final DateTime? lockedAt;
  final MeetingRound? currentRound;
  final List<MeetingRound> rounds;

  const MeetingThread({
    required this.publicId,
    required this.status,
    required this.lockedAt,
    required this.currentRound,
    required this.rounds,
  });

  bool get isAccepted => status == 'accepted';

  factory MeetingThread.fromJson(Map<String, dynamic> json) {
    final currentRound = json['current_round'] as Map<String, dynamic>?;
    return MeetingThread(
      publicId: json['public_id'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      lockedAt: json['locked_at'] == null
          ? null
          : DateTime.tryParse(json['locked_at'] as String),
      currentRound:
          currentRound == null ? null : MeetingRound.fromJson(currentRound),
      rounds: (json['rounds'] as List<dynamic>? ?? const [])
          .map((item) => MeetingRound.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  static MeetingThread? fromJsonOrNull(Map<String, dynamic>? json) {
    return json == null ? null : MeetingThread.fromJson(json);
  }
}
