import 'package:flutter/material.dart';

import '../models/brand_sponsor_models.dart';
import '../routes/brand_sponsor_routes.dart';

class BrandSponsorDemoData {
  BrandSponsorDemoData._();

  static const profile = BrandProfile(
    id: 'brand-nova',
    name: 'Nova Cola Pakistan',
    category: 'Beverage / youth culture',
    representative: 'Sara Ahmed, Brand Partnerships',
    billing: 'KYB verified - Karachi billing office',
    trustStatus: 'Verified sponsor',
    imageUrl:
        'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?auto=format&fit=crop&w=1400&q=80',
    description:
        'Premium youth beverage brand sourcing product placement, campaign integrations and launch content across film, web and music properties.',
  );

  static const metrics = [
    BrandMetric(
      label: 'Opportunities',
      value: '6',
      delta: '2 live this week',
      icon: Icons.campaign_outlined,
      tone: BrandTone.gold,
      route: BrandSponsorRoutes.composer,
    ),
    BrandMetric(
      label: 'Applications',
      value: '34',
      delta: '9 awaiting review',
      icon: Icons.inbox_outlined,
      tone: BrandTone.blue,
      route: BrandSponsorRoutes.applications,
    ),
    BrandMetric(
      label: 'Campaigns',
      value: '4',
      delta: '1 approval risk',
      icon: Icons.track_changes_outlined,
      tone: BrandTone.purple,
      route: BrandSponsorRoutes.tracker,
    ),
    BrandMetric(
      label: 'Spend',
      value: '7.8M',
      delta: 'PKR committed',
      icon: Icons.account_balance_wallet_outlined,
      tone: BrandTone.green,
      route: BrandSponsorRoutes.payments,
    ),
  ];

  static const tasks = [
    BrandTask(
      id: 'task-applications',
      title: 'Review River Lights proposals',
      subtitle: 'Four producer applications match the launch brief.',
      route: BrandSponsorRoutes.applications,
      icon: Icons.rate_review_outlined,
      tone: BrandTone.gold,
    ),
    BrandTask(
      id: 'task-approval',
      title: 'Approve product placement proof',
      subtitle: 'Metro Hearts has uploaded the hero bottle frame.',
      route: BrandSponsorRoutes.tracker,
      icon: Icons.fact_check_outlined,
      tone: BrandTone.green,
    ),
    BrandTask(
      id: 'task-terms',
      title: 'Counter exclusivity terms',
      subtitle: 'One negotiation requests category lockout.',
      route: BrandSponsorRoutes.negotiation,
      icon: Icons.handshake_outlined,
      tone: BrandTone.blue,
    ),
    BrandTask(
      id: 'task-payment',
      title: 'Verify milestone payment',
      subtitle: 'Campaign advance is waiting for finance approval.',
      route: BrandSponsorRoutes.payments,
      icon: Icons.payments_outlined,
      tone: BrandTone.purple,
    ),
  ];

