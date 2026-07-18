class ContractUser {
  final String publicId;
  final String displayName;

  const ContractUser({required this.publicId, required this.displayName});

  factory ContractUser.fromJson(Map<String, dynamic>? json) {
    return ContractUser(
      publicId: json?['public_id'] as String? ?? '',
      displayName: json?['display_name'] as String? ?? 'Unknown user',
    );
  }
}

class ContractTemplateClause {
  final String clauseKey;
  final String title;
  final String bodyText;
  final int sortOrder;
  final bool required;
  final bool editable;

  const ContractTemplateClause({
    required this.clauseKey,
    required this.title,
    required this.bodyText,
    required this.sortOrder,
    required this.required,
    required this.editable,
  });

  factory ContractTemplateClause.fromJson(Map<String, dynamic> json) {
    return ContractTemplateClause(
      clauseKey: json['clause_key'] as String? ?? '',
      title: json['title'] as String? ?? 'Clause',
      bodyText: json['body_text'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      required: json['required'] as bool? ?? true,
      editable: json['editable'] as bool? ?? false,
    );
  }
}

class ContractTemplate {
  final String publicId;
  final String name;
  final String category;
  final String jurisdiction;
  final int versionNumber;
  final String status;
  final DateTime? publishedAt;
  final List<ContractTemplateClause> clauses;

  const ContractTemplate({
    required this.publicId,
    required this.name,
    required this.category,
    required this.jurisdiction,
    required this.versionNumber,
    required this.status,
    required this.publishedAt,
    required this.clauses,
  });

