class ModelExtensionRoutes {
  ModelExtensionRoutes._();

  static const categories = '/model';
  static const usageRights = '/model/usage-rights';
  static const portfolio = '/model/portfolio-categories';
  static const rateByUsage = '/model/rate-by-usage';
  static const brandSafety = '/model/brand-safety';
  static const profile = '/model/profile';
  static const opportunities = '/model/opportunities';
  static const opportunityApplicationDetail =
      '/model/opportunities/application';

  static const primaryNav = [
    categories,
    usageRights,
    portfolio,
    rateByUsage,
    brandSafety,
  ];

  static const allRoutes = [
    categories,
    usageRights,
    portfolio,
    rateByUsage,
    brandSafety,
    profile,
    opportunities,
    opportunityApplicationDetail,
  ];

  static String titleFor(String route) {
    return switch (route) {
      categories => 'Campaign Categories',
      usageRights => 'Usage Rights',
      portfolio => 'Portfolio Categories',
      rateByUsage => 'Rate by Usage',
      brandSafety => 'Brand Safety',
      profile => 'Model Profile',
      opportunities => 'Opportunities',
      opportunityApplicationDetail => 'Application Details',
      _ => 'Model Extension',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      categories => 'MD-01',
      usageRights => 'MD-02',
      portfolio => 'MD-03',
      rateByUsage => 'MD-04',
      brandSafety => 'MD-05',
      profile => 'MD-06',
      opportunities => 'MD-07',
      opportunityApplicationDetail => 'MD-08',
      _ => 'MD',
    };
  }
}
