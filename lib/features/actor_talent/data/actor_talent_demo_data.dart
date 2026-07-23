import 'package:flutter/material.dart';

import '../models/actor_talent_models.dart';
import '../routes/actor_talent_routes.dart';

class ActorTalentDemoData {
  ActorTalentDemoData._();

  static const profileImage =
      'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80';

  static const media = [
    ActorMediaAsset(
      id: 'headshot-primary',
      url:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
      title: 'Primary headshot',
      category: 'Headshot',
      meta: 'Public cover',
      fallbackIcon: Icons.person_outline_rounded,
    ),
    ActorMediaAsset(
      id: 'drama-reel',
      url:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1200&q=80',
      title: 'Drama reel frame',
      category: 'Drama',
      meta: '02:10',
      fallbackIcon: Icons.movie_creation_outlined,
    ),
    ActorMediaAsset(
      id: 'ad-reel',
      url:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?auto=format&fit=crop&w=1200&q=80',
      title: 'Commercial clip',
      category: 'Ads',
      meta: '00:42',
      fallbackIcon: Icons.campaign_outlined,
    ),
    ActorMediaAsset(
      id: 'theatre',
      url:
          'https://images.unsplash.com/photo-1503095396549-807759245b35?auto=format&fit=crop&w=1200&q=80',
      title: 'Theatre production',
      category: 'Theatre',
      meta: 'Stage',
      fallbackIcon: Icons.theater_comedy_outlined,
    ),
    ActorMediaAsset(
      id: 'voice',
      url:
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=1200&q=80',
      title: 'Voice sample booth',
      category: 'Voice',
      meta: '01:15',
      fallbackIcon: Icons.mic_none_rounded,
    ),
  ];

  static const opportunities = [
    ActorOpportunity(
      id: 'BK-2048',
      type: ActorOpportunityType.directOffer,
      projectTitle: 'River Lights',
      role: 'Supporting Lead',
      producer: 'Ayaan Films',
      city: 'Lahore',
      dates: 'Jul 20 - Jul 24',
      fee: 'PKR 420,000',
      directorRating: 4.8,
      expiry: '18h left',
      status: ActorBookingStatus.sent,
      imageUrl:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1200&q=80',
      notes:
          'Five shoot days, wardrobe provided, evening exterior scenes, verified producer profile.',
    ),
    ActorOpportunity(
      id: 'AUD-118',
      type: ActorOpportunityType.auditionInvite,
      projectTitle: 'Metro Hearts',
      role: 'Lead Audition',
      producer: 'Niazi Studio',
      city: 'Karachi',
      dates: 'Self-tape due Jul 17',
      fee: 'PKR 650,000',
      directorRating: 4.6,
      expiry: '2d left',
      status: ActorBookingStatus.underNegotiation,
      imageUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=1200&q=80',
      notes:
          'Self-tape audition with Urdu and English sides. Travel covered after selection.',
    ),
    ActorOpportunity(
      id: 'CAST-77',
      type: ActorOpportunityType.castingCall,
      projectTitle: 'Northern Sky',
      role: 'Commercial Family Role',
      producer: 'Orbit Brands',
      city: 'Islamabad',
      dates: 'Aug 2',
      fee: 'PKR 160,000',
      directorRating: 4.9,
      expiry: '5d left',
      status: ActorBookingStatus.sent,
      imageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
      notes:
          'One-day TVC. Usage is digital only for 6 months. No exclusivity requested.',
    ),
  ];

  static const tasks = [
    ActorTask(
      id: 'task-offer',
      title: 'River Lights offer expires soon',
      subtitle: 'Respond before the 18h window closes.',
      route: ActorTalentRoutes.offerDetail,
      icon: Icons.timer_outlined,
      tone: ActorTone.gold,
    ),
    ActorTask(
      id: 'task-contract',
      title: 'Contract pending signature',
      subtitle: 'Review agreement and payment terms.',
      route: ActorTalentRoutes.contracts,
      icon: Icons.edit_document,
      tone: ActorTone.blue,
    ),
    ActorTask(
      id: 'task-payment',
      title: 'Confirm received payment',
      subtitle: 'PKR 180,000 deposit is verified.',
      route: ActorTalentRoutes.earnings,
      icon: Icons.payments_outlined,
      tone: ActorTone.green,
    ),
  ];

