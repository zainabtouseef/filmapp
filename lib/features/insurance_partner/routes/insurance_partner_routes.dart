class InsurancePartnerRoutes {
  InsurancePartnerRoutes._();

  static const home = '/insurance';
  static const records = '/insurance/records';
  static const claims = '/insurance/claims';
  static const safety = '/insurance/safety-permits';
  static const incidents = '/insurance/incidents';

  static const primaryNav = [
    home,
    records,
    claims,
    safety,
    incidents,
  ];

  static const allRoutes = [
    home,
    records,
    claims,
    safety,
    incidents,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Insurance / Safety Dashboard',
      records => 'Shoot Insurance Records',
      claims => 'Claim Support',
      safety => 'Safety Checks & Permits',
      incidents => 'Incident Reports',
      _ => 'Insurance / Safety Partner',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'IN-01',
      records => 'IN-02',
      claims => 'IN-03',
      safety => 'IN-04',
      incidents => 'IN-05',
      _ => 'IN',
    };
  }
}
