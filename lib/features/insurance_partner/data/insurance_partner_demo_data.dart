import 'package:flutter/material.dart';

import '../models/insurance_partner_models.dart';
import '../routes/insurance_partner_routes.dart';

class InsurancePartnerDemoData {
  InsurancePartnerDemoData._();

  static const deskName = 'CineSecure Safety Desk';
  static const heroImage =
      'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=80';

  static const metrics = [
    InsuranceMetric(
      label: 'Policies',
      value: '24',
      delta: '18 active shoots',
      icon: Icons.policy_outlined,
      tone: InsuranceTone.gold,
      route: InsurancePartnerRoutes.records,
    ),
    InsuranceMetric(
      label: 'Claims',
      value: '6',
      delta: '2 evidence needed',
      icon: Icons.assignment_late_outlined,
      tone: InsuranceTone.danger,
      route: InsurancePartnerRoutes.claims,
    ),
    InsuranceMetric(
      label: 'Safety Due',
      value: '9',
      delta: '3 due today',
      icon: Icons.health_and_safety_outlined,
      tone: InsuranceTone.blue,
      route: InsurancePartnerRoutes.safety,
    ),
    InsuranceMetric(
      label: 'Incidents',
      value: '3',
      delta: '1 escalated',
      icon: Icons.warning_amber_outlined,
      tone: InsuranceTone.purple,
      route: InsurancePartnerRoutes.incidents,
    ),
  ];

  static const tasks = [
    InsuranceTask(
      id: 'task-policy-river',
      title: 'Verify River Lights policy document',
      subtitle: 'Night shoot starts tomorrow; fire permit attached.',
      route: InsurancePartnerRoutes.records,
      icon: Icons.policy_outlined,
      tone: InsuranceTone.gold,
    ),
    InsuranceTask(
      id: 'task-claim-drone',
      title: 'Complete drone lens damage evidence',
      subtitle: 'Serial match and after-photo still required.',
      route: InsurancePartnerRoutes.claims,
      icon: Icons.assignment_late_outlined,
      tone: InsuranceTone.danger,
    ),
    InsuranceTask(
      id: 'task-safety-villa',
      title: 'Safety checklist due for Heritage Villa',
      subtitle: 'Generator placement and crowd-control owner signoff.',
      route: InsurancePartnerRoutes.safety,
      icon: Icons.fact_check_outlined,
      tone: InsuranceTone.blue,
    ),
    InsuranceTask(
      id: 'task-incident-slip',
      title: 'Classify set slip incident severity',
      subtitle: 'Corrective action note is waiting for review.',
      route: InsurancePartnerRoutes.incidents,
      icon: Icons.report_problem_outlined,
      tone: InsuranceTone.purple,
    ),
  ];