  static const metrics = [
    ActorMetric(
      label: 'New Matches',
      value: '8',
      delta: '+3 direct',
      icon: Icons.auto_awesome_outlined,
      tone: ActorTone.blue,
      route: ActorTalentRoutes.opportunities,
    ),
    ActorMetric(
      label: 'Pending Actions',
      value: '3',
      delta: 'needs reply',
      icon: Icons.priority_high_rounded,
      tone: ActorTone.gold,
      route: ActorTalentRoutes.offerDetail,
    ),
    ActorMetric(
      label: 'Earnings',
      value: '1.24M',
      delta: 'PKR secured',
      icon: Icons.account_balance_wallet_outlined,
      tone: ActorTone.green,
      route: ActorTalentRoutes.earnings,
    ),
    ActorMetric(
      label: 'Rating',
      value: '4.8',
      delta: 'trusted',
      icon: Icons.star_outline_rounded,
      tone: ActorTone.purple,
      route: ActorTalentRoutes.reputation,
    ),
  ];

  static const seedPortfolio = [
    ActorPortfolioItem(
      id: 'pf-headshot',
      title: 'Clean Headshot',
      category: 'Headshots',
      duration: 'Cover',
      status: 'Public',
      imageUrl:
          'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?auto=format&fit=crop&w=900&q=80',
      cover: true,
    ),
    ActorPortfolioItem(
      id: 'pf-drama',
      title: 'Drama Reel',
      category: 'Dramas',
      duration: '02:10',
      status: 'Moderation',
      imageUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1200&q=80',
    ),
    ActorPortfolioItem(
      id: 'pf-ad',
      title: 'Bank TVC',
      category: 'TVCs / Ads',
      duration: '00:42',
      status: 'Public',
      imageUrl:
          'https://images.unsplash.com/photo-1536440136628-849c177e76a1?auto=format&fit=crop&w=1200&q=80',
    ),
    ActorPortfolioItem(
      id: 'pf-voice',
      title: 'Urdu Self-tape Intro',
      category: 'Self-tapes / Intro',
      duration: '01:15',
      status: 'Private',
      imageUrl:
          'https://images.unsplash.com/photo-1598488035139-bdbb2231ce04?auto=format&fit=crop&w=1200&q=80',
    ),
    ActorPortfolioItem(
      id: 'pf-editorial',
      title: 'Editorial Character Stills',
      category: 'Editorial',
      duration: 'Gallery',
      status: 'Public',
      imageUrl:
          'https://images.unsplash.com/photo-1529139574466-a303027c1d8b?auto=format&fit=crop&w=1200&q=80',
    ),
    ActorPortfolioItem(
      id: 'pf-film',
      title: 'Independent Film Scene',
      category: 'Films / Movies',
      duration: '01:38',
      status: 'Public',
      imageUrl:
          'https://images.unsplash.com/photo-1478720568477-152d9b164e26?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const seedRates = [
    ActorRateItem(
      id: 'per-day',
      label: 'Per day',
      amount: 85000,
      negotiable: true,
      category: 'Core',
    ),
    ActorRateItem(
      id: 'per-project',
      label: 'Per project',
      amount: 420000,
      negotiable: true,
      category: 'Core',
    ),
    ActorRateItem(
      id: 'episode',
      label: 'Per episode',
      amount: 95000,
      negotiable: false,
      category: 'Series',
    ),
    ActorRateItem(
      id: 'rehearsal',
      label: 'Rehearsal day',
      amount: 30000,
      negotiable: true,
      category: 'Production',
    ),
    ActorRateItem(
      id: 'overtime',
      label: 'Overtime hour',
      amount: 12000,
      negotiable: false,
      category: 'Production',
    ),
    ActorRateItem(
      id: 'travel',
      label: 'Travel day',
      amount: 45000,
      negotiable: true,
      category: 'Travel',
    ),
    ActorRateItem(
      id: 'usage',
      label: 'Special usage',
      amount: 180000,
      negotiable: true,
      category: 'Rights',
    ),
  ];

  static const payments = [
    ActorPaymentMilestone(
      id: 'pay-1',
      label: 'Deposit',
      amount: 'PKR 180,000',
      dueDate: 'Jul 16',
      status: ActorBookingStatus.underVerification,
    ),
    ActorPaymentMilestone(
      id: 'pay-2',
      label: 'Shoot completion',
      amount: 'PKR 160,000',
      dueDate: 'Jul 25',
      status: ActorBookingStatus.paymentPending,
    ),
    ActorPaymentMilestone(
      id: 'pay-3',
      label: 'Final release',
      amount: 'PKR 80,000',
      dueDate: 'Jul 29',
      status: ActorBookingStatus.secured,
    ),
  ];

  static const reviews = [
    ActorReview(
      reviewer: 'Maha Qureshi',
      project: 'City Lanterns',
      text: 'Prepared, punctual and sharp with continuity notes.',
      rating: 5,
      date: 'Jun 2026',
    ),
    ActorReview(
      reviewer: 'Ayaan Films',
      project: 'Studio Blue',
      text: 'Strong emotional range and quick response during negotiation.',
      rating: 4.7,
      date: 'May 2026',
    ),
  ];

  static String statusLabel(ActorBookingStatus status) {
    return switch (status) {
      ActorBookingStatus.sent => 'SENT',
      ActorBookingStatus.underNegotiation => 'UNDER NEGOTIATION',
      ActorBookingStatus.termsApproved => 'TERMS APPROVED',
      ActorBookingStatus.contractPending => 'CONTRACT PENDING',
      ActorBookingStatus.paymentPending => 'PAYMENT PENDING',
      ActorBookingStatus.underVerification => 'UNDER VERIFICATION',
      ActorBookingStatus.secured => 'SECURED BOOKING',
      ActorBookingStatus.closed => 'CLOSED',
      ActorBookingStatus.disputed => 'DISPUTED',
    };
  }
}

class ActorTalentDemoStore extends ChangeNotifier {
  ActorTalentDemoStore._()
      : portfolioItems = List.of(ActorTalentDemoData.seedPortfolio),
        rates = List.of(ActorTalentDemoData.seedRates);

