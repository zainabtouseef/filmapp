class ActorTalentRoutes {
  ActorTalentRoutes._();

  static const dashboard = '/talent';
  static const profile = '/talent/profile';
  static const portfolio = '/talent/portfolio';
  static const calendar = '/talent/availability';
  static const rates = '/talent/rates';
  static const opportunities = '/talent/opportunities';
  static const offerDetail = '/talent/offers/:id';
  static const counteroffer = '/talent/counteroffer';
  static const contracts = '/talent/contracts';
  static const earnings = '/talent/earnings';
  static const reputation = '/talent/reputation';
  static const safety = '/talent/safety';

  static const primaryNav = [
    dashboard,
    opportunities,
    calendar,
    earnings,
    profile,
  ];

  static const allRoutes = [
    dashboard,
    profile,
    portfolio,
    calendar,
    rates,
    opportunities,
    offerDetail,
    counteroffer,
    contracts,
    earnings,
    reputation,
    safety,
  ];

  static String titleFor(String route) {
    return switch (route) {
      dashboard => 'Talent Dashboard',
      profile => 'Profile Builder',
      portfolio => 'Portfolio & Showreel',
      calendar => 'Availability Calendar',
      rates => 'Rate Card',
      opportunities => 'Opportunity Inbox',
      offerDetail => 'Offer Detail',
      counteroffer => 'Counteroffer',
      contracts => 'Contract Signing',
      earnings => 'Earnings Security',
      reputation => 'Reputation',
      safety => 'Safety Controls',
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
