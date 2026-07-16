import 'package:flutter/material.dart';

enum LocationBookingStatus {
  requestReceived,
  underNegotiation,
  contractPending,
  depositPending,
  secured,
  inProgress,
  closed,
  disputed,
}

enum LocationCalendarStatus {
  available,
  blocked,
  maintenance,
  tentativeHold,
  booked
}

enum LocationTone { gold, blue, green, purple, danger, neutral }

enum LocationInspectionStage { pending, captured, confirmed, issue }

class LocationProperty {
  final String id;
  final String name;
  final String type;
  final String city;
  final String area;
  final String publicAddress;
  final String encryptedAddressHint;
  final String imageUrl;
  final int capacity;
  final int parking;
  final bool powerBackup;
  final bool accessible;
  final double rating;

  const LocationProperty({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.area,
    required this.publicAddress,
    required this.encryptedAddressHint,
    required this.imageUrl,
    required this.capacity,
    required this.parking,
    required this.powerBackup,
    required this.accessible,
    required this.rating,
  });
}

class LocationMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final LocationTone tone;
  final String route;

  const LocationMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class LocationTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final LocationTone tone;

  const LocationTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class LocationBookingRequest {
  final String id;
  final String project;
  final String producer;
  final String dates;
  final String crewSize;
  final String budget;
  final String purpose;
  final LocationBookingStatus status;
  final String imageUrl;

  const LocationBookingRequest({
    required this.id,
    required this.project,
    required this.producer,
    required this.dates,
    required this.crewSize,
    required this.budget,
    required this.purpose,
    required this.status,
    required this.imageUrl,
  });
}

class LocationPriceItem {
  final String id;
  final String label;
  final int amount;
  final bool enabled;

  const LocationPriceItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.enabled,
  });

  LocationPriceItem copyWith({int? amount, bool? enabled}) {
    return LocationPriceItem(
      id: id,
      label: label,
      amount: amount ?? this.amount,
      enabled: enabled ?? this.enabled,
    );
  }
}

class LocationRuleItem {
  final String id;
  final String label;
  final String note;
  final bool allowed;
  final IconData icon;

  const LocationRuleItem({
    required this.id,
    required this.label,
    required this.note,
    required this.allowed,
    required this.icon,
  });

  LocationRuleItem copyWith({String? note, bool? allowed}) {
    return LocationRuleItem(
      id: id,
      label: label,
      note: note ?? this.note,
      allowed: allowed ?? this.allowed,
      icon: icon,
    );
  }
}

class LocationInspectionItem {
  final String id;
  final String area;
  final String beforeImage;
  final String afterImage;
  final String note;
  final LocationInspectionStage stage;

  const LocationInspectionItem({
    required this.id,
    required this.area,
    required this.beforeImage,
    required this.afterImage,
    required this.note,
    required this.stage,
  });

  LocationInspectionItem copyWith({
    String? note,
    LocationInspectionStage? stage,
  }) {
    return LocationInspectionItem(
      id: id,
      area: area,
      beforeImage: beforeImage,
      afterImage: afterImage,
      note: note ?? this.note,
      stage: stage ?? this.stage,
    );
  }
}

class LocationLedgerItem {
  final String id;
  final String label;
  final String amount;
  final String dueDate;
  final LocationBookingStatus status;

  const LocationLedgerItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}
