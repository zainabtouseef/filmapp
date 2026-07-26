class InfluencerRoutes {
  InfluencerRoutes._();

  static const home = '/influencer';
  static const mediaKit = '/influencer/media-kit';
  static const packages = '/influencer/packages';
  static const campaigns = '/influencer/campaigns';
  static const analytics = '/influencer/analytics';
  static const portfolio = '/influencer/portfolio';
  static const calendar = '/influencer/calendar';
  static const contracts = '/influencer/contracts';
  static const earnings = '/influencer/earnings';
  static const reviews = '/influencer/reviews';
  static const safety = '/influencer/safety';

  static const primaryNav = [
    home,
    mediaKit,
    packages,
    campaigns,
    analytics,
  ];

  static const allRoutes = [
    home,
    mediaKit,
    packages,
    campaigns,
    analytics,
    portfolio,
    calendar,
    contracts,
    earnings,
    reviews,
    safety,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Influencer Dashboard',
      mediaKit => 'Media Kit',
      packages => 'Rate Packages',
      campaigns => 'Campaigns',
      analytics => 'Campaign Analytics',
      portfolio => 'Portfolio',
      calendar => 'Availability',
      contracts => 'Contracts',
      earnings => 'Earnings',
      reviews => 'Reviews',
      safety => 'Safety & Support',
      _ => 'Influencer Portal',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'IF-01',
      mediaKit => 'IF-02',
      packages => 'IF-03',
      campaigns => 'IF-04',
      analytics => 'IF-05',
      portfolio => 'IF-06',
      calendar => 'IF-07',
      contracts => 'IF-08',
      earnings => 'IF-09',
      reviews => 'IF-10',
      safety => 'IF-11',
      _ => 'IF',
    };
  }
}
