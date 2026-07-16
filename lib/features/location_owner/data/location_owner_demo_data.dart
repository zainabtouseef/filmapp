import 'package:flutter/material.dart';

import '../models/location_owner_models.dart';
import '../routes/location_owner_routes.dart';

class LocationOwnerDemoData {
  LocationOwnerDemoData._();

  static const properties = [
    LocationProperty(
      id: 'LOC-102',
      name: 'Gulberg Glass House',
      type: 'Home',
      city: 'Lahore',
      area: 'Gulberg III',
      publicAddress: 'Gulberg III, Lahore',
      encryptedAddressHint: 'Exact address encrypted',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      capacity: 38,
      parking: 8,
      powerBackup: true,
      accessible: true,
      rating: 4.8,
    ),
    LocationProperty(
      id: 'LOC-210',
      name: 'Rooftop Cinema Terrace',
      type: 'Rooftop',
      city: 'Karachi',
      area: 'Clifton',
      publicAddress: 'Clifton, Karachi',
      encryptedAddressHint: 'Exact address encrypted',
      imageUrl:
          'https://images.unsplash.com/photo-1494526585095-c41746248156?auto=format&fit=crop&w=1200&q=80',
      capacity: 24,
      parking: 4,
      powerBackup: true,
      accessible: false,
      rating: 4.6,
    ),
    LocationProperty(
      id: 'LOC-338',
      name: 'Industrial Loft Studio',
      type: 'Studio',
      city: 'Islamabad',
      area: 'I-9',
      publicAddress: 'I-9, Islamabad',
      encryptedAddressHint: 'Exact address encrypted',
      imageUrl:
          'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1200&q=80',
      capacity: 45,
      parking: 12,
      powerBackup: true,
      accessible: true,
      rating: 4.7,
    ),
  ];

