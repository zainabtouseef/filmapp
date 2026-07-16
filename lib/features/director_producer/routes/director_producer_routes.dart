import 'package:flutter/material.dart';

class DirectorProducerRoutes {
  DirectorProducerRoutes._();

  static const home = '/director';
  static const projects = '/director/projects';
  static const createProject = '/director/projects/create';
  static const projectDetail = '/director/projects/:id';
  static const requirements = '/director/projects/:id/requirements';
  static const marketplace = '/director/marketplace';
  static const filters = '/director/marketplace/filters';
  static const profile = '/director/profile/:id';
  static const shortlist = '/director/shortlist';
  static const bookingRequest = '/director/booking-request';
  static const bargaining = '/director/bargaining';
  static const negotiationThread = '/director/bargaining/:id';
  static const contracts = '/director/contracts';
  static const payments = '/director/payments';
  static const schedule = '/director/schedule';
  static const accounts = '/director/accounts';
  static const room = '/director/room';
  static const reports = '/director/reports';

  static const allRoutes = [
    home,
    projects,
    createProject,
    projectDetail,
    requirements,
    marketplace,
    filters,
    profile,
    shortlist,
    bookingRequest,
    bargaining,
    negotiationThread,
    contracts,
    payments,
    schedule,
    accounts,
    room,
    reports,
  ];
}

class DpNavItem {
  final String label;
  final IconData icon;
  final String route;

  const DpNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