  static const opportunities = [
    BrandOpportunity(
      id: 'opp-nova-launch',
      title: 'Nova Cola Summer Launch',
      category: 'Product placement + social content',
      budget: 'PKR 2.4M',
      usage: 'Digital, cinema BTS, 9 months',
      eligibility: 'Youth, music, sports or campus storyline',
      deliverables: 'Hero placement, 2 reels, 6 stills, BTS mention',
      dueDate: 'Applications close Jul 22',
      status: BrandStatus.active,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=80',
    ),
    BrandOpportunity(
      id: 'opp-nova-campus',
      title: 'Campus Beat Integration',
      category: 'Brand integration',
      budget: 'PKR 1.1M',
      usage: 'Streaming promo, 6 months',
      eligibility: 'College or dance-led productions',
      deliverables: 'Scene integration, cast post, 4 usage stills',
      dueDate: 'Draft ready',
      status: BrandStatus.draft,
      imageUrl:
          'https://images.unsplash.com/photo-1516450360452-9312f5e86fc7?auto=format&fit=crop&w=1400&q=80',
    ),
    BrandOpportunity(
      id: 'opp-nova-sports',
      title: 'Night Match Placement',
      category: 'Sponsorship',
      budget: 'PKR 4.3M',
      usage: 'Broadcast snippets, OOH recap, 12 months',
      eligibility: 'Sports, urban action or live-event project',
      deliverables: 'Sideline branding, 3 reels, hero product moment',
      dueDate: 'Negotiation active',
      status: BrandStatus.negotiation,
      imageUrl:
          'https://images.unsplash.com/photo-1517649763962-0c623066013b?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const applications = [
    BrandApplication(
      id: 'app-river',
      applicant: 'Maha Productions',
      type: 'Feature film',
      proposal: 'Natural placement in cafe sequence with lead cast stills.',
      audience: 'Urban drama, 18-34',
      budgetAsk: 'PKR 2.1M',
      status: BrandStatus.reviewing,
      imageUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1400&q=80',
    ),
    BrandApplication(
      id: 'app-metro',
      applicant: 'Northstar Films',
      type: 'Streaming series',
      proposal: 'Bottle integration, behind-the-scenes reels and music cue.',
      audience: 'Streaming youth, 16-30',
      budgetAsk: 'PKR 2.6M',
      status: BrandStatus.shortlisted,
      imageUrl:
          'https://images.unsplash.com/photo-1493246507139-91e8fad9978e?auto=format&fit=crop&w=1400&q=80',
    ),
    BrandApplication(
      id: 'app-orbit',
      applicant: 'Orbit Ads',
      type: 'Digital campaign',
      proposal: 'Dance-led social launch with model creators and product pack.',
      audience: 'Social-first, 15-28',
      budgetAsk: 'PKR 980K',
      status: BrandStatus.pending,
      imageUrl:
          'https://images.unsplash.com/photo-1492684223066-81342ee5ff30?auto=format&fit=crop&w=1400&q=80',
    ),
    BrandApplication(
      id: 'app-indus',
      applicant: 'Indus Pictures',
      type: 'Mountain adventure',
      proposal: 'Lifestyle placement in road-trip sequence and poster usage.',
      audience: 'Family + travel, 20-42',
      budgetAsk: 'PKR 1.8M',
      status: BrandStatus.negotiation,
      imageUrl:
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const terms = [
    BrandTerm(
      id: 'term-river',
      applicant: 'Maha Productions',
      scope: 'Cafe scene product placement plus lead cast photo set.',
      exclusivity: 'No competing beverage in hero cafe scene.',
      approvalRights: 'Brand approval on final placement frame and captions.',
      paymentSchedule: '40% advance, 40% proof approval, 20% completion.',
      status: BrandStatus.negotiation,
    ),
    BrandTerm(
      id: 'term-metro',
      applicant: 'Northstar Films',
      scope: 'Streaming episode placement and BTS social package.',
      exclusivity: 'Category lockout for two scenes only.',
      approvalRights: 'Usage stills require brand approval before release.',
      paymentSchedule: '50% advance, 50% after verified proof.',
      status: BrandStatus.approved,
    ),
  ];

  static const deliverables = [
    BrandDeliverable(
      id: 'del-hero',
      label: 'Hero product placement frame',
      owner: 'Northstar Films',
      dueDate: 'Jul 20',
      proof: 'Uploaded frame proof',
      status: BrandStatus.reviewing,
      imageUrl:
          'https://images.unsplash.com/photo-1516280440614-37939bbacd81?auto=format&fit=crop&w=1200&q=80',
    ),
    BrandDeliverable(
      id: 'del-reels',
      label: 'Two campaign reels',
      owner: 'Orbit Ads',
      dueDate: 'Jul 24',
      proof: 'Awaiting upload',
      status: BrandStatus.pending,
      imageUrl:
          'https://images.unsplash.com/photo-1505686994434-e3cc5abf1330?auto=format&fit=crop&w=1200&q=80',
    ),
    BrandDeliverable(
      id: 'del-stills',
      label: 'Usage stills gallery',
      owner: 'Maha Productions',
      dueDate: 'Jul 26',
      proof: 'Six stills submitted',
      status: BrandStatus.delivered,
      imageUrl:
          'https://images.unsplash.com/photo-1526948128573-703ee1aeb6fa?auto=format&fit=crop&w=1200&q=80',
    ),
    BrandDeliverable(
      id: 'del-approval',
      label: 'Caption approval pack',
      owner: 'Indus Pictures',
      dueDate: 'Jul 29',
      proof: 'Revision requested',
      status: BrandStatus.revision,
      imageUrl:
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const payments = [
    BrandPaymentItem(
      id: 'pay-advance',
      label: 'Campaign advance',
      payer: 'Nova Cola Pakistan',
      payee: 'Northstar Films',
      amount: 'PKR 1.2M',
      dueDate: 'Jul 18',
      status: BrandStatus.paymentPending,
    ),
    BrandPaymentItem(
      id: 'pay-proof',
      label: 'Proof approval milestone',
      payer: 'Nova Cola Pakistan',
      payee: 'Maha Productions',
      amount: 'PKR 840K',
      dueDate: 'Verified',
      status: BrandStatus.verified,
    ),
    BrandPaymentItem(
      id: 'pay-final',
      label: 'Completion release',
      payer: 'Nova Cola Pakistan',
      payee: 'Orbit Ads',
      amount: 'PKR 490K',
      dueDate: 'Jul 30',
      status: BrandStatus.pending,
    ),
    BrandPaymentItem(
      id: 'pay-revision',
      label: 'Revision holdback',
      payer: 'Nova Cola Pakistan',
      payee: 'Indus Pictures',
      amount: 'PKR 380K',
      dueDate: 'Flagged',
      status: BrandStatus.disputed,
    ),
  ];

  static String statusLabel(BrandStatus status) {
    return switch (status) {
      BrandStatus.draft => 'Draft',
      BrandStatus.active => 'Active',
      BrandStatus.pending => 'Pending',
      BrandStatus.reviewing => 'Reviewing',
      BrandStatus.shortlisted => 'Shortlisted',
      BrandStatus.negotiation => 'Negotiation',
      BrandStatus.approved => 'Approved',
      BrandStatus.revision => 'Revision',
      BrandStatus.delivered => 'Delivered',
      BrandStatus.paymentPending => 'Payment Due',
      BrandStatus.verified => 'Verified',
      BrandStatus.closed => 'Closed',
      BrandStatus.disputed => 'Issue',
    };
  }
}

class BrandSponsorDemoStore extends ChangeNotifier {
  BrandSponsorDemoStore._()
      : _applicationStatuses = {
          for (final item in BrandSponsorDemoData.applications)
            item.id: item.status,
        },
        _deliverableStatuses = {
          for (final item in BrandSponsorDemoData.deliverables)
            item.id: item.status,
        },
        _paymentStatuses = {
          for (final item in BrandSponsorDemoData.payments)
            item.id: item.status,
        };

  static final instance = BrandSponsorDemoStore._();

  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Map<String, BrandStatus> _applicationStatuses;
  final Map<String, BrandStatus> _deliverableStatuses;
  final Map<String, BrandStatus> _paymentStatuses;

  String applicationsFilter = 'All';
  String deliverablesFilter = 'All';
  String paymentsFilter = 'All';
  bool profilePublished = true;
  bool assetUploadPending = false;
  int draftsCreated = 1;
  int termVersion = 2;

  List<BrandTask> get activeTasks => BrandSponsorDemoData.tasks
      .where((task) => !completedTasks.contains(task.id))
      .where((task) => !snoozedTasks.contains(task.id))
      .toList();

  BrandOpportunity get primaryOpportunity =>
      BrandSponsorDemoData.opportunities.first;

  BrandTerm get activeTerm => BrandSponsorDemoData.terms.first;

  BrandStatus applicationStatus(BrandApplication item) {
    return _applicationStatuses[item.id] ?? item.status;
  }

  BrandStatus deliverableStatus(BrandDeliverable item) {
    return _deliverableStatuses[item.id] ?? item.status;
  }

  BrandStatus paymentStatus(BrandPaymentItem item) {
    return _paymentStatuses[item.id] ?? item.status;
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void setApplicationsFilter(String filter) {
    applicationsFilter = filter;
    notifyListeners();
  }

  void setDeliverablesFilter(String filter) {
    deliverablesFilter = filter;
    notifyListeners();
  }

  void setPaymentsFilter(String filter) {
    paymentsFilter = filter;
    notifyListeners();
  }

  void toggleProfilePublished() {
    profilePublished = !profilePublished;
    notifyListeners();
  }

  void queueAssetUpload() {
    assetUploadPending = true;
    notifyListeners();
  }

  void createOpportunityDraft() {
    draftsCreated++;
    notifyListeners();
  }

  void shortlistApplication(String id) {
    _applicationStatuses[id] = BrandStatus.shortlisted;
    notifyListeners();
  }

  void negotiateApplication(String id) {
    _applicationStatuses[id] = BrandStatus.negotiation;
    notifyListeners();
  }

  void rejectApplication(String id) {
    _applicationStatuses[id] = BrandStatus.closed;
    notifyListeners();
  }

  void acceptTerms() {
    termVersion++;
    notifyListeners();
  }

  void counterTerms() {
    termVersion++;
    notifyListeners();
  }

  void approveDeliverable(String id) {
    _deliverableStatuses[id] = BrandStatus.approved;
    notifyListeners();
  }

  void requestRevision(String id) {
    _deliverableStatuses[id] = BrandStatus.revision;
    notifyListeners();
  }

  void markDelivered(String id) {
    _deliverableStatuses[id] = BrandStatus.delivered;
    notifyListeners();
  }

  void verifyPayment(String id) {
    _paymentStatuses[id] = BrandStatus.verified;
    notifyListeners();
  }

  void flagPayment(String id) {
    _paymentStatuses[id] = BrandStatus.disputed;
    notifyListeners();
  }
}
