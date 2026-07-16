import 'package:flutter/material.dart';

enum BrandStatus {
  draft,
  active,
  pending,
  reviewing,
  shortlisted,
  negotiation,
  approved,
  revision,
  delivered,
  paymentPending,
  verified,
  closed,
  disputed,
}

enum BrandTone { gold, blue, green, purple, danger, neutral }

class BrandMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final BrandTone tone;
  final String route;

  const BrandMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class BrandTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final BrandTone tone;

  const BrandTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class BrandProfile {
  final String id;
  final String name;
  final String category;
  final String representative;
  final String billing;
  final String trustStatus;
  final String imageUrl;
  final String description;

  const BrandProfile({
    required this.id,
    required this.name,
    required this.category,
    required this.representative,
    required this.billing,
    required this.trustStatus,
    required this.imageUrl,
    required this.description,
  });
}

class BrandOpportunity {
  final String id;
  final String title;
  final String category;
  final String budget;
  final String usage;
  final String eligibility;
  final String deliverables;
  final String dueDate;
  final BrandStatus status;
  final String imageUrl;

  const BrandOpportunity({
    required this.id,
    required this.title,
    required this.category,
    required this.budget,
    required this.usage,
    required this.eligibility,
    required this.deliverables,
    required this.dueDate,
    required this.status,
    required this.imageUrl,
  });
}

class BrandApplication {
  final String id;
  final String applicant;
  final String type;
  final String proposal;
  final String audience;
  final String budgetAsk;
  final BrandStatus status;
  final String imageUrl;

  const BrandApplication({
    required this.id,
    required this.applicant,
    required this.type,
    required this.proposal,
    required this.audience,
    required this.budgetAsk,
    required this.status,
    required this.imageUrl,
  });
}

class BrandTerm {
  final String id;
  final String applicant;
  final String scope;
  final String exclusivity;
  final String approvalRights;
  final String paymentSchedule;
  final BrandStatus status;

  const BrandTerm({
    required this.id,
    required this.applicant,
    required this.scope,
    required this.exclusivity,
    required this.approvalRights,
    required this.paymentSchedule,
    required this.status,
  });
}

class BrandDeliverable {
  final String id;
  final String label;
  final String owner;
  final String dueDate;
  final String proof;
  final BrandStatus status;
  final String imageUrl;

  const BrandDeliverable({
    required this.id,
    required this.label,
    required this.owner,
    required this.dueDate,
    required this.proof,
    required this.status,
    required this.imageUrl,
  });
}

class BrandPaymentItem {
  final String id;
  final String label;
  final String payer;
  final String payee;
  final String amount;
  final String dueDate;
  final BrandStatus status;

  const BrandPaymentItem({
    required this.id,
    required this.label,
    required this.payer,
    required this.payee,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}
