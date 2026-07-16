import 'package:flutter/material.dart';

import '../models/media_equipment_models.dart';
import '../routes/media_equipment_routes.dart';

class MediaEquipmentDemoData {
  MediaEquipmentDemoData._();

  static const profile = MediaProviderProfile(
    id: 'MEP-101',
    name: 'FrameForge Rentals',
    type: 'Business',
    city: 'Lahore',
    coverage: 'Lahore, Islamabad, Karachi',
    verification: 'KYB verified',
    serviceCategories: 'Camera, lens, lighting, drone, audio, operators',
    bio:
        'Premium cinema equipment rentals with verified serials, trained operators and insured handover workflows.',
    imageUrl:
        'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
    rating: 4.9,
  );

  static const inventory = [
    MediaInventoryItem(
      id: 'EQ-RED-01',
      category: 'Camera',
      modelName: 'RED Komodo 6K',
      serial: 'RDK-6K-7781',
      condition: 'Excellent',
      dayRate: 85000,
      deposit: 220000,
      city: 'Lahore',
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
      available: true,
    ),
    MediaInventoryItem(
      id: 'EQ-LENS-24',
      category: 'Lens',
      modelName: 'Cooke Mini S4/i Set',
      serial: 'CKE-S4-24100',
      condition: 'Calibrated',
      dayRate: 70000,
      deposit: 180000,
      city: 'Lahore',
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
      available: true,
    ),
    MediaInventoryItem(
      id: 'EQ-LIGHT-10',
      category: 'Light',
      modelName: 'Aputure 600D Pro Kit',
      serial: 'APT-600D-4472',
      condition: 'Good',
      dayRate: 32000,
      deposit: 90000,
      city: 'Islamabad',
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
      available: true,
    ),
    MediaInventoryItem(
      id: 'EQ-DRONE-03',
      category: 'Drone',
      modelName: 'DJI Inspire 3',
      serial: 'DJI-I3-9950',
      condition: 'Excellent',
      dayRate: 95000,
      deposit: 260000,
      city: 'Karachi',
      imageUrl:
          'https://images.unsplash.com/photo-1508614589041-895b88991e3e?auto=format&fit=crop&w=1200&q=80',
      available: false,
    ),
    MediaInventoryItem(
      id: 'EQ-AUD-02',
      category: 'Audio',
      modelName: 'Sound Devices 833 Kit',
      serial: 'SD-833-1182',
      condition: 'Excellent',
      dayRate: 42000,
      deposit: 100000,
      city: 'Lahore',
      imageUrl:
          'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?auto=format&fit=crop&w=1200&q=80',
      available: true,
    ),
  ];

  static const metrics = [
    MediaMetric(
      label: 'Today',
      value: '5',
      delta: '3 pickups',
      icon: Icons.local_shipping_outlined,
      tone: MediaTone.blue,
      route: MediaEquipmentRoutes.availability,
    ),
    MediaMetric(
      label: 'Requests',
      value: '8',
      delta: '2 urgent',
      icon: Icons.inbox_outlined,
      tone: MediaTone.gold,
      route: MediaEquipmentRoutes.requests,
    ),
    MediaMetric(
      label: 'Utilization',
      value: '72%',
      delta: '+9 this week',
      icon: Icons.query_stats_outlined,
      tone: MediaTone.green,
      route: MediaEquipmentRoutes.earnings,
    ),
    MediaMetric(
      label: 'Rating',
      value: '4.9',
      delta: 'quality score',
      icon: Icons.star_outline_rounded,
      tone: MediaTone.purple,
      route: MediaEquipmentRoutes.earnings,
    ),
  ];

  static const tasks = [
    MediaTask(
      id: 'task-pickup',
      title: 'RED Komodo pickup due',
      subtitle: 'Serial scan and accessories proof required before release.',
      route: MediaEquipmentRoutes.handover,
      icon: Icons.qr_code_scanner_rounded,
      tone: MediaTone.gold,
    ),
    MediaTask(
      id: 'task-return',
      title: 'Drone return inspection',
      subtitle: 'Check propellers, batteries and gimbal condition.',
      route: MediaEquipmentRoutes.returns,
      icon: Icons.assignment_return_outlined,
      tone: MediaTone.blue,
    ),
    MediaTask(
      id: 'task-request',
      title: 'Premium camera crew request',
      subtitle: 'Producer asks for revised transport and overtime terms.',
      route: MediaEquipmentRoutes.requests,
      icon: Icons.edit_note_outlined,
      tone: MediaTone.green,
    ),
  ];

