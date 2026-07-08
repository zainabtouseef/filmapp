import 'package:flutter/material.dart';

class SuperAdminRoutes {
  SuperAdminRoutes._();

  static const loginDemo = '/admin/login-demo';
  static const dashboard = '/admin/dashboard';
  static const reviewHub = '/admin/review-hub';
  static const reviewHubPeople = '/admin/review-hub/people';
  static const reviewHubListings = '/admin/review-hub/listings';
  static const reviewHubContent = '/admin/review-hub/content';
  static const verifications = '/admin/verifications';
  static const verificationDetail = '/admin/verifications/:id';
  static const contentModeration = '/admin/content-moderation';
  static const listingsModeration = '/admin/listings-moderation';
  static const bookingsMonitor = '/admin/bookings-monitor';
  static const paymentQueue = '/admin/payment-queue';
  static const paymentReview = '/admin/payment-review/:id';
  static const contractTemplates = '/admin/contract-templates';
  static const fees = '/admin/fees';
  static const disputes = '/admin/disputes';
  static const disputeCase = '/admin/disputes/:id';
  static const users = '/admin/users';
  static const adminRoles = '/admin/admin-roles';
  static const support = '/admin/support';
  static const broadcasts = '/admin/broadcasts';
  static const auditLogs = '/admin/audit-logs';
  static const analytics = '/admin/analytics';

  static const allRoutes = [
    dashboard,
    reviewHub,
    reviewHubPeople,
    reviewHubListings,
    reviewHubContent,
    verifications,
    verificationDetail,
    contentModeration,
    listingsModeration,
    bookingsMonitor,
    paymentQueue,
    paymentReview,
    contractTemplates,
    fees,
    disputes,
    disputeCase,
    users,
    adminRoles,
    support,
    broadcasts,
    auditLogs,
    analytics,
  ];
}

class AdminNavItem {
  final String label;
  final IconData icon;
  final String route;

  const AdminNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