  static final instance = ActorTalentDemoStore._();

  int profileCompleteness = 78;
  bool profileSubmittedForReview = false;
  bool contractSigned = false;
  bool receiptConfirmed = false;
  bool paymentIssueOpen = false;
  String selectedOpportunityTab = 'All';
  String profileStageName = 'Ali Raza';
  String profileRealName = 'Ali Raza Khan';
  String profileCity = 'Lahore';
  String profileLanguages = 'Urdu, Punjabi, English';
  String profileSkills = 'Drama, commercial, theatre, voice';
  String profileCredits = '2 dramas, 4 TVCs, 1 theatre tour';
  String profileInstagram = '@ali.raza.actor';
  String profileFollowers = '42k';
  String profileWorkHistory =
      'ARY drama supporting lead, bank TVC, theatre tour';
  String profileAgeRange = '25-35';
  String profileHeight = '5 ft 10 in';
  String agency = 'Independent';
  String preferredCities = 'Lahore, Islamabad';
  String travelRadius = 'Domestic with notice';
  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Set<String> blockedUsers = {'Unknown casting DM'};
  final Map<String, ActorBookingStatus> _opportunityStatuses = {};
  final Map<int, ActorAvailabilityStatus> availability = {
    1: ActorAvailabilityStatus.available,
    2: ActorAvailabilityStatus.available,
    3: ActorAvailabilityStatus.tentative,
    4: ActorAvailabilityStatus.booked,
    5: ActorAvailabilityStatus.unavailable,
    6: ActorAvailabilityStatus.available,
    7: ActorAvailabilityStatus.available,
    8: ActorAvailabilityStatus.tentative,
    9: ActorAvailabilityStatus.booked,
    10: ActorAvailabilityStatus.available,
    11: ActorAvailabilityStatus.available,
    12: ActorAvailabilityStatus.unavailable,
    13: ActorAvailabilityStatus.available,
    14: ActorAvailabilityStatus.available,
  };

  List<ActorPortfolioItem> portfolioItems;
  List<ActorRateItem> rates;

  List<ActorTask> get activeTasks => ActorTalentDemoData.tasks
      .where(
        (task) =>
            !completedTasks.contains(task.id) &&
            !snoozedTasks.contains(task.id),
      )
      .toList();

