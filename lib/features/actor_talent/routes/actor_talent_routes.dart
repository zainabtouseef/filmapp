class ActorTalentRoutes {
  ActorTalentRoutes._();

  static const dashboard = '/talent';
  static const profile = '/talent/profile';
  static const portfolio = '/talent/portfolio';
  static const calendar = '/talent/availability';
  static const rates = '/talent/rates';
  static const opportunities = '/talent/opportunities';
  static const roleDetail = '/talent/roles/:id';
  static const applications = '/talent/applications';
  static const applicationDetail = '/talent/applications/:id';
  static const auditions = '/talent/auditions';
  static const bookings = '/talent/bookings';
  static const offerDetail = '/talent/offers/:id';
  static const counteroffer = '/talent/counteroffer';
  static const contracts = '/talent/contracts';
  static const earnings = '/talent/earnings';
  static const reputation = '/talent/reputation';
  static const safety = '/talent/safety';

  static const primaryNav = [
    dashboard,
    opportunities,
    applications,
    bookings,
    profile,
  ];

  static const allRoutes = [
    dashboard,
    profile,
    portfolio,
    calendar,
    rates,
    opportunities,
    roleDetail,
    applications,
    applicationDetail,
    auditions,
    bookings,
    offerDetail,
    counteroffer,
    contracts,
    earnings,
    reputation,
    safety,
  ];

  static String titleFor(String route) {
    return switch (route) {
      dashboard => 'Talent Workspace',
      profile => 'Casting Profile',
      portfolio => 'Portfolio',
      calendar => 'Availability',
      rates => 'Rates',
      opportunities => 'Opportunities',
      roleDetail => 'Role Details',
      applications => 'Applications',
      applicationDetail => 'Application Details',
      auditions => 'Auditions',
      bookings => 'Bookings & Messages',
      offerDetail => 'Offer Review',
      counteroffer => 'Counteroffer',
      contracts => 'Contracts',
      earnings => 'Earnings',
      reputation => 'Reviews',
      safety => 'Safety & Support',
      _ => 'Actor / Talent',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      dashboard => 'AT-01',
      profile => 'AT-02',
      portfolio => 'AT-03',
      calendar => 'AT-04',
      rates => 'AT-05',
      opportunities => 'AT-06',
      roleDetail => 'AT-13',
      applications => 'AT-14',
      applicationDetail => 'AT-15',
      auditions => 'AT-16',
      bookings => 'AT-17',
      offerDetail => 'AT-07',
      counteroffer => 'AT-08',
      contracts => 'AT-09',
      earnings => 'AT-10',
      reputation => 'AT-11',
      safety => 'AT-12',
      _ => 'AT',
    };
  }
}
