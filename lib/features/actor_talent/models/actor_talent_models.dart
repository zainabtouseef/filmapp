import 'package:flutter/material.dart';

enum ActorOpportunityType { directOffer, auditionInvite, castingCall }

enum ActorBookingStatus {
  sent,
  underNegotiation,
  termsApproved,
  contractPending,
  paymentPending,
  underVerification,
  secured,
  closed,
  disputed,
}

enum ActorAvailabilityStatus { available, tentative, booked, unavailable }

enum ActorTone { gold, blue, green, purple, danger, neutral }

class ActorMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final ActorTone tone;
  final String route;

  const ActorMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class ActorTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final ActorTone tone;

  const ActorTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class ActorMediaAsset {
  final String id;
  final String url;
  final String title;
  final String category;
  final String meta;
  final IconData fallbackIcon;

  const ActorMediaAsset({
    required this.id,
    required this.url,
    required this.title,
    required this.category,
    required this.meta,
    required this.fallbackIcon,
  });
}

class ActorOpportunity {
  final String id;
  final ActorOpportunityType type;
  final String projectTitle;
  final String role;
  final String producer;
  final String city;
  final String dates;
  final String fee;
  final double directorRating;
  final String expiry;
  final ActorBookingStatus status;
  final String imageUrl;
  final String notes;

  const ActorOpportunity({
    required this.id,
    required this.type,
    required this.projectTitle,
    required this.role,
    required this.producer,
    required this.city,
    required this.dates,
    required this.fee,
    required this.directorRating,
    required this.expiry,
    required this.status,
    required this.imageUrl,
    required this.notes,
  });
}

class ActorPortfolioItem {
  final String id;
  final String title;
  final String category;
  final String duration;
  final String status;
  final String imageUrl;
  final bool cover;

  const ActorPortfolioItem({
    required this.id,
    required this.title,
    required this.category,
    required this.duration,
    required this.status,
    required this.imageUrl,
    this.cover = false,
  });

  ActorPortfolioItem copyWith({
    String? status,
    bool? cover,
  }) {
    return ActorPortfolioItem(
      id: id,
      title: title,
      category: category,
      duration: duration,
      status: status ?? this.status,
      imageUrl: imageUrl,
      cover: cover ?? this.cover,
    );
  }
}

class ActorRateItem {
  final String id;
  final String label;
  final int amount;
  final bool negotiable;
  final String category;

  const ActorRateItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.negotiable,
    required this.category,
  });

  ActorRateItem copyWith({int? amount, bool? negotiable}) {
    return ActorRateItem(
      id: id,
      label: label,
      amount: amount ?? this.amount,
      negotiable: negotiable ?? this.negotiable,
      category: category,
    );
  }
}

class ActorPaymentMilestone {
  final String id;
  final String label;
  final String amount;
  final String dueDate;
  final ActorBookingStatus status;

  const ActorPaymentMilestone({
    required this.id,
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}

class ActorReview {
  final String reviewer;
  final String project;
  final String text;
  final double rating;
  final String date;

  const ActorReview({
    required this.reviewer,
    required this.project,
    required this.text,
    required this.rating,
    required this.date,
  });
}
