import 'package:flutter/material.dart';

import '../models/crew_services_models.dart';
import '../routes/crew_services_routes.dart';

class CrewServicesDemoData {
  CrewServicesDemoData._();

  static const profile = CrewProfile(
    id: 'CRW-118',
    name: 'Northstar Crew',
    service: 'DOP + Gaffer Unit',
    city: 'Lahore',
    coverage: 'Lahore, Islamabad, Murree, Karachi',
    ownedKit: 'ARRI lighting, wireless focus, grip van, monitors',
    experience: '11 years, 74 verified productions',
    dayRate: 185000,
    imageUrl:
        'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1200&q=80',
    rating: 4.9,
  );

  static const metrics = [
    CrewMetric(
      label: 'New Requests',
      value: '6',
      delta: '2 urgent',
      icon: Icons.inbox_outlined,
      tone: CrewTone.gold,
      route: CrewServicesRoutes.requests,
    ),
    CrewMetric(
      label: 'Confirmed Jobs',
      value: '4',
      delta: 'next: Jul 20',
      icon: Icons.movie_filter_outlined,
      tone: CrewTone.blue,
      route: CrewServicesRoutes.availability,
    ),
    CrewMetric(
      label: 'Earnings',
      value: '1.2M',
      delta: 'PKR secured',
      icon: Icons.account_balance_wallet_outlined,
      tone: CrewTone.green,
      route: CrewServicesRoutes.contracts,
    ),
    CrewMetric(
      label: 'Rating',
      value: '4.9',
      delta: 'repeat score',
      icon: Icons.star_outline_rounded,
      tone: CrewTone.purple,
      route: CrewServicesRoutes.ratings,
    ),
  ];

  static const tasks = [
    CrewTask(
      id: 'task-contract',
      title: 'Crew agreement awaiting signature',
      subtitle: 'River Lights payment milestone starts after signature.',
      route: CrewServicesRoutes.contracts,
      icon: Icons.draw_outlined,
      tone: CrewTone.gold,
    ),
    CrewTask(
      id: 'task-request',
      title: 'Counteroffer requested',
      subtitle: 'Producer asked for overtime and travel terms.',
      route: CrewServicesRoutes.requests,
      icon: Icons.edit_note_outlined,
      tone: CrewTone.blue,
    ),
    CrewTask(
      id: 'task-profile',
      title: 'Add latest production stills',
      subtitle: 'Portfolio freshness improves director conversion.',
      route: CrewServicesRoutes.portfolio,
      icon: Icons.photo_library_outlined,
      tone: CrewTone.green,
    ),
  ];

  static const credits = [
    CrewCredit(
      id: 'crd-1',
      title: 'River Lights',
      category: 'Drama',
      role: 'DOP Unit',
      year: '2026',
      imageUrl:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
      featured: true,
    ),
    CrewCredit(
      id: 'crd-2',
      title: 'Metro Hearts',
      category: 'Commercial',
      role: 'Lighting + Grip',
      year: '2025',
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1200&q=80',
      featured: true,
    ),
    CrewCredit(
      id: 'crd-3',
      title: 'Northern Sky',
      category: 'Brand Film',
      role: 'Camera Crew',
      year: '2025',
      imageUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=1200&q=80',
      featured: false,
    ),
  ];

