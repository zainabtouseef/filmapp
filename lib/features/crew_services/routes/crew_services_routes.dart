class CrewServicesRoutes {
  CrewServicesRoutes._();

  static const home = '/crew';
  static const profile = '/crew/profile';
  static const portfolio = '/crew/portfolio';
  static const availability = '/crew/availability';
  static const requests = '/crew/requests';
  static const contracts = '/crew/contracts-payments';
  static const ratings = '/crew/ratings';
  static const opportunities = '/crew/opportunities';
  static const opportunityApplicationDetail = '/crew/opportunities/application';

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
    opportunities,
    opportunityApplicationDetail,
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
      opportunities => 'Opportunities',
      opportunityApplicationDetail => 'Application Details',
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
      opportunities => 'CR-08',
      opportunityApplicationDetail => 'CR-09',
      _ => 'CR',
    };
  }
}
