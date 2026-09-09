class BrandSponsorRoutes {
  BrandSponsorRoutes._();

  static const home = '/brand';
  static const projects = '/brand/projects';
  static const marketplace = '/brand/discover';
  static const shortlists = '/brand/shortlists';
  static const bookings = '/brand/requests';
  static const profile = '/brand/profile';
  static const composer = '/brand/opportunity-composer';
  static const applications = '/brand/applications';
  static const negotiation = '/brand/negotiation';
  static const tracker = '/brand/campaign-tracker';
  static const payments = '/brand/payments';

  static const primaryNav = [
    home,
    projects,
    marketplace,
    bookings,
  ];

  static const allRoutes = [
    home,
    projects,
    marketplace,
    shortlists,
    bookings,
    profile,
    composer,
    applications,
    negotiation,
    tracker,
    payments,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Brand Workspace',
      projects => 'Projects & Campaigns',
      marketplace => 'Production Marketplace',
      shortlists => 'Project Shortlists',
      bookings => 'Requests & Bookings',
      profile => 'Brand Profile',
      composer => 'Opportunities',
      applications => 'Applications',
      negotiation => 'Terms & Deals',
      tracker => 'Campaign Delivery',
      payments => 'Finance & Records',
      _ => 'Brand Workspace',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'BR-01',
      projects => 'BR-08',
      marketplace => 'BR-09',
      shortlists => 'BR-10',
      bookings => 'BR-11',
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
