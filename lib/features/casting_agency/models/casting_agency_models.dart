import 'package:flutter/material.dart';

enum AgencyStatus {
  active,
  pending,
  newRequest,
  reviewing,
  shortlisted,
  selfTapePending,
  selfTapeReceived,
  selected,
  rejected,
  booked,
  closed,
  paymentPending,
  paid,
  disputed,
}

enum AgencyTone { gold, blue, green, purple, danger, neutral }

class AgencyMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final AgencyTone tone;
  final String route;

  const AgencyMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class AgencyTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final AgencyTone tone;

  const AgencyTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class AgencyTalent {
  final String id;
  final String name;
  final String category;
  final String city;
  final String ageRange;
  final String availability;
  final String bookings;
  final String imageUrl;
  final bool linkedAccount;
  final AgencyStatus status;

  const AgencyTalent({
    required this.id,
    required this.name,
    required this.category,
    required this.city,
    required this.ageRange,
    required this.availability,
    required this.bookings,
    required this.imageUrl,
    required this.linkedAccount,
    required this.status,
  });
}

class AgencyAudition {
  final String id;
  final String project;
  final String director;
  final String role;
  final String dueDate;
  final String budget;
  final String city;
  final AgencyStatus status;
  final String imageUrl;

  const AgencyAudition({
    required this.id,
    required this.project,
    required this.director,
    required this.role,
    required this.dueDate,
    required this.budget,
    required this.city,
    required this.status,
    required this.imageUrl,
  });
}

class AgencyTape {
  final String id;
  final String talentId;
  final String talentName;
  final String project;
  final String duration;
  final String dueDate;
  final AgencyStatus status;
  final String imageUrl;
  final String transcript;

  const AgencyTape({
    required this.id,
    required this.talentId,
    required this.talentName,
    required this.project,
    required this.duration,
    required this.dueDate,
    required this.status,
    required this.imageUrl,
    required this.transcript,
  });
}

class AgencySelectionNote {
  final String id;
  final String talentId;
  final String talentName;
  final String project;
  final String note;
  final String directorFeedback;
  final int score;
  final AgencyStatus status;

  const AgencySelectionNote({
    required this.id,
    required this.talentId,
    required this.talentName,
    required this.project,
    required this.note,
    required this.directorFeedback,
    required this.score,
    required this.status,
  });
}

class AgencyCommissionItem {
  final String id;
  final String talentName;
  final String project;
  final String gross;
  final String commission;
  final String dueDate;
  final AgencyStatus status;

  const AgencyCommissionItem({
    required this.id,
    required this.talentName,
    required this.project,
    required this.gross,
    required this.commission,
    required this.dueDate,
    required this.status,
  });
}

class AgencyBookingRecord {
  final String id;
  final String talentName;
  final String project;
  final String value;
  final String commission;
  final String date;
  final AgencyStatus status;

  const AgencyBookingRecord({
    required this.id,
    required this.talentName,
    required this.project,
    required this.value,
    required this.commission,
    required this.date,
    required this.status,
  });
}
