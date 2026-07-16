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

  static const primaryNav = [
    home,
    listing,
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
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Owner Dashboard',
      listing => 'Location Listing',
      calendar => 'Availability Calendar',
      pricing => 'Pricing & Deposit',
      rules => 'Rules & Restrictions',
      requests => 'Booking Requests',
      checkIn => 'Check-In Inspection',
      checkOut => 'Check-Out Claim',
      earnings => 'Earnings & Deposits',
      performance => 'Property Performance',
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
      _ => 'LO',
    };
  }
}
