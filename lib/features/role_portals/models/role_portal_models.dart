import 'package:flutter/material.dart';

enum BookingLifecycleStatus {
  draft,
  sent,
  underNegotiation,
  termsApproved,
  contractPendingSignature,
  paymentPending,
  paymentUnderVerification,
  securedBooking,
  inProgress,
  completionReview,
  closed,
  disputed,
  cancelled,
}

enum PortalScreenKind {
  dashboard,
  profile,
  portfolio,
  calendar,
  inbox,
  detail,
  composer,
  manager,
  finance,
  safety,
  reports,
}

enum PortalMetricTone { blue, purple, gold, green, danger, neutral }

class RolePortalNavItem {
  final String label;
  final IconData icon;
  final String route;

  const RolePortalNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}

class RolePortalSpec {
  final String id;
  final String label;
  final String shortLabel;
  final String description;
  final IconData icon;
  final String homeRoute;
  final List<RolePortalScreenSpec> screens;

  const RolePortalSpec({
    required this.id,
    required this.label,
    required this.shortLabel,
    required this.description,
    required this.icon,
    required this.homeRoute,
    required this.screens,
  });

  List<RolePortalNavItem> get navItems => screens
      .map(
        (screen) => RolePortalNavItem(
          label: screen.navLabel,
          icon: screen.icon,
          route: screen.route,
        ),
      )
      .toList();
}

class RolePortalScreenSpec {
  final String id;
  final String navLabel;
  final String title;
  final String subtitle;
  final String route;
  final IconData icon;
  final PortalScreenKind kind;
  final String primaryAction;
  final String secondaryAction;
  final String mediaCategory;
  final List<String> filters;
  final List<String> formFields;

  const RolePortalScreenSpec({
    required this.id,
    required this.navLabel,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.icon,
    required this.kind,
    required this.primaryAction,
    required this.secondaryAction,
    required this.mediaCategory,
    this.filters = const [],
    this.formFields = const [],
  });
}

class PortalMetric {
  final String label;
  final String value;
  final String delta;
  final IconData icon;
  final PortalMetricTone tone;

  const PortalMetric({
    required this.label,
    required this.value,
    required this.delta,
    required this.icon,
    required this.tone,
  });
}

class PortalRecord {
  final String id;
  final String title;
  final String subtitle;
  final String meta;
  final String status;
  final String amount;
  final String imageUrl;
  final IconData icon;

  const PortalRecord({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.meta,
    required this.status,
    required this.amount,
    required this.imageUrl,
    required this.icon,
  });
}

class PortalMediaAsset {
  final String id;
  final String url;
  final String label;
  final String category;
  final IconData fallbackIcon;

  const PortalMediaAsset({
    required this.id,
    required this.url,
    required this.label,
    required this.category,
    required this.fallbackIcon,
  });
}

class PortalWorkflowItem {
  final BookingLifecycleStatus status;
  final String title;
  final String owner;
  final String timestamp;

  const PortalWorkflowItem({
    required this.status,
    required this.title,
    required this.owner,
    required this.timestamp,
  });
}
