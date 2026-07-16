import 'package:flutter/material.dart';

import '../models/legal_partner_models.dart';
import '../routes/legal_partner_routes.dart';

class LegalPartnerDemoData {
  LegalPartnerDemoData._();

  static const firmName = 'LexBridge Legal Desk';
  static const heroImage =
      'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=1400&q=80';

  static const metrics = [
    LegalMetric(
      label: 'Queue',
      value: '18',
      delta: '4 high risk',
      icon: Icons.article_outlined,
      tone: LegalTone.gold,
      route: LegalPartnerRoutes.home,
    ),
    LegalMetric(
      label: 'SLA',
      value: '92%',
      delta: 'on-time reviews',
      icon: Icons.timer_outlined,
      tone: LegalTone.green,
      route: LegalPartnerRoutes.contractReview,
    ),
    LegalMetric(
      label: 'Templates',
      value: '7',
      delta: 'pending governance',
      icon: Icons.library_books_outlined,
      tone: LegalTone.blue,
      route: LegalPartnerRoutes.templateReview,
    ),
    LegalMetric(
      label: 'Billing',
      value: '1.8M',
      delta: 'PKR this month',
      icon: Icons.receipt_long_outlined,
      tone: LegalTone.purple,
      route: LegalPartnerRoutes.billing,
    ),
  ];

  static const tasks = [
    LegalTask(
      id: 'task-review-river',
      title: 'Review River Lights talent agreement',
      subtitle: 'SLA expires in 2h 10m; exclusivity clause flagged.',
      route: LegalPartnerRoutes.contractReview,
      icon: Icons.gavel_outlined,
      tone: LegalTone.gold,
    ),
    LegalTask(
      id: 'task-addendum',
      title: 'Approve pinned negotiation addendum',
      subtitle: 'Usage rights update before signature.',
      route: LegalPartnerRoutes.addendumReview,
      icon: Icons.post_add_outlined,
      tone: LegalTone.blue,
    ),
    LegalTask(
      id: 'task-template',
      title: 'Submit template governance change',
      subtitle: 'Brand integration payment clause needs platform approval.',
      route: LegalPartnerRoutes.templateReview,
      icon: Icons.library_books_outlined,
      tone: LegalTone.green,
    ),
    LegalTask(
      id: 'task-billing',
      title: 'Finalize premium review invoice',
      subtitle: 'Three completed matters ready for billing.',
      route: LegalPartnerRoutes.billing,
      icon: Icons.receipt_long_outlined,
      tone: LegalTone.purple,
    ),
  ];