  static const requests = [
    LocationBookingRequest(
      id: 'LBR-871',
      project: 'River Lights',
      producer: 'Ayaan Films',
      dates: 'Jul 20 - Jul 24',
      crewSize: '28 crew',
      budget: 'PKR 640,000',
      purpose: 'Drama interiors + night exterior',
      status: LocationBookingStatus.requestReceived,
      imageUrl:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
    ),
    LocationBookingRequest(
      id: 'LBR-922',
      project: 'Metro Hearts',
      producer: 'Niazi Studio',
      dates: 'Aug 2',
      crewSize: '16 crew',
      budget: 'PKR 240,000',
      purpose: 'Commercial kitchen sequence',
      status: LocationBookingStatus.underNegotiation,
      imageUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=1200&q=80',
    ),
    LocationBookingRequest(
      id: 'LBR-940',
      project: 'Northern Sky',
      producer: 'Orbit Brands',
      dates: 'Aug 11 - Aug 12',
      crewSize: '34 crew',
      budget: 'PKR 510,000',
      purpose: 'Brand campaign rooftop frames',
      status: LocationBookingStatus.secured,
      imageUrl:
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const metrics = [
    LocationMetric(
      label: 'Upcoming Shoots',
      value: '4',
      delta: '+1 secured',
      icon: Icons.movie_filter_outlined,
      tone: LocationTone.blue,
      route: LocationOwnerRoutes.calendar,
    ),
    LocationMetric(
      label: 'Pending Requests',
      value: '7',
      delta: '2 urgent',
      icon: Icons.inbox_outlined,
      tone: LocationTone.gold,
      route: LocationOwnerRoutes.requests,
    ),
    LocationMetric(
      label: 'Earnings',
      value: '1.8M',
      delta: 'PKR protected',
      icon: Icons.account_balance_wallet_outlined,
      tone: LocationTone.green,
      route: LocationOwnerRoutes.earnings,
    ),
    LocationMetric(
      label: 'Rating',
      value: '4.8',
      delta: 'owner score',
      icon: Icons.star_outline_rounded,
      tone: LocationTone.purple,
      route: LocationOwnerRoutes.performance,
    ),
  ];

  static const tasks = [
    LocationTask(
      id: 'task-request',
      title: 'River Lights request needs decision',
      subtitle: 'Crew size and night exterior require confirmation.',
      route: LocationOwnerRoutes.requests,
      icon: Icons.priority_high_rounded,
      tone: LocationTone.gold,
    ),
    LocationTask(
      id: 'task-checkin',
      title: 'Check-in evidence due',
      subtitle: 'Before-photos required before handover.',
      route: LocationOwnerRoutes.checkIn,
      icon: Icons.fact_check_outlined,
      tone: LocationTone.blue,
    ),
    LocationTask(
      id: 'task-deposit',
      title: 'Deposit release review',
      subtitle: 'Confirm no damage or file a claim.',
      route: LocationOwnerRoutes.checkOut,
      icon: Icons.verified_user_outlined,
      tone: LocationTone.green,
    ),
  ];

  static const seedPrices = [
    LocationPriceItem(
        id: 'hourly', label: 'Hourly', amount: 18000, enabled: true),
    LocationPriceItem(
        id: 'half', label: 'Half-day', amount: 95000, enabled: true),
    LocationPriceItem(
        id: 'full', label: 'Full-day', amount: 165000, enabled: true),
    LocationPriceItem(
        id: 'night', label: 'Night shoot', amount: 210000, enabled: true),
    LocationPriceItem(
        id: 'overtime', label: 'Overtime hour', amount: 24000, enabled: true),
    LocationPriceItem(
        id: 'cleaning', label: 'Cleaning fee', amount: 35000, enabled: true),
    LocationPriceItem(
        id: 'deposit',
        label: 'Security deposit',
        amount: 180000,
        enabled: true),
  ];

  static const seedRules = [
    LocationRuleItem(
      id: 'smoking',
      label: 'Smoking',
      note: 'Outdoor only with cleanup.',
      allowed: false,
      icon: Icons.smoke_free_outlined,
    ),
    LocationRuleItem(
      id: 'pets',
      label: 'Pets',
      note: 'Small trained animals with notice.',
      allowed: true,
      icon: Icons.pets_outlined,
    ),
    LocationRuleItem(
      id: 'sound',
      label: 'Loud sound',
      note: 'No amplified sound after 10 PM.',
      allowed: false,
      icon: Icons.volume_up_outlined,
    ),
    LocationRuleItem(
      id: 'equipment',
      label: 'Heavy equipment',
      note: 'Protect flooring and confirm load plan.',
      allowed: true,
      icon: Icons.construction_outlined,
    ),
    LocationRuleItem(
      id: 'kitchen',
      label: 'Kitchen use',
      note: 'Available with cleaning fee.',
      allowed: true,
      icon: Icons.kitchen_outlined,
    ),
    LocationRuleItem(
      id: 'bedroom',
      label: 'Bedroom access',
      note: 'Primary suite excluded.',
      allowed: false,
      icon: Icons.bed_outlined,
    ),
    LocationRuleItem(
      id: 'rooftop',
      label: 'Rooftop access',
      note: 'Safety rail required.',
      allowed: true,
      icon: Icons.roofing_outlined,
    ),
    LocationRuleItem(
      id: 'crew',
      label: 'Max crew size',
      note: '38 people including cast.',
      allowed: true,
      icon: Icons.groups_2_outlined,
    ),
  ];

  static const seedInspection = [
    LocationInspectionItem(
      id: 'living',
      area: 'Living room',
      beforeImage:
          'https://images.unsplash.com/photo-1505693416388-ac5ce068fe85?auto=format&fit=crop&w=900&q=80',
      afterImage:
          'https://images.unsplash.com/photo-1513694203232-719a280e022f?auto=format&fit=crop&w=900&q=80',
      note: 'Furniture intact, floor protected.',
      stage: LocationInspectionStage.pending,
    ),
    LocationInspectionItem(
      id: 'kitchen',
      area: 'Kitchen',
      beforeImage:
          'https://images.unsplash.com/photo-1556912173-3bb406ef7e77?auto=format&fit=crop&w=900&q=80',
      afterImage:
          'https://images.unsplash.com/photo-1556909114-f6e7ad7d3136?auto=format&fit=crop&w=900&q=80',
      note: 'Counters clear, appliances documented.',
      stage: LocationInspectionStage.pending,
    ),
    LocationInspectionItem(
      id: 'meter',
      area: 'Power meter',
      beforeImage:
          'https://images.unsplash.com/photo-1621905252507-b35492cc74b4?auto=format&fit=crop&w=900&q=80',
      afterImage:
          'https://images.unsplash.com/photo-1611095790444-1dfa35e37b52?auto=format&fit=crop&w=900&q=80',
      note: 'Initial reading pending.',
      stage: LocationInspectionStage.pending,
    ),
  ];

  static const ledger = [
    LocationLedgerItem(
      id: 'led-1',
      label: 'Rental deposit',
      amount: 'PKR 180,000',
      dueDate: 'Jul 18',
      status: LocationBookingStatus.depositPending,
    ),
    LocationLedgerItem(
      id: 'led-2',
      label: 'Full-day rental',
      amount: 'PKR 330,000',
      dueDate: 'Jul 24',
      status: LocationBookingStatus.secured,
    ),
    LocationLedgerItem(
      id: 'led-3',
      label: 'Damage claim hold',
      amount: 'PKR 45,000',
      dueDate: 'Jul 26',
      status: LocationBookingStatus.disputed,
    ),
  ];

  static String bookingStatusLabel(LocationBookingStatus status) {
    return switch (status) {
      LocationBookingStatus.requestReceived => 'REQUEST RECEIVED',
      LocationBookingStatus.underNegotiation => 'UNDER NEGOTIATION',
      LocationBookingStatus.contractPending => 'CONTRACT PENDING',
      LocationBookingStatus.depositPending => 'DEPOSIT PENDING',
      LocationBookingStatus.secured => 'SECURED BOOKING',
      LocationBookingStatus.inProgress => 'IN PROGRESS',
      LocationBookingStatus.closed => 'CLOSED',
      LocationBookingStatus.disputed => 'DISPUTED',
    };
  }
}

class LocationOwnerDemoStore extends ChangeNotifier {
  LocationOwnerDemoStore._()
      : prices = List.of(LocationOwnerDemoData.seedPrices),
        rules = List.of(LocationOwnerDemoData.seedRules),
        inspection = List.of(LocationOwnerDemoData.seedInspection);

  static final instance = LocationOwnerDemoStore._();

  String activePropertyId = LocationOwnerDemoData.properties.first.id;
  int listingStep = 1;
  bool listingSubmitted = false;
  bool exactAddressEncrypted = true;
  bool contractRulesSynced = false;
  bool pricingPublished = false;
  bool checkInConfirmed = false;
  bool checkOutConfirmed = false;
  bool damageClaimOpen = false;
  int? damageClaimAmount;
  String? activeBookingLabel;
  String requestFilter = 'All';
  bool listingPowerBackup = true;
  bool listingAccessible = true;
  String listingCity = '';
  String listingArea = '';
  String listingExactAddress = '';
  String listingCapacity = '';
  String listingParking = '';
  String listingAvailableAreas = '';
  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Map<String, LocationBookingStatus> _requestStatuses = {};
  final Map<int, LocationCalendarStatus> calendar = {
    1: LocationCalendarStatus.available,
    2: LocationCalendarStatus.tentativeHold,
    3: LocationCalendarStatus.booked,
    4: LocationCalendarStatus.available,
    5: LocationCalendarStatus.blocked,
    6: LocationCalendarStatus.maintenance,
    7: LocationCalendarStatus.available,
    8: LocationCalendarStatus.tentativeHold,
    9: LocationCalendarStatus.booked,
    10: LocationCalendarStatus.available,
    11: LocationCalendarStatus.available,
    12: LocationCalendarStatus.blocked,
    13: LocationCalendarStatus.available,
    14: LocationCalendarStatus.available,
  };

  List<LocationPriceItem> prices;
  List<LocationRuleItem> rules;
  List<LocationInspectionItem> inspection;

  LocationProperty get activeProperty => LocationOwnerDemoData.properties
      .firstWhere((property) => property.id == activePropertyId);

  List<LocationTask> get activeTasks => LocationOwnerDemoData.tasks
      .where(
        (task) =>
            !completedTasks.contains(task.id) &&
            !snoozedTasks.contains(task.id),
      )
      .toList();

  LocationBookingStatus requestStatus(LocationBookingRequest request) {
    return _requestStatuses[request.id] ?? request.status;
  }

  int get depositAmount =>
      prices.firstWhere((price) => price.id == 'deposit').amount;

  int get depositHeldAmount =>
      (damageClaimOpen || !checkOutConfirmed) ? depositAmount : 0;

  int get depositReleasedAmount =>
      (checkOutConfirmed && !damageClaimOpen) ? depositAmount : 0;

  int get depositClaimedAmount =>
      damageClaimOpen ? (damageClaimAmount ?? 0) : 0;

  List<LocationLedgerItem> get visibleLedger => LocationOwnerDemoData.ledger
      .where((item) => item.id != 'led-3' || damageClaimOpen)
      .toList();

  void setActiveProperty(String id) {
    activePropertyId = id;
    notifyListeners();
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void submitListing() {
    listingSubmitted = true;
    listingStep = 3;
    notifyListeners();
  }

  void setListingStep(int step) {
    listingStep = step.clamp(1, 3);
    notifyListeners();
  }

  void setExactAddressEncrypted(bool value) {
    exactAddressEncrypted = value;
    notifyListeners();
  }

  void setCalendarStatus(int day, LocationCalendarStatus status) {
    calendar[day] = status;
    notifyListeners();
  }

  void updatePrice(String id, {int? amount, bool? enabled}) {
    prices = prices
        .map(
          (price) => price.id == id
              ? price.copyWith(amount: amount, enabled: enabled)
              : price,
        )
        .toList();
    pricingPublished = false;
    notifyListeners();
  }

  void publishPricing() {
    pricingPublished = true;
    notifyListeners();
  }

  void toggleRule(String id) {
    rules = rules
        .map((rule) =>
            rule.id == id ? rule.copyWith(allowed: !rule.allowed) : rule)
        .toList();
    contractRulesSynced = false;
    notifyListeners();
  }

  void syncRulesToContract() {
    contractRulesSynced = true;
    notifyListeners();
  }

  void resetRules() {
    rules = List.of(LocationOwnerDemoData.seedRules);
    contractRulesSynced = false;
    notifyListeners();
  }

  void setRequestFilter(String filter) {
    requestFilter = filter;
    notifyListeners();
  }

  void acceptRequest(String id) {
    _requestStatuses[id] = LocationBookingStatus.contractPending;
    final request =
        LocationOwnerDemoData.requests.firstWhere((r) => r.id == id);
    activeBookingLabel = request.project;
    completedTasks.add('task-request');
    notifyListeners();
  }

  void counterRequest(String id) {
    _requestStatuses[id] = LocationBookingStatus.underNegotiation;
    notifyListeners();
  }

  void rejectRequest(String id) {
    _requestStatuses[id] = LocationBookingStatus.closed;
    completedTasks.add('task-request');
    notifyListeners();
  }

  void captureInspection(String id, {bool issue = false}) {
    inspection = inspection
        .map(
          (item) => item.id == id
              ? item.copyWith(
                  stage: issue
                      ? LocationInspectionStage.issue
                      : LocationInspectionStage.captured,
                )
              : item,
        )
        .toList();
    notifyListeners();
  }

  void confirmCheckIn() {
    checkInConfirmed = true;
    completedTasks.add('task-checkin');
    notifyListeners();
  }

  void confirmCheckOut() {
    checkOutConfirmed = true;
    completedTasks.add('task-deposit');
    notifyListeners();
  }

  void fileDamageClaim({required int amount}) {
    damageClaimOpen = true;
    damageClaimAmount = amount;
    notifyListeners();
  }

  void resolveClaim() {
    damageClaimOpen = false;
    damageClaimAmount = null;
    notifyListeners();
  }

  void setListingPowerBackup(bool value) {
    listingPowerBackup = value;
    notifyListeners();
  }

  void setListingAccessible(bool value) {
    listingAccessible = value;
    notifyListeners();
  }

  void saveListingDraft({
    required String city,
    required String area,
    required String exactAddress,
    required String capacity,
    required String parking,
    required String availableAreas,
  }) {
    listingCity = city;
    listingArea = area;
    listingExactAddress = exactAddress;
    listingCapacity = capacity;
    listingParking = parking;
    listingAvailableAreas = availableAreas;
    notifyListeners();
  }
}
