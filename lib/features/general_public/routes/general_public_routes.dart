import 'package:flutter/material.dart';

class GeneralPublicRoutes {
  GeneralPublicRoutes._();

  static const home = '/public';
  static const cinema = '/public/cinema';
  static const browse = '/public/browse';
  static const actors = '/public/actors';
  static const models = '/public/models';
  static const influencers = '/public/influencers';
  static const profile = '/public/profile/:id';
  static const bookingRequest = '/public/booking-request';
  static const requests = '/public/requests';
  static const contracts = '/public/contracts';
  static const payments = '/public/payments';
  static const account = '/public/account';

  static const allRoutes = [
    home,
    cinema,
    browse,
    actors,
    models,
    influencers,
    profile,
    bookingRequest,
    requests,
    contracts,
    payments,
    account,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Campaign Home',
      cinema => 'Cinema',
      browse => 'Browse Talent',
      actors => 'Book Actors',
      models => 'Book Models',
      influencers => 'Book Influencers',
      profile => 'Talent Profile',
      bookingRequest => 'Booking Request',
      requests => 'My Requests',
      contracts => 'Contracts',
      payments => 'Payments',
      account => 'Account',
      _ => 'Public Booking Portal',
    };
  }
}

class GeneralPublicNavItem {
  final String label;
  final IconData icon;
  final String route;

  const GeneralPublicNavItem({
    required this.label,
    required this.icon,
    required this.route,
  });
}
