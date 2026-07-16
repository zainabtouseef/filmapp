class MediaEquipmentRoutes {
  MediaEquipmentRoutes._();

  static const home = '/equipment-provider';
  static const profile = '/equipment-provider/profile';
  static const inventory = '/equipment-provider/inventory';
  static const packages = '/equipment-provider/packages';
  static const availability = '/equipment-provider/availability';
  static const terms = '/equipment-provider/terms';
  static const requests = '/equipment-provider/requests';
  static const handover = '/equipment-provider/handover';
  static const returns = '/equipment-provider/return';
  static const earnings = '/equipment-provider/earnings';

  static const primaryNav = [
    home,
    inventory,
    requests,
    availability,
    earnings,
  ];

  static const allRoutes = [
    home,
    profile,
    inventory,
    packages,
    availability,
    terms,
    requests,
    handover,
    returns,
    earnings,
  ];

  static String titleFor(String route) {
    return switch (route) {
      home => 'Provider Dashboard',
      profile => 'Provider Profile',
      inventory => 'Inventory Manager',
      packages => 'Package Builder',
      availability => 'Availability Calendar',
      terms => 'Rate & Terms',
      requests => 'Requests & Negotiation',
      handover => 'Handover Checklist',
      returns => 'Return Checklist',
      earnings => 'Earnings & Ratings',
      _ => 'Media / Equipment',
    };
  }

  static String screenIdFor(String route) {
    return switch (route) {
      home => 'ME-01',
      profile => 'ME-02',
      inventory => 'ME-03',
      packages => 'ME-04',
      availability => 'ME-05',
      terms => 'ME-06',
      requests => 'ME-07',
      handover => 'ME-08',
      returns => 'ME-09',
      earnings => 'ME-10',
      _ => 'ME',
    };
  }
}