  static const policies = [
    InsurancePolicy(
      id: 'pol-river',
      project: 'River Lights',
      booking: 'BK-1180',
      insuredParty: 'Maha Productions',
      coverage: 'PKR 18M equipment + public liability',
      validity: 'Jul 15 - Jul 30',
      document: 'CIN-POL-8891.pdf',
      risk: 'High - night water sequence',
      status: InsuranceStatus.highRisk,
      imageUrl:
          'https://images.unsplash.com/photo-1485846234645-a62644f84728?auto=format&fit=crop&w=1400&q=80',
    ),
    InsurancePolicy(
      id: 'pol-villa',
      project: 'Heritage Villa Shoot',
      booking: 'BK-1204',
      insuredParty: 'Indus Pictures',
      coverage: 'PKR 8M property bond',
      validity: 'Jul 17 - Jul 22',
      document: 'CIN-POL-7710.pdf',
      risk: 'Medium - historic interiors',
      status: InsuranceStatus.active,
      imageUrl:
          'https://images.unsplash.com/photo-1523217582562-09d0def993a6?auto=format&fit=crop&w=1400&q=80',
    ),
    InsurancePolicy(
      id: 'pol-drone',
      project: 'Skyline Commercial',
      booking: 'BK-1215',
      insuredParty: 'Falcon Camera House',
      coverage: 'PKR 12M drone and lens package',
      validity: 'Jul 19 - Jul 20',
      document: 'CIN-POL-9014.pdf',
      risk: 'High - aerial work',
      status: InsuranceStatus.pending,
      imageUrl:
          'https://images.unsplash.com/photo-1473968512647-3e447244af8f?auto=format&fit=crop&w=1400&q=80',
    ),
    InsurancePolicy(
      id: 'pol-brand',
      project: 'Nova Cola Launch',
      booking: 'BK-1198',
      insuredParty: 'Nova Cola Pakistan',
      coverage: 'PKR 5M activation liability',
      validity: 'Jul 21 - Aug 05',
      document: 'CIN-POL-8116.pdf',
      risk: 'Low - studio-only',
      status: InsuranceStatus.verified,
      imageUrl:
          'https://images.unsplash.com/photo-1497366754035-f200968a6e72?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const claims = [
    InsuranceClaim(
      id: 'clm-drone-lens',
      title: 'Drone lens impact claim',
      source: 'Equipment return flow',
      policyId: 'pol-drone',
      itemOrRoom: 'Lens SN-DX114 / Drone kit bay',
      adjuster: 'Raza Malik',
      due: 'Today',
      estimate: 'PKR 420K',
      status: InsuranceStatus.evidenceNeeded,
      beforeImageUrl:
          'https://images.unsplash.com/photo-1506947411487-a56738267384?auto=format&fit=crop&w=1200&q=80',
      afterImageUrl:
          'https://images.unsplash.com/photo-1516035069371-29a1b244cc32?auto=format&fit=crop&w=1200&q=80',
    ),
    InsuranceClaim(
      id: 'clm-villa-floor',
      title: 'Villa marble floor scuff',
      source: 'Location checkout',
      policyId: 'pol-villa',
      itemOrRoom: 'Drawing room / east corner',
      adjuster: 'Mina Farooqi',
      due: 'Jul 18',
      estimate: 'PKR 95K',
      status: InsuranceStatus.investigating,
      beforeImageUrl:
          'https://images.unsplash.com/photo-1600607687920-4e2a09cf159d?auto=format&fit=crop&w=1200&q=80',
      afterImageUrl:
          'https://images.unsplash.com/photo-1600566753151-384129cf4e3e?auto=format&fit=crop&w=1200&q=80',
    ),
    InsuranceClaim(
      id: 'clm-lighting',
      title: 'Lighting stand injury report',
      source: 'Crew incident report',
      policyId: 'pol-river',
      itemOrRoom: 'Stage B / rigging lane',
      adjuster: 'Nadia Shah',
      due: 'Jul 20',
      estimate: 'PKR 160K',
      status: InsuranceStatus.openClaim,
      beforeImageUrl:
          'https://images.unsplash.com/photo-1524985069026-dd778a71c7b4?auto=format&fit=crop&w=1200&q=80',
      afterImageUrl:
          'https://images.unsplash.com/photo-1518173946687-a4c8892bbd9f?auto=format&fit=crop&w=1200&q=80',
    ),
  ];

  static const claimEvidence = [
    InsuranceEvidence(
      id: 'ev-before',
      label: 'Before evidence',
      detail: 'Timestamped handover image exists.',
    ),
    InsuranceEvidence(
      id: 'ev-after',
      label: 'After evidence',
      detail: 'Return image attached and readable.',
    ),
    InsuranceEvidence(
      id: 'ev-serial',
      label: 'Serial / room match',
      detail: 'SN-DX114 matches booking inventory.',
    ),
    InsuranceEvidence(
      id: 'ev-signatures',
      label: 'Party signatures',
      detail: 'Provider and producer acknowledgement.',
    ),
    InsuranceEvidence(
      id: 'ev-adjuster',
      label: 'Adjuster note',
      detail: 'Initial cause and estimate recorded.',
      mandatory: false,
    ),
  ];

  static const safetyChecks = [
    InsuranceSafetyCheck(
      id: 'safe-villa',
      shoot: 'Heritage Villa night sequence',
      location: 'Gulberg Heritage Villa',
      responsible: 'Adeel Khan',
      dueDate: 'Today',
      permit: 'Fire + neighborhood NOC',
      risk: 'High - generator and crowd perimeter',
      status: InsuranceStatus.safetyDue,
      imageUrl:
          'https://images.unsplash.com/photo-1500534314209-a25ddb2bd429?auto=format&fit=crop&w=1400&q=80',
    ),
    InsuranceSafetyCheck(
      id: 'safe-river',
      shoot: 'River Lights bridge unit',
      location: 'Ravi riverside road',
      responsible: 'Samia Noor',
      dueDate: 'Jul 17',
      permit: 'Traffic control permit',
      risk: 'High - water and night work',
      status: InsuranceStatus.highRisk,
      imageUrl:
          'https://images.unsplash.com/photo-1500530855697-b586d89ba3ee?auto=format&fit=crop&w=1400&q=80',
    ),
    InsuranceSafetyCheck(
      id: 'safe-studio',
      shoot: 'Nova Cola studio build',
      location: 'Stage 5, Karachi',
      responsible: 'Haris Ali',
      dueDate: 'Jul 21',
      permit: 'Studio safety certificate',
      risk: 'Medium - lighting grid',
      status: InsuranceStatus.completed,
      imageUrl:
          'https://images.unsplash.com/photo-1536240478700-b869070f9279?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const safetySteps = [
    InsuranceSafetyStep(
      id: 'st-permit',
      label: 'Permit documents',
      detail: 'NOC, fire and traffic permits attached.',
    ),
    InsuranceSafetyStep(
      id: 'st-risk',
      label: 'Risk documentation',
      detail: 'Hazards, mitigation and responsible persons logged.',
    ),
    InsuranceSafetyStep(
      id: 'st-evidence',
      label: 'Completion evidence',
      detail: 'Photos for generator, cables and exits uploaded.',
    ),
    InsuranceSafetyStep(
      id: 'st-signature',
      label: 'Responsible signoff',
      detail: 'Producer and safety officer signatures captured.',
    ),
    InsuranceSafetyStep(
      id: 'st-offline',
      label: 'Offline safe draft',
      detail: 'Local checklist draft saved for weak network areas.',
      mandatory: false,
    ),
  ];

  static const incidents = [
    InsuranceIncident(
      id: 'inc-slip',
      title: 'Grip slip near wet floor',
      project: 'River Lights',
      severity: 'Medium',
      date: 'Jul 14',
      parties: 'Grip team, safety officer',
      correctiveAction: 'Added anti-slip mats and blocked wet lane.',
      status: InsuranceStatus.investigating,
    ),
    InsuranceIncident(
      id: 'inc-generator',
      title: 'Generator cable heat warning',
      project: 'Heritage Villa Shoot',
      severity: 'High',
      date: 'Jul 13',
      parties: 'Location owner, electrician',
      correctiveAction: 'Moved cable run and added breaker inspection.',
      status: InsuranceStatus.escalated,
    ),
    InsuranceIncident(
      id: 'inc-crowd',
      title: 'Crowd control barrier moved',
      project: 'Nova Cola Launch',
      severity: 'Low',
      date: 'Jul 11',
      parties: 'Brand field team',
      correctiveAction: 'Reassigned marshal and relabeled barrier line.',
      status: InsuranceStatus.resolved,
    ),
    InsuranceIncident(
      id: 'inc-rigging',
      title: 'Lighting stand near miss',
      project: 'Skyline Commercial',
      severity: 'Medium',
      date: 'Jul 10',
      parties: 'Lighting crew, camera unit',
      correctiveAction: 'Sandbag count increased; aisle markers placed.',
      status: InsuranceStatus.openClaim,
    ),
  ];

  static const incidentChart = [
    InsuranceChartPoint(label: 'Low', value: 4, tone: InsuranceTone.green),
    InsuranceChartPoint(label: 'Medium', value: 7, tone: InsuranceTone.gold),
    InsuranceChartPoint(label: 'High', value: 3, tone: InsuranceTone.danger),
    InsuranceChartPoint(label: 'Resolved', value: 9, tone: InsuranceTone.blue),
  ];

  static String statusLabel(InsuranceStatus status) {
    return switch (status) {
      InsuranceStatus.active => 'Active',
      InsuranceStatus.expiring => 'Expiring',
      InsuranceStatus.pending => 'Pending',
      InsuranceStatus.verified => 'Verified',
      InsuranceStatus.highRisk => 'High Risk',
      InsuranceStatus.openClaim => 'Open Claim',
      InsuranceStatus.investigating => 'Investigating',
      InsuranceStatus.evidenceNeeded => 'Evidence Needed',
      InsuranceStatus.approved => 'Approved',
      InsuranceStatus.rejected => 'Rejected',
      InsuranceStatus.safetyDue => 'Safety Due',
      InsuranceStatus.completed => 'Completed',
      InsuranceStatus.escalated => 'Escalated',
      InsuranceStatus.resolved => 'Resolved',
      InsuranceStatus.draft => 'Draft',
    };
  }
}

class InsurancePartnerDemoStore extends ChangeNotifier {
  InsurancePartnerDemoStore._()
      : _policyStatuses = {
          for (final item in InsurancePartnerDemoData.policies)
            item.id: item.status,
        },
        _claimStatuses = {
          for (final item in InsurancePartnerDemoData.claims)
            item.id: item.status,
        },
        _safetyStatuses = {
          for (final item in InsurancePartnerDemoData.safetyChecks)
            item.id: item.status,
        },
        _incidentStatuses = {
          for (final item in InsurancePartnerDemoData.incidents)
            item.id: item.status,
        };

  static final instance = InsurancePartnerDemoStore._();

  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Set<String> completedEvidence = {'ev-before'};
  final Set<String> completedSafetySteps = {'st-permit'};
  final Map<String, InsuranceStatus> _policyStatuses;
  final Map<String, InsuranceStatus> _claimStatuses;
  final Map<String, InsuranceStatus> _safetyStatuses;
  final Map<String, InsuranceStatus> _incidentStatuses;

  String policyFilter = 'All';
  String incidentFilter = 'All';
  int claimNotes = 3;
  int auditEvents = 31;
  int exportsPrepared = 0;

  List<InsuranceTask> get activeTasks => InsurancePartnerDemoData.tasks
      .where((task) => !completedTasks.contains(task.id))
      .where((task) => !snoozedTasks.contains(task.id))
      .toList();

  InsurancePolicy get primaryPolicy => InsurancePartnerDemoData.policies.first;

  InsuranceClaim get primaryClaim => InsurancePartnerDemoData.claims.first;

  InsuranceSafetyCheck get primarySafety =>
      InsurancePartnerDemoData.safetyChecks.first;

  InsuranceStatus policyStatus(InsurancePolicy policy) {
    return _policyStatuses[policy.id] ?? policy.status;
  }

  InsuranceStatus claimStatus(InsuranceClaim claim) {
    return _claimStatuses[claim.id] ?? claim.status;
  }

  InsuranceStatus safetyStatus(InsuranceSafetyCheck check) {
    return _safetyStatuses[check.id] ?? check.status;
  }

  InsuranceStatus incidentStatus(InsuranceIncident incident) {
    return _incidentStatuses[incident.id] ?? incident.status;
  }

  int get claimProgress => (completedEvidence.length /
          InsurancePartnerDemoData.claimEvidence.length *
          100)
      .round();

  int get safetyProgress => (completedSafetySteps.length /
          InsurancePartnerDemoData.safetySteps.length *
          100)
      .round();

  bool get claimReady => InsurancePartnerDemoData.claimEvidence
      .where((item) => item.mandatory)
      .every((item) => completedEvidence.contains(item.id));

  bool get safetyReady => InsurancePartnerDemoData.safetySteps
      .where((item) => item.mandatory)
      .every((item) => completedSafetySteps.contains(item.id));

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void setPolicyFilter(String filter) {
    policyFilter = filter;
    notifyListeners();
  }

  void setIncidentFilter(String filter) {
    incidentFilter = filter;
    notifyListeners();
  }

  void verifyPolicy(String id) {
    _policyStatuses[id] = InsuranceStatus.verified;
    auditEvents++;
    notifyListeners();
  }

  void flagPolicy(String id) {
    _policyStatuses[id] = InsuranceStatus.highRisk;
    auditEvents++;
    notifyListeners();
  }

  void toggleEvidence(String id) {
    if (!completedEvidence.add(id)) completedEvidence.remove(id);
    notifyListeners();
  }

  void saveClaimDraft() {
    _claimStatuses[primaryClaim.id] = InsuranceStatus.draft;
    auditEvents++;
    notifyListeners();
  }

  void finalizeClaim() {
    _claimStatuses[primaryClaim.id] = InsuranceStatus.investigating;
    claimNotes++;
    auditEvents++;
    notifyListeners();
  }

  void resolveClaim(String id) {
    _claimStatuses[id] = InsuranceStatus.resolved;
    auditEvents++;
    notifyListeners();
  }

  void escalateClaim(String id) {
    _claimStatuses[id] = InsuranceStatus.escalated;
    auditEvents++;
    notifyListeners();
  }

  void toggleSafetyStep(String id) {
    if (!completedSafetySteps.add(id)) completedSafetySteps.remove(id);
    notifyListeners();
  }

  void saveSafetyDraft() {
    _safetyStatuses[primarySafety.id] = InsuranceStatus.draft;
    auditEvents++;
    notifyListeners();
  }

  void completeSafetyCheck() {
    _safetyStatuses[primarySafety.id] = InsuranceStatus.completed;
    auditEvents++;
    notifyListeners();
  }

  void resolveIncident(String id) {
    _incidentStatuses[id] = InsuranceStatus.resolved;
    auditEvents++;
    notifyListeners();
  }

  void escalateIncident(String id) {
    _incidentStatuses[id] = InsuranceStatus.escalated;
    auditEvents++;
    notifyListeners();
  }

  void exportIncidents() {
    exportsPrepared++;
    auditEvents++;
    notifyListeners();
  }
}
