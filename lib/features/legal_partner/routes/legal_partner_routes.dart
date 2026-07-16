class LegalPartnerRoutes {
  LegalPartnerRoutes._();

  static const home = '/legal';
  static const contractReview = '/legal/contract-review';
  static const templateReview = '/legal/template-review';
  static const addendumReview = '/legal/addendum-review';
  static const billing = '/legal/history-billing';

  static const primaryNav = [
    home,
    contractReview,
    templateReview,
    addendumReview,
    billing,
  ];

  static const allRoutes = [
    home,
    contractReview,
    templateReview,
    addendumReview,
    billing,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Legal Dashboard',
      contractReview => 'Contract Review Request Detail',
      templateReview => 'Template Review',
      addendumReview => 'Addendum Review',
      billing => 'Review History & Billing',
      _ => 'Legal Partner',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'LG-01',
      contractReview => 'LG-02',
      templateReview => 'LG-03',
      addendumReview => 'LG-04',
      billing => 'LG-05',
      _ => 'LG',
    };
  }
}
