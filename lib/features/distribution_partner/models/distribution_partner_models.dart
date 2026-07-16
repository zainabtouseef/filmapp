import 'package:flutter/material.dart';

enum DistributionStatus {
  ready,
  missingItems,
  pending,
  approved,
  activeWindow,
  submitted,
  completed,
  delayed,
  escalated,
  closed,
  draft,
}

enum DistributionTone { gold, blue, green, purple, danger, neutral }

class DistributionMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final DistributionTone tone;
  final String route;

  const DistributionMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
    required this.route,
  });
}

class DistributionTask {
  final String id;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final DistributionTone tone;

  const DistributionTask({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.tone,
  });
}

class DistributionProject {
  final String id;
  final String title;
  final String producer;
  final String releaseWindow;
  final String territories;
  final String missingItems;
  final String statusNote;
  final DistributionStatus status;
  final String imageUrl;

  const DistributionProject({
    required this.id,
    required this.title,
    required this.producer,
    required this.releaseWindow,
    required this.territories,
    required this.missingItems,
    required this.statusNote,
    required this.status,
    required this.imageUrl,
  });
}

class DistributorContact {
  final String id;
  final String name;
  final String channel;
  final String territory;
  final String contactRole;
  final String priorProject;
  final String notes;
  final DistributionStatus status;

  const DistributorContact({
    required this.id,
    required this.name,
    required this.channel,
    required this.territory,
    required this.contactRole,
    required this.priorProject,
    required this.notes,
    required this.status,
  });
}

class ReleaseHandoverItem {
  final String id;
  final String label;
  final String detail;
  final bool mandatory;

  const ReleaseHandoverItem({
    required this.id,
    required this.label,
    required this.detail,
    this.mandatory = true,
  });
}

class DistributionReportRecord {
  final String id;
  final String partner;
  final String territory;
  final String channel;
  final String audience;
  final String revenue;
  final DistributionStatus status;

  const DistributionReportRecord({
    required this.id,
    required this.partner,
    required this.territory,
    required this.channel,
    required this.audience,
    required this.revenue,
    required this.status,
  });
}

class DistributionChartPoint {
  final String label;
  final int value;
  final DistributionTone tone;

  const DistributionChartPoint({
    required this.label,
    required this.value,
    required this.tone,
  });
}
