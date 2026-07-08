import 'package:flutter/material.dart';

enum AdminRiskTone { low, medium, high, critical }

enum AdminDecisionTone { neutral, info, warning, success, danger }

class AdminKpi {
  final String title;
  final String value;
  final String trend;
  final String sla;
  final IconData icon;
  final String route;
  final AdminDecisionTone tone;

  const AdminKpi({
    required this.title,
    required this.value,
    required this.trend,
    required this.sla,
    required this.icon,
    required this.route,
    required this.tone,
  });
}

class AdminFeedItem {
  final String title;
  final String category;
  final String age;
  final String assignedTo;
  final String priority;
  final String route;
  final AdminRiskTone risk;

  const AdminFeedItem({
    required this.title,
    required this.category,
    required this.age,
    required this.assignedTo,
    required this.priority,
    required this.route,
    required this.risk,
  });
}

class KycSubmission {
  final String name;
  final String role;
  final String city;
  final String docs;
  final String age;
  final String risk;
  final String assignedTo;
  final String status;

  const KycSubmission({
    required this.name,
    required this.role,
    required this.city,
    required this.docs,
    required this.age,
    required this.risk,
    required this.assignedTo,
    required this.status,
  });
}

class AdminContentItem {
  final String title;
  final String user;
  final String role;
  final String type;
  final String time;
  final String visibility;
  final String watermark;
  final int reports;
  final String risk;

  const AdminContentItem({
    required this.title,
    required this.user,
    required this.role,
    required this.type,
    required this.time,
    required this.visibility,
    required this.watermark,
    required this.reports,
    required this.risk,
  });
}

class AdminListing {
  final String title;
  final String owner;
  final String city;
  final String category;
  final String price;
  final String deposit;
  final String date;
  final String visibility;
  final String status;

  const AdminListing({
    required this.title,
    required this.owner,
    required this.city,
    required this.category,
    required this.price,
    required this.deposit,
    required this.date,
    required this.visibility,
    required this.status,
  });
}

class AdminBooking {
  final String id;
  final String project;
  final String category;
  final String parties;
  final String city;
  final String value;
  final String status;
  final String activity;
  final String risk;

  const AdminBooking({
    required this.id,
    required this.project,
    required this.category,
    required this.parties,
    required this.city,
    required this.value,
    required this.status,
    required this.activity,
    required this.risk,
  });
}

class AdminPaymentProof {
  final String bookingId;
  final String contractId;
  final String payer;
  final String payee;
  final String milestone;
  final int expectedAmount;
  final int claimedAmount;
  final String method;
  final String risk;
  final String age;

  const AdminPaymentProof({
    required this.bookingId,
    required this.contractId,
    required this.payer,
    required this.payee,
    required this.milestone,
    required this.expectedAmount,
    required this.claimedAmount,
    required this.method,
    required this.risk,
    required this.age,
  });
}

class AdminDispute {
  final String caseId;
  final String type;
  final String parties;
  final String bookingId;
  final String value;
  final String age;
  final String assignedTo;
  final String status;
  final String severity;

  const AdminDispute({
    required this.caseId,
    required this.type,
    required this.parties,
    required this.bookingId,
    required this.value,
    required this.age,
    required this.assignedTo,
    required this.status,
    required this.severity,
  });
}

class AdminUserRecord {
  final String name;
  final String roles;
  final String city;
  final String verification;
  final String trust;
  final int bookings;
  final int disputes;
  final String deviceRisk;
  final String status;

  const AdminUserRecord({
    required this.name,
    required this.roles,
    required this.city,
    required this.verification,
    required this.trust,
    required this.bookings,
    required this.disputes,
    required this.deviceRisk,
    required this.status,
  });
}

class AdminTicket {
  final String id;
  final String source;
  final String user;
  final String category;
  final String priority;
  final String lastMessage;
  final String age;
  final String assignedTo;
  final String status;

  const AdminTicket({
    required this.id,
    required this.source,
    required this.user,
    required this.category,
    required this.priority,
    required this.lastMessage,
    required this.age,
    required this.assignedTo,
    required this.status,
  });
}

class AdminAuditEvent {
  final String timestamp;
  final String type;
  final String actor;
  final String affectedUser;
  final String entity;
  final String device;
  final String risk;
  final String description;
  final String route;

  const AdminAuditEvent({
    required this.timestamp,
    required this.type,
    required this.actor,
    required this.affectedUser,
    required this.entity,
    required this.device,
    required this.risk,
    required this.description,
    required this.route,
  });
}
