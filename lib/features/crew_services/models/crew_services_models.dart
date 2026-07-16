import 'package:flutter/material.dart';

enum CrewBookingStatus {
  requestReceived,
  underNegotiation,
  contractPending,
  paymentPending,
  secured,
  inProgress,
  closed,
  rejected,
  disputed,
}

enum CrewAvailabilityStatus { available, unavailable, tentative, booked }

enum CrewTone { gold, blue, green, purple, danger, neutral }

class CrewProfile {
  final String id;
  final String name;
  final String service;
  final String city;
  final String coverage;
  final String ownedKit;
  final String experience;
  final int dayRate;
  final String imageUrl;
  final double rating;

  const CrewProfile({
    required this.id,
    required this.name,
    required this.service,
    required this.city,
    required this.coverage,
    required this.ownedKit,
    required this.experience,
    required this.dayRate,
    required this.imageUrl,
    required this.rating,
  });
}

class CrewMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final CrewTone tone;
  final String route;

  const CrewMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class CrewTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final CrewTone tone;

  const CrewTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class CrewCredit {
  final String id;
  final String title;
  final String category;
  final String role;
  final String year;
  final String imageUrl;
  final bool featured;

  const CrewCredit({
    required this.id,
    required this.title,
    required this.category,
    required this.role,
    required this.year,
    required this.imageUrl,
    required this.featured,
  });

  CrewCredit copyWith({bool? featured}) {
    return CrewCredit(
      id: id,
      title: title,
      category: category,
      role: role,
      year: year,
      imageUrl: imageUrl,
      featured: featured ?? this.featured,
    );
  }
}

class CrewRequest {
  final String id;
  final String project;
  final String producer;
  final String dates;
  final String city;
  final String budget;
  final String requirement;
  final CrewBookingStatus status;
  final String imageUrl;

  const CrewRequest({
    required this.id,
    required this.project,
    required this.producer,
    required this.dates,
    required this.city,
    required this.budget,
    required this.requirement,
    required this.status,
    required this.imageUrl,
  });
}

class CrewLedgerItem {
  final String id;
  final String label;
  final String amount;
  final String dueDate;
  final CrewBookingStatus status;

  const CrewLedgerItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}

class CrewReview {
  final String id;
  final String project;
  final String director;
  final double rating;
  final String note;
  final CrewBookingStatus status;

  const CrewReview({
    required this.id,
    required this.project,
    required this.director,
    required this.rating,
    required this.note,
    required this.status,
  });
}