  static const reviewRequests = [
    LegalReviewRequest(
      id: 'lg-river',
      title: 'River Lights Talent Agreement',
      owner: 'Maha Productions',
      counterparty: 'Ayesha Khan',
      contractType: 'Talent booking',
      sla: '2h 10m',
      assignedLawyer: 'Hina Qureshi',
      risk: 'High - category exclusivity',
      status: LegalStatus.urgent,
      imageUrl:
          'https://images.unsplash.com/photo-1521791136064-7986c2920216?auto=format&fit=crop&w=1400&q=80',
    ),
    LegalReviewRequest(
      id: 'lg-brand',
      title: 'Nova Cola Sponsor Agreement',
      owner: 'Nova Cola Pakistan',
      counterparty: 'Northstar Films',
      contractType: 'Brand sponsorship',
      sla: '6h 35m',
      assignedLawyer: 'Omar Sheikh',
      risk: 'Medium - approval rights',
      status: LegalStatus.reviewing,
      imageUrl:
          'https://images.unsplash.com/photo-1551836022-d5d88e9218df?auto=format&fit=crop&w=1400&q=80',
    ),
    LegalReviewRequest(
      id: 'lg-location',
      title: 'Heritage Villa Location Contract',
      owner: 'Indus Pictures',
      counterparty: 'Amina Estate Trust',
      contractType: 'Location booking',
      sla: '1d 4h',
      assignedLawyer: 'Sana Mir',
      risk: 'Low - restoration bond',
      status: LegalStatus.clarification,
      imageUrl:
          'https://images.unsplash.com/photo-1505664194779-8beaceb93744?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const clauseRisks = [
    LegalClauseRisk(
      id: 'risk-exclusivity',
      clause: 'Clause 4.2 - Exclusivity',
      issue: 'Category lockout is broader than the selected production dates.',
      recommendation: 'Limit exclusivity to confirmed shoot and promo windows.',
      status: LegalStatus.urgent,
    ),
    LegalClauseRisk(
      id: 'risk-payment',
      clause: 'Clause 6.1 - Payment Release',
      issue: 'Milestone release depends on ambiguous content approval.',
      recommendation: 'Tie release to platform verified proof state.',
      status: LegalStatus.reviewing,
    ),
    LegalClauseRisk(
      id: 'risk-cancellation',
      clause: 'Clause 8.3 - Cancellation',
      issue: 'Force majeure wording omits location safety closure.',
      recommendation: 'Add safety closure and permit refusal language.',
      status: LegalStatus.correctionRequested,
    ),
  ];

  static const templateChanges = [
    LegalTemplateChange(
      id: 'tmpl-brand',
      template: 'Brand Integration Agreement',
      clause: 'Payment proof and approval release',
      proposedChange:
          'Add platform-verified proof state before final campaign release.',
      reason:
          'Avoid ambiguity between client creative approval and payment proof.',
      status: LegalStatus.templatePending,
    ),
    LegalTemplateChange(
      id: 'tmpl-location',
      template: 'Location Booking Contract',
      clause: 'Damage bond and inspection evidence',
      proposedChange:
          'Require timestamped check-in and check-out evidence before bond release.',
      reason: 'Align legal terms with location owner inspection workflow.',
      status: LegalStatus.reviewing,
    ),
  ];

  static const addendums = [
    LegalAddendumItem(
      id: 'add-brand',
      title: 'Nova Cola usage-rights addendum',
      sourceDecision: 'Pinned negotiation: 9-month digital usage',
      affectedContract: 'Nova Cola Sponsor Agreement',
      dueDate: 'Today',
      status: LegalStatus.addendumPending,
      imageUrl:
          'https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&w=1200&q=80',
    ),
    LegalAddendumItem(
      id: 'add-talent',
      title: 'Talent overtime addendum',
      sourceDecision: 'Project-room decision: one night shoot extension',
      affectedContract: 'River Lights Talent Agreement',
      dueDate: 'Jul 18',
      status: LegalStatus.reviewing,
      imageUrl:
          'https://images.unsplash.com/photo-1450101499163-c8848c66ca85?auto=format&fit=crop&w=1200&q=80',
    ),
    LegalAddendumItem(
      id: 'add-location',
      title: 'Location restoration addendum',
      sourceDecision: 'Pinned decision: rain cover and garden restoration',
      affectedContract: 'Heritage Villa Location Contract',
      dueDate: 'Jul 21',
      status: LegalStatus.approved,
      imageUrl:
          'https://images.unsplash.com/photo-1505664194779-8beaceb93744?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const billing = [
    LegalBillingRecord(
      id: 'bill-river',
      matter: 'River Lights Talent Agreement',
      client: 'Maha Productions',
      turnaround: '3h 42m',
      invoice: 'PKR 220K',
      notes: 'High-risk exclusivity review with one correction request.',
      status: LegalStatus.completed,
    ),
    LegalBillingRecord(
      id: 'bill-brand',
      matter: 'Nova Cola Sponsor Agreement',
      client: 'Nova Cola Pakistan',
      turnaround: '5h 20m',
      invoice: 'PKR 310K',
      notes: 'Usage-rights and approval workflow review.',
      status: LegalStatus.billed,
    ),
    LegalBillingRecord(
      id: 'bill-location',
      matter: 'Heritage Villa Location Contract',
      client: 'Indus Pictures',
      turnaround: '1d 1h',
      invoice: 'PKR 145K',
      notes: 'Bond evidence language and permit references.',
      status: LegalStatus.completed,
    ),
    LegalBillingRecord(
      id: 'bill-template',
      matter: 'Brand Integration Template Review',
      client: 'CineConnect Admin',
      turnaround: 'Pending',
      invoice: 'PKR 90K',
      notes: 'Governance change waiting for platform approval.',
      status: LegalStatus.templatePending,
    ),
  ];

  static String statusLabel(LegalStatus status) {
    return switch (status) {
      LegalStatus.queued => 'Queued',
      LegalStatus.urgent => 'Urgent',
      LegalStatus.reviewing => 'Reviewing',
      LegalStatus.clarification => 'Clarification',
      LegalStatus.correctionRequested => 'Correction',
      LegalStatus.approved => 'Approved',
      LegalStatus.escalated => 'Escalated',
      LegalStatus.templatePending => 'Template Pending',
      LegalStatus.addendumPending => 'Addendum Pending',
      LegalStatus.completed => 'Completed',
      LegalStatus.billed => 'Billed',
      LegalStatus.blocked => 'Blocked',
    };
  }
}

class LegalPartnerDemoStore extends ChangeNotifier {
  LegalPartnerDemoStore._()
      : _requestStatuses = {
          for (final item in LegalPartnerDemoData.reviewRequests)
            item.id: item.status,
        },
        _addendumStatuses = {
          for (final item in LegalPartnerDemoData.addendums)
            item.id: item.status,
        },
        _billingStatuses = {
          for (final item in LegalPartnerDemoData.billing) item.id: item.status,
        };

  static final instance = LegalPartnerDemoStore._();

  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Map<String, LegalStatus> _requestStatuses;
  final Map<String, LegalStatus> _addendumStatuses;
  final Map<String, LegalStatus> _billingStatuses;

  String queueFilter = 'All';
  String billingFilter = 'All';
  bool templateSubmitted = false;
  int annotationCount = 7;
  int auditEvents = 22;

  List<LegalTask> get activeTasks => LegalPartnerDemoData.tasks
      .where((task) => !completedTasks.contains(task.id))
      .where((task) => !snoozedTasks.contains(task.id))
      .toList();

  LegalReviewRequest get primaryRequest =>
      LegalPartnerDemoData.reviewRequests.first;

  LegalStatus requestStatus(LegalReviewRequest request) {
    return _requestStatuses[request.id] ?? request.status;
  }

  LegalStatus addendumStatus(LegalAddendumItem item) {
    return _addendumStatuses[item.id] ?? item.status;
  }

  LegalStatus billingStatus(LegalBillingRecord item) {
    return _billingStatuses[item.id] ?? item.status;
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void setQueueFilter(String filter) {
    queueFilter = filter;
    notifyListeners();
  }

  void setBillingFilter(String filter) {
    billingFilter = filter;
    notifyListeners();
  }

  void approveRequest(String id) {
    _requestStatuses[id] = LegalStatus.approved;
    auditEvents++;
    notifyListeners();
  }

  void requestCorrection(String id) {
    _requestStatuses[id] = LegalStatus.correctionRequested;
    annotationCount++;
    auditEvents++;
    notifyListeners();
  }

  void escalateRequest(String id) {
    _requestStatuses[id] = LegalStatus.escalated;
    auditEvents++;
    notifyListeners();
  }

  void submitTemplateChange() {
    templateSubmitted = true;
    auditEvents++;
    notifyListeners();
  }

  void approveAddendum(String id) {
    _addendumStatuses[id] = LegalStatus.approved;
    auditEvents++;
    notifyListeners();
  }

  void correctAddendum(String id) {
    _addendumStatuses[id] = LegalStatus.correctionRequested;
    auditEvents++;
    notifyListeners();
  }

  void markBilled(String id) {
    _billingStatuses[id] = LegalStatus.billed;
    notifyListeners();
  }
}
