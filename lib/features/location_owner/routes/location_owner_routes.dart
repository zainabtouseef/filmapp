class LocationOwnerRoutes {
  LocationOwnerRoutes._();

  static const home = '/location-owner';
  static const listing = '/location-owner/listing-wizard';
  static const calendar = '/location-owner/availability';
  static const pricing = '/location-owner/pricing';
  static const rules = '/location-owner/rules';
  static const requests = '/location-owner/requests';
  static const checkIn = '/location-owner/check-in';
  static const checkOut = '/location-owner/check-out';
  static const earnings = '/location-owner/earnings';
  static const performance = '/location-owner/performance';
  static const profile = '/location-owner/profile';
  static const portfolio = '/location-owner/portfolio';
  static const opportunities = '/location-owner/opportunities';
  static const opportunityApplicationDetail =
      '/location-owner/opportunities/application';

  static const primaryNav = [
    home,
    requests,
    calendar,
    earnings,
  ];

  static const allRoutes = [
    home,
    listing,
    calendar,
    pricing,
    rules,
    requests,
    checkIn,
    checkOut,
    earnings,
    performance,
    profile,
    portfolio,
    opportunities,
    opportunityApplicationDetail,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Location Workspace',
      listing => 'Properties',
      calendar => 'Availability',
      pricing => 'Rates & Deposits',
      rules => 'Property Rules',
      requests => 'Booking Requests',
      checkIn => 'Check-In',
      checkOut => 'Check-Out & Claims',
      earnings => 'Earnings',
      performance => 'Property Insights',
      profile => 'Owner Profile',
      portfolio => 'Portfolio',
      opportunities => 'Opportunities',
      opportunityApplicationDetail => 'Application Details',
      _ => 'Location Owner',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'LO-01',
      listing => 'LO-02',
      calendar => 'LO-03',
      pricing => 'LO-04',
      rules => 'LO-05',
      requests => 'LO-06',
      checkIn => 'LO-07',
      checkOut => 'LO-08',
      earnings => 'LO-09',
      performance => 'LO-10',
      profile => 'LO-11',
      portfolio => 'LO-12',
      opportunities => 'LO-13',
      opportunityApplicationDetail => 'LO-14',
      _ => 'LO',
    };
  }
}
