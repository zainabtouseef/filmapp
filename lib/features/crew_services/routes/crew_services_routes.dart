class CrewServicesRoutes {
  CrewServicesRoutes._();

  static const home = '/crew';
  static const profile = '/crew/profile';
  static const portfolio = '/crew/portfolio';
  static const availability = '/crew/availability';
  static const requests = '/crew/requests';
  static const contracts = '/crew/contracts-payments';
  static const ratings = '/crew/ratings';

  static const primaryNav = [
    home,
    requests,
    availability,
    contracts,
    profile,
  ];

  static const allRoutes = [
    home,
    profile,
    portfolio,
    availability,
    requests,
    contracts,
    ratings,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Crew Dashboard',
      profile => 'Service Profile',
      portfolio => 'Portfolio & Credits',
      availability => 'Availability Calendar',
      requests => 'Requests & Negotiation',
      contracts => 'Contracts & Payments',
      ratings => 'Ratings & Work History',
      _ => 'Crew Services',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'CR-01',
      profile => 'CR-02',
      portfolio => 'CR-03',
      availability => 'CR-04',
      requests => 'CR-05',
      contracts => 'CR-06',
      ratings => 'CR-07',
      _ => 'CR',
    };
  }
}