  factory ContractTemplate.fromJson(Map<String, dynamic> json) {
    return ContractTemplate(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Contract template',
      category: json['category'] as String? ?? 'talent',
      jurisdiction: json['jurisdiction'] as String? ?? 'PK',
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'published',
      publishedAt: DateTime.tryParse(json['published_at'] as String? ?? ''),
      clauses: (json['clauses'] as List<dynamic>? ?? const [])
          .map((item) =>
              ContractTemplateClause.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }
}

class ContractParty {
  final String publicId;
  final ContractUser user;
  final String partyRole;
  final int signingOrder;
  final String status;

  const ContractParty({
    required this.publicId,
    required this.user,
    required this.partyRole,
    required this.signingOrder,
    required this.status,
  });

  factory ContractParty.fromJson(Map<String, dynamic> json) {
    return ContractParty(
      publicId: json['public_id'] as String? ?? '',
      user: ContractUser.fromJson(json['user'] as Map<String, dynamic>?),
      partyRole: json['party_role'] as String? ?? 'party',
      signingOrder: (json['signing_order'] as num?)?.toInt() ?? 1,
      status: json['status'] as String? ?? 'pending',
    );
  }
}

class ContractClause {
  final String clauseKey;
  final String title;
  final String bodyText;
  final int sortOrder;
  final bool highlighted;

  const ContractClause({
    required this.clauseKey,
    required this.title,
    required this.bodyText,
    required this.sortOrder,
    required this.highlighted,
  });

  factory ContractClause.fromJson(Map<String, dynamic> json) {
    return ContractClause(
      clauseKey: json['clause_key'] as String? ?? '',
      title: json['title'] as String? ?? 'Clause',
      bodyText: json['body_text'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      highlighted: json['highlighted'] as bool? ?? false,
    );
  }
}

class ContractSignature {
  final String partyId;
  final ContractUser signer;
  final String signatureHash;
  final DateTime? signedAt;

  const ContractSignature({
    required this.partyId,
    required this.signer,
    required this.signatureHash,
    required this.signedAt,
  });

  factory ContractSignature.fromJson(Map<String, dynamic> json) {
    return ContractSignature(
      partyId: json['party_id'] as String? ?? '',
      signer: ContractUser.fromJson(json['signer'] as Map<String, dynamic>?),
      signatureHash: json['signature_hash'] as String? ?? '',
      signedAt: DateTime.tryParse(json['signed_at'] as String? ?? ''),
    );
  }
}

class ContractAddendum {
  final String publicId;
  final ContractUser requestedBy;
  final String reason;
  final String content;
  final String status;
  final DateTime? createdAt;

  const ContractAddendum({
    required this.publicId,
    required this.requestedBy,
    required this.reason,
    required this.content,
    required this.status,
    required this.createdAt,
  });

  factory ContractAddendum.fromJson(Map<String, dynamic> json) {
    return ContractAddendum(
      publicId: json['public_id'] as String? ?? '',
      requestedBy:
          ContractUser.fromJson(json['requested_by'] as Map<String, dynamic>?),
      reason: json['reason'] as String? ?? '',
      content: json['content'] as String? ?? '',
      status: json['status'] as String? ?? 'review_requested',
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class CineContract {
  final String publicId;
  final String bookingId;
  final String projectId;
  final ContractTemplate template;
  final int versionNumber;
  final String title;
  final String status;
  final String? effectiveDate;
  final int valueMinor;
  final String currency;
  final double signatureProgress;
  final List<ContractParty> parties;
  final List<ContractClause> clauses;
  final List<ContractSignature> signatures;
  final List<ContractAddendum> addendums;
  final Map<String, dynamic> contentSnapshot;

  const CineContract({
    required this.publicId,
    required this.bookingId,
    required this.projectId,
    required this.template,
    required this.versionNumber,
    required this.title,
    required this.status,
    required this.effectiveDate,
    required this.valueMinor,
    required this.currency,
    required this.signatureProgress,
    required this.parties,
    required this.clauses,
    required this.signatures,
    required this.addendums,
    required this.contentSnapshot,
  });

  factory CineContract.fromJson(Map<String, dynamic> json) {
    return CineContract(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      template:
          ContractTemplate.fromJson(json['template'] as Map<String, dynamic>),
      versionNumber: (json['version_number'] as num?)?.toInt() ?? 1,
      title: json['title'] as String? ?? 'Contract',
      status: json['status'] as String? ?? 'pending_signature',
      effectiveDate: json['effective_date'] as String?,
      valueMinor: (json['value_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      signatureProgress:
          double.tryParse('${json['signature_progress'] ?? '0'}') ?? 0,
      parties: (json['parties'] as List<dynamic>? ?? const [])
          .map((item) => ContractParty.fromJson(item as Map<String, dynamic>))
          .toList(),
      clauses: (json['clauses'] as List<dynamic>? ?? const [])
          .map((item) => ContractClause.fromJson(item as Map<String, dynamic>))
          .toList()
        ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder)),
      signatures: (json['signatures'] as List<dynamic>? ?? const [])
          .map((item) =>
              ContractSignature.fromJson(item as Map<String, dynamic>))
          .toList(),
      addendums: (json['addendums'] as List<dynamic>? ?? const [])
          .map(
              (item) => ContractAddendum.fromJson(item as Map<String, dynamic>))
          .toList(),
      contentSnapshot:
          json['content_snapshot'] as Map<String, dynamic>? ?? const {},
    );
  }

  String get displayValue => '${_money(valueMinor)} $currency';

  String get statusLabel => status.replaceAll('_', ' ').toUpperCase();

  bool get isSigned => status == 'signed';

  String get signatureProgressPercent =>
      '${(signatureProgress * 100).round()}% signed';

  String get counterpartySummary {
    if (parties.isEmpty) return 'Contract parties pending';
    return parties
        .map((party) => '${party.partyRole}: ${party.user.displayName}')
        .join(' • ');
  }
}

class LegalClauseRiskDto {
  final String riskLevel;
  final String issue;
  final String recommendation;
  final String? contractClauseKey;
  final String status;

  const LegalClauseRiskDto({
    required this.riskLevel,
    required this.issue,
    required this.recommendation,
    required this.contractClauseKey,
    required this.status,
  });

  factory LegalClauseRiskDto.fromJson(Map<String, dynamic> json) {
    return LegalClauseRiskDto(
      riskLevel: json['risk_level'] as String? ?? 'medium',
      issue: json['issue'] as String? ?? 'Review requested',
      recommendation: json['recommendation'] as String? ?? '',
      contractClauseKey: json['contract_clause_key'] as String?,
      status: json['status'] as String? ?? 'open',
    );
  }
}

class LegalReviewDto {
  final String publicId;
  final String? contractId;
  final String? templateId;
  final String? addendumId;
  final ContractUser requestedBy;
  final ContractUser? assignedLegal;
  final String contractType;
  final String risk;
  final String status;
  final DateTime? slaDueAt;
  final String? decisionNotes;
  final List<LegalClauseRiskDto> risks;
  final DateTime? createdAt;

  const LegalReviewDto({
    required this.publicId,
    required this.contractId,
    required this.templateId,
    required this.addendumId,
    required this.requestedBy,
    required this.assignedLegal,
    required this.contractType,
    required this.risk,
    required this.status,
    required this.slaDueAt,
    required this.decisionNotes,
    required this.risks,
    required this.createdAt,
  });

  factory LegalReviewDto.fromJson(Map<String, dynamic> json) {
    final assigned = json['assigned_legal'] as Map<String, dynamic>?;
    return LegalReviewDto(
      publicId: json['public_id'] as String? ?? '',
      contractId: json['contract_id'] as String?,
      templateId: json['template_id'] as String?,
      addendumId: json['addendum_id'] as String?,
      requestedBy:
          ContractUser.fromJson(json['requested_by'] as Map<String, dynamic>?),
      assignedLegal: assigned == null ? null : ContractUser.fromJson(assigned),
      contractType: json['contract_type'] as String? ?? 'contract',
      risk: json['risk'] as String? ?? 'medium',
      status: json['status'] as String? ?? 'requested',
      slaDueAt: DateTime.tryParse(json['sla_due_at'] as String? ?? ''),
      decisionNotes: json['decision_notes'] as String?,
      risks: (json['risks'] as List<dynamic>? ?? const [])
          .map((item) =>
              LegalClauseRiskDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }

  String get title => contractId ?? templateId ?? addendumId ?? publicId;
  String get slaLabel => slaDueAt == null ? 'No SLA' : _shortDate(slaDueAt!);
}

String _money(int minor) {
  final amount = minor / 100;
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return amount.toStringAsFixed(0);
}

String _shortDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
