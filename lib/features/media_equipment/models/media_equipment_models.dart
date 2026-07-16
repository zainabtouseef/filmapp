import 'package:flutter/material.dart';

enum MediaBookingStatus {
  requestReceived,
  underNegotiation,
  contractPending,
  depositPending,
  secured,
  inProgress,
  returned,
  closed,
  rejected,
  disputed,
}

enum MediaAvailabilityStatus { available, hold, booked, maintenance, transit }

enum MediaTone { gold, blue, green, purple, danger, neutral }

enum MediaInspectionStage { pending, captured, verified, issue, missing }

class MediaProviderProfile {
  final String id;
  final String name;
  final String type;
  final String city;
  final String coverage;
  final String verification;
  final String serviceCategories;
  final String bio;
  final String imageUrl;
  final double rating;

  const MediaProviderProfile({
    required this.id,
    required this.name,
    required this.type,
    required this.city,
    required this.coverage,
    required this.verification,
    required this.serviceCategories,
    required this.bio,
    required this.imageUrl,
    required this.rating,
  });
}

class MediaInventoryItem {
  final String id;
  final String category;
  final String modelName;
  final String serial;
  final String condition;
  final int dayRate;
  final int deposit;
  final String city;
  final String imageUrl;
  final bool available;

  const MediaInventoryItem({
    required this.id,
    required this.category,
    required this.modelName,
    required this.serial,
    required this.condition,
    required this.dayRate,
    required this.deposit,
    required this.city,
    required this.imageUrl,
    required this.available,
  });

  MediaInventoryItem copyWith({bool? available}) {
    return MediaInventoryItem(
      id: id,
      category: category,
      modelName: modelName,
      serial: serial,
      condition: condition,
      dayRate: dayRate,
      deposit: deposit,
      city: city,
      imageUrl: imageUrl,
      available: available ?? this.available,
    );
  }
}

class MediaMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final MediaTone tone;
  final String route;

  const MediaMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class MediaTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final MediaTone tone;

  const MediaTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class MediaBookingRequest {
  final String id;
  final String project;
  final String producer;
  final String dates;
  final String city;
  final String budget;
  final String items;
  final MediaBookingStatus status;
  final String imageUrl;

  const MediaBookingRequest({
    required this.id,
    required this.project,
    required this.producer,
    required this.dates,
    required this.city,
    required this.budget,
    required this.items,
    required this.status,
    required this.imageUrl,
  });
}

class MediaPackageItem {
  final String id;
  final String label;
  final String items;
  final bool operatorIncluded;
  final int price;
  final String terms;

  const MediaPackageItem({
    required this.id,
    required this.label,
    required this.items,
    required this.operatorIncluded,
    required this.price,
    required this.terms,
  });
}

class MediaTermItem {
  final String id;
  final String label;
  final String note;
  final int amount;
  final bool enabled;
  final IconData icon;

  const MediaTermItem({
    required this.id,
    required this.label,
    required this.note,
    required this.amount,
    required this.enabled,
    required this.icon,
  });

  MediaTermItem copyWith({int? amount, bool? enabled}) {
    return MediaTermItem(
      id: id,
      label: label,
      note: note,
      amount: amount ?? this.amount,
      enabled: enabled ?? this.enabled,
      icon: icon,
    );
  }
}

class MediaInspectionItem {
  final String id;
  final String itemName;
  final String serial;
  final String beforeImage;
  final String afterImage;
  final String accessories;
  final MediaInspectionStage stage;

  const MediaInspectionItem({
    required this.id,
    required this.itemName,
    required this.serial,
    required this.beforeImage,
    required this.afterImage,
    required this.accessories,
    required this.stage,
  });

  MediaInspectionItem copyWith({MediaInspectionStage? stage}) {
    return MediaInspectionItem(
      id: id,
      itemName: itemName,
      serial: serial,
      beforeImage: beforeImage,
      afterImage: afterImage,
      accessories: accessories,
      stage: stage ?? this.stage,
    );
  }
}

class MediaLedgerItem {
  final String id;
  final String label;
  final String amount;
  final String dueDate;
  final MediaBookingStatus status;

  const MediaLedgerItem({
    required this.id,
    required this.label,
    required this.amount,
    required this.dueDate,
    required this.status,
  });
}
