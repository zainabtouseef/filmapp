class DistributionPartnerRoutes {
  DistributionPartnerRoutes._();

  static const home = '/distribution';
  static const contacts = '/distribution/contacts';
  static const release = '/distribution/release';
  static const reports = '/distribution/reports';

  static const primaryNav = [
    home,
    contacts,
    release,
    release,
    reports,
  ];

  static const allRoutes = [
    home,
    contacts,
    release,
    reports,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Distribution Dashboard',
      contacts => 'Distributor Contacts & Records',
      release => 'Release Coordination',
      reports => 'Performance Reporting',
      _ => 'Distribution / Release Partner',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'DS-01',
      contacts => 'DS-02',
      release => 'DS-03',
      reports => 'DS-04',
      _ => 'DS',
    };
  }
}
