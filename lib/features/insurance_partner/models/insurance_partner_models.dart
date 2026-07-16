import 'package:flutter/material.dart';

enum InsuranceStatus {
  active,
  expiring,
  pending,
  verified,
  highRisk,
  openClaim,
  investigating,
  evidenceNeeded,
  approved,
  rejected,
  safetyDue,
  completed,
  escalated,
  resolved,
  draft,
}

enum InsuranceTone { gold, blue, green, purple, danger, neutral }

class InsuranceMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final InsuranceTone tone;
  final String route;

  const InsuranceMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class InsuranceTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final InsuranceTone tone;

  const InsuranceTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class InsurancePolicy {
  final String id;
  final String project;
  final String booking;
  final String insuredParty;
  final String coverage;
  final String validity;
  final String document;
  final String risk;
  final InsuranceStatus status;
  final String imageUrl;

  const InsurancePolicy({
    required this.id,
    required this.project,
    required this.booking,
    required this.insuredParty,
    required this.coverage,
    required this.validity,
    required this.document,
    required this.risk,
    required this.status,
    required this.imageUrl,
  });
}

class InsuranceClaim {
  final String id;
  final String title;
  final String source;
  final String policyId;
  final String itemOrRoom;
  final String adjuster;
  final String due;
  final String estimate;
  final InsuranceStatus status;
  final String beforeImageUrl;
  final String afterImageUrl;

  const InsuranceClaim({
    required this.id,
    required this.title,
    required this.source,
    required this.policyId,
    required this.itemOrRoom,
    required this.adjuster,
    required this.due,
    required this.estimate,
    required this.status,
    required this.beforeImageUrl,
    required this.afterImageUrl,
  });
}

class InsuranceEvidence {
  final String id;
  final String label;
  final String detail;
  final bool mandatory;

  const InsuranceEvidence({
    required this.id,
    required this.label,
    required this.detail,
    this.mandatory = true,
  });
}

class InsuranceSafetyCheck {
  final String id;
  final String shoot;
  final String location;
  final String responsible;
  final String dueDate;
  final String permit;
  final String risk;
  final InsuranceStatus status;
  final String imageUrl;

  const InsuranceSafetyCheck({
    required this.id,
    required this.shoot,
    required this.location,
    required this.responsible,
    required this.dueDate,
    required this.permit,
    required this.risk,
    required this.status,
    required this.imageUrl,
  });
}

class InsuranceSafetyStep {
  final String id;
  final String label;
  final String detail;
  final bool mandatory;

  const InsuranceSafetyStep({
    required this.id,
    required this.label,
    required this.detail,
    this.mandatory = true,
  });
}

class InsuranceIncident {
  final String id;
  final String title;
  final String project;
  final String severity;
  final String date;
  final String parties;
  final String correctiveAction;
  final InsuranceStatus status;

  const InsuranceIncident({
    required this.id,
    required this.title,
    required this.project,
    required this.severity,
    required this.date,
    required this.parties,
    required this.correctiveAction,
    required this.status,
  });
}

class InsuranceChartPoint {
  final String label;
  final int value;
  final InsuranceTone tone;

  const InsuranceChartPoint({
    required this.label,
    required this.value,
    required this.tone,
  });
}
