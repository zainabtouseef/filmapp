class BrandSponsorRoutes {
  BrandSponsorRoutes._();

  static const home = '/brand';
  static const profile = '/brand/profile';
  static const composer = '/brand/opportunity-composer';
  static const applications = '/brand/applications';
  static const negotiation = '/brand/negotiation';
  static const tracker = '/brand/campaign-tracker';
  static const payments = '/brand/payments';

  static const primaryNav = [
    home,
    composer,
    applications,
    tracker,
    payments,
  ];

  static const allRoutes = [
    home,
    profile,
    composer,
    applications,
    negotiation,
    tracker,
    payments,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Brand Dashboard',
      profile => 'Brand Profile',
      composer => 'Opportunity Composer',
      applications => 'Applications Inbox',
      negotiation => 'Negotiation & Terms',
      tracker => 'Campaign Tracker',
      payments => 'Payments & Records',
      _ => 'Brands / Sponsors',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'BR-01',
      profile => 'BR-02',
      composer => 'BR-03',
      applications => 'BR-04',
      negotiation => 'BR-05',
      tracker => 'BR-06',
      payments => 'BR-07',
      _ => 'BR',
    };
  }
}
