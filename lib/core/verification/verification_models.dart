class UploadedFile {
  final String publicId;
  final String mimeType;
  final int sizeBytes;
  final String scanStatus;
  final String processingStatus;
  final String originalName;
  final String visibility;
  final String? downloadUrl;
  final String? publicUrl;

  const UploadedFile({
    required this.publicId,
    required this.mimeType,
    required this.sizeBytes,
    required this.scanStatus,
    required this.processingStatus,
    required this.originalName,
    required this.visibility,
    this.downloadUrl,
    this.publicUrl,
  });

  factory UploadedFile.fromJson(Map<String, dynamic> json) {
    return UploadedFile(
      publicId: json['public_id'] as String,
      mimeType: json['mime_type'] as String,
      sizeBytes: json['size_bytes'] as int,
      scanStatus: json['scan_status'] as String,
      processingStatus: json['processing_status'] as String,
      originalName: json['original_name'] as String,
      visibility: json['visibility'] as String? ?? 'authorized',
      downloadUrl: json['download_url'] as String?,
      publicUrl: json['public_url'] as String?,
    );
  }
}

class UploadTicket {
  final String id;
  final String method;
  final String uploadUrl;
  final int maxBytes;

  const UploadTicket({
    required this.id,
    required this.method,
    required this.uploadUrl,
    required this.maxBytes,
  });

  factory UploadTicket.fromJson(Map<String, dynamic> json) {
    return UploadTicket(
      id: json['upload_session_id'] as String,
      method: json['method'] as String,
      uploadUrl: json['upload_url'] as String,
      maxBytes: json['max_bytes'] as int,
    );
  }
}

class KycDocumentDraft {
  final String documentType;
  final String country;
  final String? fileId;

  const KycDocumentDraft({
    required this.documentType,
    this.country = 'PK',
    this.fileId,
  });

  Map<String, dynamic> toJson() {
    return {
      'document_type': documentType,
      'country': country,
      if (fileId != null) 'file_id': fileId,
    };
  }
}

class KycSubmission {
  final String publicId;
  final String status;
  final String riskLevel;
  final String roleName;
  final String applicantName;
  final String applicantEmail;
  final String? decisionReason;
  final List<UploadedFile> files;
  final List<String> documentTypes;

  const KycSubmission({
    required this.publicId,
    required this.status,
    required this.riskLevel,
    required this.roleName,
    required this.applicantName,
    required this.applicantEmail,
    this.decisionReason,
    this.files = const [],
    this.documentTypes = const [],
  });

  factory KycSubmission.fromJson(Map<String, dynamic> json) {
    final role = json['role'] as Map<String, dynamic>? ?? const {};
    final user = json['user'] as Map<String, dynamic>? ?? const {};
    final documents = json['documents'] as List<dynamic>? ?? const [];
    final typedDocuments =
        documents.map((item) => item as Map<String, dynamic>).toList();
    return KycSubmission(
      publicId: json['public_id'] as String,
      status: json['status'] as String,
      riskLevel: json['risk_level'] as String,
      roleName: role['name'] as String? ?? 'CineConnect role',
      applicantName: user['display_name'] as String? ?? 'CineConnect user',
      applicantEmail: user['email'] as String? ?? 'No email available',
      decisionReason: json['decision_reason'] as String?,
      files: typedDocuments
          .map((item) => item['file'])
          .whereType<Map<String, dynamic>>()
          .map(UploadedFile.fromJson)
          .toList(),
      documentTypes: typedDocuments
          .map((item) => item['document_type'] as String? ?? 'document')
          .toList(),
    );
  }
}