  static const requests = [
    CrewRequest(
      id: 'CRR-801',
      project: 'River Lights',
      producer: 'Ayaan Films',
      dates: 'Jul 20 - Jul 24',
      city: 'Lahore',
      budget: 'PKR 740,000',
      requirement: 'DOP unit, gaffer, focus puller, grip van',
      status: CrewBookingStatus.requestReceived,
      imageUrl:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
    ),
    CrewRequest(
      id: 'CRR-822',
      project: 'Metro Hearts',
      producer: 'Niazi Studio',
      dates: 'Aug 2',
      city: 'Karachi',
      budget: 'PKR 260,000',
      requirement: 'One-day commercial lighting unit',
      status: CrewBookingStatus.underNegotiation,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1200&q=80',
    ),
    CrewRequest(
      id: 'CRR-940',
      project: 'Northern Sky',
      producer: 'Orbit Brands',
      dates: 'Aug 11 - Aug 12',
      city: 'Islamabad',
      budget: 'PKR 430,000',
      requirement: 'Camera team and night shoot lighting',
      status: CrewBookingStatus.secured,
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const ledger = [
    CrewLedgerItem(
      id: 'crl-1',
      label: 'Signing advance',
      amount: 'PKR 185,000',
      dueDate: 'Jul 18',
      status: CrewBookingStatus.paymentPending,
    ),
    CrewLedgerItem(
      id: 'crl-2',
      label: 'Production day milestone',
      amount: 'PKR 370,000',
      dueDate: 'Jul 24',
      status: CrewBookingStatus.secured,
    ),
    CrewLedgerItem(
      id: 'crl-3',
      label: 'Overtime adjustment',
      amount: 'PKR 54,000',
      dueDate: 'Jul 26',
      status: CrewBookingStatus.disputed,
    ),
  ];

  static const reviews = [
    CrewReview(
      id: 'rv-1',
      project: 'River Lights',
      director: 'Ayaan Films',
      rating: 4.9,
      note: 'Fast setup, calm crew lead, strong night-lighting control.',
      status: CrewBookingStatus.closed,
    ),
    CrewReview(
      id: 'rv-2',
      project: 'Metro Hearts',
      director: 'Niazi Studio',
      rating: 4.8,
      note: 'Commercial day stayed on schedule with clean equipment handling.',
      status: CrewBookingStatus.closed,
    ),
    CrewReview(
      id: 'rv-3',
      project: 'Northern Sky',
      director: 'Orbit Brands',
      rating: 4.7,
      note: 'Great coordination and clear safety notes.',
      status: CrewBookingStatus.closed,
    ),
  ];

  static String statusLabel(CrewBookingStatus status) {
    return switch (status) {
      CrewBookingStatus.requestReceived => 'REQUEST RECEIVED',
      CrewBookingStatus.underNegotiation => 'UNDER NEGOTIATION',
      CrewBookingStatus.contractPending => 'CONTRACT PENDING',
      CrewBookingStatus.paymentPending => 'PAYMENT PENDING',
      CrewBookingStatus.secured => 'SECURED BOOKING',
      CrewBookingStatus.inProgress => 'IN PROGRESS',
      CrewBookingStatus.closed => 'CLOSED',
      CrewBookingStatus.rejected => 'REJECTED',
      CrewBookingStatus.disputed => 'DISPUTED',
    };
  }
}

class CrewServicesDemoStore extends ChangeNotifier {
  CrewServicesDemoStore._() : credits = List.of(CrewServicesDemoData.credits);

  static final instance = CrewServicesDemoStore._();

  bool profilePublished = true;
  bool portfolioUploadPending = false;
  bool contractSigned = false;
  bool paymentProofUploaded = false;
  String? activeBookingLabel;
  String profileService = CrewServicesDemoData.profile.service;
  String profileCoverage = CrewServicesDemoData.profile.coverage;
  String requestFilter = 'All';
  String creditFilter = 'All';
  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Map<String, CrewBookingStatus> _requestStatuses = {};
  List<CrewCredit> credits;

  final Map<int, CrewAvailabilityStatus> calendar = {
    1: CrewAvailabilityStatus.available,
    2: CrewAvailabilityStatus.tentative,
    3: CrewAvailabilityStatus.booked,
    4: CrewAvailabilityStatus.available,
    5: CrewAvailabilityStatus.unavailable,
    6: CrewAvailabilityStatus.available,
    7: CrewAvailabilityStatus.available,
    8: CrewAvailabilityStatus.tentative,
    9: CrewAvailabilityStatus.booked,
    10: CrewAvailabilityStatus.available,
    11: CrewAvailabilityStatus.available,
    12: CrewAvailabilityStatus.unavailable,
    13: CrewAvailabilityStatus.available,
    14: CrewAvailabilityStatus.available,
  };

  List<CrewTask> get activeTasks => CrewServicesDemoData.tasks
      .where(
        (task) =>
            !completedTasks.contains(task.id) &&
            !snoozedTasks.contains(task.id),
      )
      .toList();

  CrewBookingStatus requestStatus(CrewRequest request) {
    return _requestStatuses[request.id] ?? request.status;
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void setRequestFilter(String filter) {
    requestFilter = filter;
    notifyListeners();
  }

  void setCreditFilter(String filter) {
    creditFilter = filter;
    notifyListeners();
  }

  void toggleProfilePublished() {
    profilePublished = !profilePublished;
    notifyListeners();
  }

  void addPortfolioUpload() {
    portfolioUploadPending = true;
    notifyListeners();
  }

  void toggleFeaturedCredit(String id) {
    credits = credits
        .map((credit) => credit.id == id
            ? credit.copyWith(featured: !credit.featured)
            : credit)
        .toList();
    notifyListeners();
  }

  void setCalendarStatus(int day, CrewAvailabilityStatus status) {
    calendar[day] = status;
    notifyListeners();
  }

  void acceptRequest(String id) {
    _requestStatuses[id] = CrewBookingStatus.contractPending;
    final request = CrewServicesDemoData.requests.firstWhere(
      (r) => r.id == id,
    );
    activeBookingLabel = request.project;
    if (id == 'CRR-822') completedTasks.add('task-request');
    notifyListeners();
  }

  void counterRequest(String id) {
    _requestStatuses[id] = CrewBookingStatus.underNegotiation;
    notifyListeners();
  }

  void rejectRequest(String id) {
    _requestStatuses[id] = CrewBookingStatus.rejected;
    if (id == 'CRR-822') completedTasks.add('task-request');
    notifyListeners();
  }

  void signContract() {
    contractSigned = true;
    completedTasks.add('task-contract');
    notifyListeners();
  }

  void uploadPaymentProof() {
    paymentProofUploaded = true;
    notifyListeners();
  }

  void updateProfile({required String service, required String coverage}) {
    profileService = service;
    profileCoverage = coverage;
    notifyListeners();
  }
}