  static const packages = [
    MediaPackageItem(
      id: 'PKG-BASIC',
      label: 'Basic Shoot Package',
      items: 'Camera + light kit + audio',
      operatorIncluded: false,
      price: 145000,
      terms: '10 hours, pickup from Lahore hub',
    ),
    MediaPackageItem(
      id: 'PKG-PREMIUM',
      label: 'Premium Camera Crew',
      items: 'RED + Cooke lenses + DOP assistant',
      operatorIncluded: true,
      price: 310000,
      terms: '12 hours, operator and assistant included',
    ),
    MediaPackageItem(
      id: 'PKG-DRONE',
      label: 'Drone Package',
      items: 'DJI Inspire 3 + licensed pilot',
      operatorIncluded: true,
      price: 180000,
      terms: 'Weather clause applies',
    ),
  ];

  static const requests = [
    MediaBookingRequest(
      id: 'MER-640',
      project: 'River Lights',
      producer: 'Ayaan Films',
      dates: 'Jul 20 - Jul 24',
      city: 'Lahore',
      budget: 'PKR 720,000',
      items: 'RED Komodo, Cooke lenses, lights',
      status: MediaBookingStatus.requestReceived,
      imageUrl:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
    ),
    MediaBookingRequest(
      id: 'MER-711',
      project: 'Metro Hearts',
      producer: 'Niazi Studio',
      dates: 'Aug 2',
      city: 'Karachi',
      budget: 'PKR 260,000',
      items: 'Drone package, pilot, insurance proof',
      status: MediaBookingStatus.underNegotiation,
      imageUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=1200&q=80',
    ),
    MediaBookingRequest(
      id: 'MER-825',
      project: 'Northern Sky',
      producer: 'Orbit Brands',
      dates: 'Aug 11 - Aug 12',
      city: 'Islamabad',
      budget: 'PKR 390,000',
      items: 'Lighting truck, audio kit, monitors',
      status: MediaBookingStatus.secured,
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const seedTerms = [
    MediaTermItem(
      id: 'daily',
      label: 'Daily base rate',
      note: 'Standard 10-hour production day.',
      amount: 145000,
      enabled: true,
      icon: Icons.today_outlined,
    ),
    MediaTermItem(
      id: 'operator',
      label: 'Operator extra',
      note: 'Camera or drone operator per day.',
      amount: 55000,
      enabled: true,
      icon: Icons.engineering_outlined,
    ),
    MediaTermItem(
      id: 'assistant',
      label: 'Assistant',
      note: 'Camera assistant / lighting tech.',
      amount: 28000,
      enabled: true,
      icon: Icons.person_add_alt_outlined,
    ),
    MediaTermItem(
      id: 'transport',
      label: 'Transport',
      note: 'Within city logistics and load-in.',
      amount: 35000,
      enabled: true,
      icon: Icons.local_shipping_outlined,
    ),
    MediaTermItem(
      id: 'overtime',
      label: 'Overtime hour',
      note: 'Applies after agreed day limit.',
      amount: 16000,
      enabled: true,
      icon: Icons.more_time_outlined,
    ),
    MediaTermItem(
      id: 'deposit',
      label: 'Security deposit',
      note: 'Held until return inspection closes.',
      amount: 220000,
      enabled: true,
      icon: Icons.verified_user_outlined,
    ),
  ];

  static const seedInspection = [
    MediaInspectionItem(
      id: 'red',
      itemName: 'RED Komodo 6K',
      serial: 'RDK-6K-7781',
      beforeImage:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=900&q=80',
      afterImage:
          'https://images.unsplash.com/photo-1519183071298-a2962be96f83?auto=format&fit=crop&w=900&q=80',
      accessories: 'Body cap, 2 cards, top handle, cage',
      stage: MediaInspectionStage.pending,
    ),
    MediaInspectionItem(
      id: 'lens',
      itemName: 'Cooke Mini S4/i Set',
      serial: 'CKE-S4-24100',
      beforeImage:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=900&q=80',
      afterImage:
          'https://images.unsplash.com/photo-1510127034890-ba27508e9f1c?auto=format&fit=crop&w=900&q=80',
      accessories: '24/35/50/75/100mm, front caps',
      stage: MediaInspectionStage.pending,
    ),
    MediaInspectionItem(
      id: 'audio',
      itemName: 'Sound Devices 833 Kit',
      serial: 'SD-833-1182',
      beforeImage:
          'https://images.unsplash.com/photo-1590602847861-f357a9332bbc?auto=format&fit=crop&w=900&q=80',
      afterImage:
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=900&q=80',
      accessories: 'Recorder, boom, 2 lavs, 4 batteries',
      stage: MediaInspectionStage.pending,
    ),
  ];

  static const ledger = [
    MediaLedgerItem(
      id: 'mel-1',
      label: 'Premium package deposit',
      amount: 'PKR 220,000',
      dueDate: 'Jul 18',
      status: MediaBookingStatus.depositPending,
    ),
    MediaLedgerItem(
      id: 'mel-2',
      label: 'RED + lenses rental',
      amount: 'PKR 510,000',
      dueDate: 'Jul 24',
      status: MediaBookingStatus.secured,
    ),
    MediaLedgerItem(
      id: 'mel-3',
      label: 'Missing battery hold',
      amount: 'PKR 32,000',
      dueDate: 'Jul 26',
      status: MediaBookingStatus.disputed,
    ),
  ];

  static String bookingStatusLabel(MediaBookingStatus status) {
    return switch (status) {
      MediaBookingStatus.requestReceived => 'REQUEST RECEIVED',
      MediaBookingStatus.underNegotiation => 'UNDER NEGOTIATION',
      MediaBookingStatus.contractPending => 'CONTRACT PENDING',
      MediaBookingStatus.depositPending => 'DEPOSIT PENDING',
      MediaBookingStatus.secured => 'SECURED BOOKING',
      MediaBookingStatus.inProgress => 'IN PROGRESS',
      MediaBookingStatus.returned => 'RETURNED',
      MediaBookingStatus.closed => 'CLOSED',
      MediaBookingStatus.rejected => 'REJECTED',
      MediaBookingStatus.disputed => 'DISPUTED',
    };
  }
}

class MediaEquipmentDemoStore extends ChangeNotifier {
  MediaEquipmentDemoStore._()
      : inventory = List.of(MediaEquipmentDemoData.inventory),
        terms = List.of(MediaEquipmentDemoData.seedTerms),
        handover = List.of(MediaEquipmentDemoData.seedInspection),
        returns = List.of(MediaEquipmentDemoData.seedInspection);

  static final instance = MediaEquipmentDemoStore._();

  String activeItemId = MediaEquipmentDemoData.inventory.first.id;
  String inventoryFilter = 'All';
  String requestFilter = 'All';
  int packageStep = 1;
  bool packageSubmitted = false;
  bool profilePublished = true;
  bool termsPublished = false;
  bool handoverConfirmed = false;
  bool returnConfirmed = false;
  bool damageClaimOpen = false;
  int? damageClaimAmount;
  String? activeBookingLabel;
  String profileName = MediaEquipmentDemoData.profile.name;
  String profileCoverage = MediaEquipmentDemoData.profile.coverage;
  String packageDraftName = 'Premium Camera Crew';
  String packageDraftPrice = '310000';
  String packageDraftTerms = '12 hours, operator included';
  bool packageDraftOperatorIncluded = true;
  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Set<String> selectedPackageItems = {'EQ-RED-01', 'EQ-LENS-24'};
  final Map<String, MediaBookingStatus> _requestStatuses = {};
  final List<MediaPackageItem> publishedPackages = [];

  final Map<int, MediaAvailabilityStatus> calendar = {
    1: MediaAvailabilityStatus.available,
    2: MediaAvailabilityStatus.hold,
    3: MediaAvailabilityStatus.booked,
    4: MediaAvailabilityStatus.transit,
    5: MediaAvailabilityStatus.available,
    6: MediaAvailabilityStatus.maintenance,
    7: MediaAvailabilityStatus.available,
    8: MediaAvailabilityStatus.hold,
    9: MediaAvailabilityStatus.booked,
    10: MediaAvailabilityStatus.available,
    11: MediaAvailabilityStatus.available,
    12: MediaAvailabilityStatus.transit,
    13: MediaAvailabilityStatus.available,
    14: MediaAvailabilityStatus.available,
  };

  List<MediaInventoryItem> inventory;
  List<MediaTermItem> terms;
  List<MediaInspectionItem> handover;
  List<MediaInspectionItem> returns;

  MediaInventoryItem get activeItem => inventory.firstWhere(
        (item) => item.id == activeItemId,
        orElse: () => inventory.first,
      );

  List<MediaTask> get activeTasks => MediaEquipmentDemoData.tasks
      .where(
        (task) =>
            !completedTasks.contains(task.id) &&
            !snoozedTasks.contains(task.id),
      )
      .toList();

  MediaBookingStatus requestStatus(MediaBookingRequest request) {
    return _requestStatuses[request.id] ?? request.status;
  }

  int get depositAmount => activeItem.deposit;

  int get depositHeldAmount =>
      (damageClaimOpen || !returnConfirmed) ? depositAmount : 0;

  int get depositReleasedAmount =>
      (returnConfirmed && !damageClaimOpen) ? depositAmount : 0;

  int get depositClaimedAmount =>
      damageClaimOpen ? (damageClaimAmount ?? 0) : 0;

  List<MediaLedgerItem> get visibleLedger => MediaEquipmentDemoData.ledger
      .where((item) => item.id != 'mel-3' || damageClaimOpen)
      .toList();

  void setActiveItem(String id) {
    activeItemId = id;
    notifyListeners();
  }

  void setInventoryFilter(String filter) {
    inventoryFilter = filter;
    notifyListeners();
  }

  void setRequestFilter(String filter) {
    requestFilter = filter;
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

  void toggleInventoryAvailability(String id) {
    inventory = inventory
        .map((item) =>
            item.id == id ? item.copyWith(available: !item.available) : item)
        .toList();
    notifyListeners();
  }

  bool addDemoInventoryItem() {
    if (inventory.any((item) => item.id == 'EQ-MON-07')) return false;
    inventory = [
      ...inventory,
      const MediaInventoryItem(
        id: 'EQ-MON-07',
        category: 'Monitor',
        modelName: 'SmallHD Cine 7',
        serial: 'SHD-C7-4510',
        condition: 'New',
        dayRate: 22000,
        deposit: 65000,
        city: 'Lahore',
        imageUrl:
            'https://images.unsplash.com/photo-1533246860975-b290f87773f8?auto=format&fit=crop&w=1200&q=80',
        available: true,
      ),
    ];
    activeItemId = 'EQ-MON-07';
    notifyListeners();
    return true;
  }

  void setPackageStep(int step) {
    packageStep = step.clamp(1, 3);
    notifyListeners();
  }

  void togglePackageItem(String id) {
    if (selectedPackageItems.contains(id)) {
      selectedPackageItems.remove(id);
    } else {
      selectedPackageItems.add(id);
    }
    packageSubmitted = false;
    notifyListeners();
  }

  void submitPackage({
    required String label,
    required int price,
    required String terms,
    required bool operatorIncluded,
  }) {
    final itemNames = inventory
        .where((item) => selectedPackageItems.contains(item.id))
        .map((item) => item.modelName)
        .join(', ');
    publishedPackages.add(
      MediaPackageItem(
        id: 'PKG-CUSTOM-${publishedPackages.length + 1}',
        label: label,
        items: itemNames,
        operatorIncluded: operatorIncluded,
        price: price,
        terms: terms,
      ),
    );
    packageSubmitted = true;
    packageStep = 3;
    notifyListeners();
  }

  void savePackageDraft({
    required String name,
    required String price,
    required String terms,
    required bool operatorIncluded,
  }) {
    packageDraftName = name;
    packageDraftPrice = price;
    packageDraftTerms = terms;
    packageDraftOperatorIncluded = operatorIncluded;
    notifyListeners();
  }

  void setCalendarStatus(int day, MediaAvailabilityStatus status) {
    calendar[day] = status;
    notifyListeners();
  }

  void updateTerm(String id, {int? amount, bool? enabled}) {
    terms = terms
        .map(
          (item) => item.id == id
              ? item.copyWith(amount: amount, enabled: enabled)
              : item,
        )
        .toList();
    termsPublished = false;
    notifyListeners();
  }

  void resetTerms() {
    terms = List.of(MediaEquipmentDemoData.seedTerms);
    termsPublished = false;
    notifyListeners();
  }

  void publishTerms() {
    termsPublished = true;
    notifyListeners();
  }

  void acceptRequest(String id) {
    _requestStatuses[id] = MediaBookingStatus.contractPending;
    final request =
        MediaEquipmentDemoData.requests.firstWhere((r) => r.id == id);
    activeBookingLabel = request.project;
    completedTasks.add('task-request');
    notifyListeners();
  }

  void counterRequest(String id) {
    _requestStatuses[id] = MediaBookingStatus.underNegotiation;
    notifyListeners();
  }

  void rejectRequest(String id) {
    _requestStatuses[id] = MediaBookingStatus.rejected;
    completedTasks.add('task-request');
    notifyListeners();
  }

  void captureHandover(String id, {bool issue = false}) {
    handover = handover
        .map((item) => item.id == id
            ? item.copyWith(
                stage: issue
                    ? MediaInspectionStage.issue
                    : MediaInspectionStage.captured,
              )
            : item)
        .toList();
    notifyListeners();
  }

  void captureReturn(String id, {bool missing = false}) {
    returns = returns
        .map((item) => item.id == id
            ? item.copyWith(
                stage: missing
                    ? MediaInspectionStage.missing
                    : MediaInspectionStage.verified,
              )
            : item)
        .toList();
    notifyListeners();
  }

  void confirmHandover() {
    handoverConfirmed = true;
    completedTasks.add('task-pickup');
    notifyListeners();
  }

  void confirmReturn() {
    returnConfirmed = true;
    completedTasks.add('task-return');
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

  void toggleProfilePublished() {
    profilePublished = !profilePublished;
    notifyListeners();
  }

  void updateProfile({required String name, required String coverage}) {
    profileName = name;
    profileCoverage = coverage;
    notifyListeners();
  }
}
