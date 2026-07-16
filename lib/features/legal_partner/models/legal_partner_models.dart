import 'package:flutter/material.dart';

enum LegalStatus {
  queued,
  urgent,
  reviewing,
  clarification,
  correctionRequested,
  approved,
  escalated,
  templatePending,
  addendumPending,
  completed,
  billed,
  blocked,
}

enum LegalTone { gold, blue, green, purple, danger, neutral }

class LegalMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final LegalTone tone;
  final String route;

  const LegalMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class LegalTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final LegalTone tone;

  const LegalTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class LegalReviewRequest {
  final String id;
  final String title;
  final String owner;
  final String counterparty;
  final String contractType;
  final String sla;
  final String assignedLawyer;
  final String risk;
  final LegalStatus status;
  final String imageUrl;

  const LegalReviewRequest({
    required this.id,
    required this.title,
    required this.owner,
    required this.counterparty,
    required this.contractType,
    required this.sla,
    required this.assignedLawyer,
    required this.risk,
    required this.status,
    required this.imageUrl,
  });
}

class LegalClauseRisk {
  final String id;
  final String clause;
  final String issue;
  final String recommendation;
  final LegalStatus status;

  const LegalClauseRisk({
    required this.id,
    required this.clause,
    required this.issue,
    required this.recommendation,
    required this.status,
  });
}

class LegalTemplateChange {
  final String id;
  final String template;
  final String clause;
  final String proposedChange;
  final String reason;
  final LegalStatus status;

  const LegalTemplateChange({
    required this.id,
    required this.template,
    required this.clause,
    required this.proposedChange,
    required this.reason,
    required this.status,
  });
}

class LegalAddendumItem {
  final String id;
  final String title;
  final String sourceDecision;
  final String affectedContract;
  final String dueDate;
  final LegalStatus status;
  final String imageUrl;

  const LegalAddendumItem({
    required this.id,
    required this.title,
    required this.sourceDecision,
    required this.affectedContract,
    required this.dueDate,
    required this.status,
    required this.imageUrl,
  });
}

class LegalBillingRecord {
  final String id;
  final String matter;
  final String client;
  final String turnaround;
  final String invoice;
  final String notes;
  final LegalStatus status;

  const LegalBillingRecord({
    required this.id,
    required this.matter,
    required this.client,
    required this.turnaround,
    required this.invoice,
    required this.notes,
    required this.status,
  });
}