  ActorBookingStatus opportunityStatus(ActorOpportunity opportunity) {
    return _opportunityStatuses[opportunity.id] ?? opportunity.status;
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void updateProfile({
    required String stageName,
    required String realName,
    required String city,
    required String languages,
    required String skills,
    required String credits,
    required String instagram,
    required String followers,
    required String workHistory,
    required String ageRange,
    required String height,
    required String agencyName,
  }) {
    profileStageName = stageName;
    profileRealName = realName;
    profileCity = city;
    profileLanguages = languages;
    profileSkills = skills;
    profileCredits = credits;
    profileInstagram = instagram;
    profileFollowers = followers;
    profileWorkHistory = workHistory;
    profileAgeRange = ageRange;
    profileHeight = height;
    agency = agencyName;
    profileCompleteness = 92;
    profileSubmittedForReview = true;
    notifyListeners();
  }

  void saveProfileDraft({
    required String stageName,
    required String realName,
    required String city,
    required String languages,
    required String skills,
    required String credits,
    required String instagram,
    required String followers,
    required String workHistory,
    required String ageRange,
    required String height,
    required String agencyName,
  }) {
    profileStageName = stageName;
    profileRealName = realName;
    profileCity = city;
    profileLanguages = languages;
    profileSkills = skills;
    profileCredits = credits;
    profileInstagram = instagram;
    profileFollowers = followers;
    profileWorkHistory = workHistory;
    profileAgeRange = ageRange;
    profileHeight = height;
    agency = agencyName;
    notifyListeners();
  }

  void setOpportunityTab(String value) {
    selectedOpportunityTab = value;
    notifyListeners();
  }

  void acceptOffer(String id) {
    _opportunityStatuses[id] = ActorBookingStatus.termsApproved;
    completedTasks.add('task-offer');
    notifyListeners();
  }

  void rejectOffer(String id) {
    _opportunityStatuses[id] = ActorBookingStatus.closed;
    completedTasks.add('task-offer');
    notifyListeners();
  }

  void holdDates(String id) {
    _opportunityStatuses[id] = ActorBookingStatus.underNegotiation;
    availability[20] = ActorAvailabilityStatus.tentative;
    availability[21] = ActorAvailabilityStatus.tentative;
    notifyListeners();
  }

  void sendCounteroffer(String id) {
    _opportunityStatuses[id] = ActorBookingStatus.underNegotiation;
    completedTasks.add('task-offer');
    notifyListeners();
  }

  void signContract() {
    contractSigned = true;
    _opportunityStatuses['BK-2048'] = ActorBookingStatus.paymentPending;
    completedTasks.add('task-contract');
    notifyListeners();
  }

  void confirmReceipt() {
    receiptConfirmed = true;
    completedTasks.add('task-payment');
    notifyListeners();
  }

  void raisePaymentIssue() {
    paymentIssueOpen = true;
    _opportunityStatuses['BK-2048'] = ActorBookingStatus.disputed;
    notifyListeners();
  }

  void setAvailability(int day, ActorAvailabilityStatus status) {
    availability[day] = status;
    notifyListeners();
  }

  void updateTravelLimits({
    required String cities,
    required String radius,
  }) {
    preferredCities = cities;
    travelRadius = radius;
    notifyListeners();
  }

  void setCover(String id) {
    portfolioItems = portfolioItems
        .map((item) => item.copyWith(cover: item.id == id))
        .toList();
    notifyListeners();
  }

  void addPortfolioDemoItem() {
    portfolioItems = [
      ActorPortfolioItem(
        id: 'pf-new-${portfolioItems.length + 1}',
        title: 'Self Intro Video',
        category: 'Self-tapes / Intro',
        duration: '00:55',
        status: 'Moderation',
        imageUrl:
            'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=1200&q=80',
      ),
      ...portfolioItems,
    ];
    notifyListeners();
  }

  void updateRate(String id, {int? amount, bool? negotiable}) {
    rates = rates
        .map(
          (rate) => rate.id == id
              ? rate.copyWith(amount: amount, negotiable: negotiable)
              : rate,
        )
        .toList();
    notifyListeners();
  }

  void resetRates() {
    rates = List.of(ActorTalentDemoData.seedRates);
    notifyListeners();
  }

  void unblock(String name) {
    blockedUsers.remove(name);
    notifyListeners();
  }

  void block(String name) {
    blockedUsers.add(name);
    notifyListeners();
  }

  final Map<String, ActorCounterofferDraft> _drafts = {};

  ActorCounterofferDraft? draftFor(String offerId) => _drafts[offerId];

  void saveDraft(String offerId, ActorCounterofferDraft draft) {
    _drafts[offerId] = draft;
    notifyListeners();
  }

  void clearDraft(String offerId) {
    _drafts.remove(offerId);
    notifyListeners();
  }
}

class ActorCounterofferDraft {
  final String amount;
  final String dates;
  final String advance;
  final String conditions;
  final String message;

  const ActorCounterofferDraft({
    required this.amount,
    required this.dates,
    required this.advance,
    required this.conditions,
    required this.message,
  });
}
