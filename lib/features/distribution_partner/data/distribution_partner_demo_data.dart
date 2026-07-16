import 'package:flutter/material.dart';

import '../models/distribution_partner_models.dart';
import '../routes/distribution_partner_routes.dart';

class DistributionPartnerDemoData {
  DistributionPartnerDemoData._();

  static const deskName = 'CineRelease Partner Desk';
  static const heroImage =
      'https://images.unsplash.com/photo-1489599849927-2ee91cede3ba?auto=format&fit=crop&w=1400&q=80';

  static const metrics = [
    DistributionMetric(
      label: 'Near Release',
      value: '7',
      delta: '3 need handover',
      icon: Icons.rocket_launch_outlined,
      tone: DistributionTone.gold,
      route: DistributionPartnerRoutes.release,
    ),
    DistributionMetric(
      label: 'Contacts',
      value: '42',
      delta: '12 active partners',
      icon: Icons.contacts_outlined,
      tone: DistributionTone.blue,
      route: DistributionPartnerRoutes.contacts,
    ),
    DistributionMetric(
      label: 'Windows',
      value: '5',
      delta: 'planned this month',
      icon: Icons.event_available_outlined,
      tone: DistributionTone.green,
      route: DistributionPartnerRoutes.release,
    ),
    DistributionMetric(
      label: 'Reports',
      value: '18',
      delta: '4 pending review',
      icon: Icons.analytics_outlined,
      tone: DistributionTone.purple,
      route: DistributionPartnerRoutes.reports,
    ),
  ];

  static const tasks = [
    DistributionTask(
      id: 'task-handover-river',
      title: 'Collect River Lights final master',
      subtitle: 'DCP and subtitle metadata are still missing.',
      route: DistributionPartnerRoutes.release,
      icon: Icons.movie_filter_outlined,
      tone: DistributionTone.gold,
    ),
    DistributionTask(
      id: 'task-contact-ott',
      title: 'Update StreamWave territory notes',
      subtitle: 'OTT partner asked for Pakistan-first holdback terms.',
      route: DistributionPartnerRoutes.contacts,
      icon: Icons.contacts_outlined,
      tone: DistributionTone.blue,
    ),
    DistributionTask(
      id: 'task-window',
      title: 'Confirm Eid window visibility plan',
      subtitle: 'Campaign assets need distributor approval before lock.',
      route: DistributionPartnerRoutes.release,
      icon: Icons.event_available_outlined,
      tone: DistributionTone.green,
    ),
    DistributionTask(
      id: 'task-report',
      title: 'Review Gulf territory statement',
      subtitle: 'Revenue report variance requires partner note.',
      route: DistributionPartnerRoutes.reports,
      icon: Icons.analytics_outlined,
      tone: DistributionTone.purple,
    ),
  ];

  static const projects = [
    DistributionProject(
      id: 'ds-river',
      title: 'River Lights',
      producer: 'Maha Productions',
      releaseWindow: 'Aug 08 - Aug 22',
      territories: 'Pakistan, UAE, UK diaspora',
      missingItems: 'DCP, subtitles, censor certificate',
      statusNote: 'Secured booking moving to release handover.',
      status: DistributionStatus.missingItems,
      imageUrl:
          'https://images.unsplash.com/photo-1517604931442-7e0c8ed2963c?auto=format&fit=crop&w=1400&q=80',
    ),
    DistributionProject(
      id: 'ds-nova',
      title: 'Nova Cola Launch Film',
      producer: 'Northstar Films',
      releaseWindow: 'Jul 25 - Aug 05',
      territories: 'Digital Pakistan + GCC',
      missingItems: 'Brand campaign visibility record',
      statusNote: 'Approval pack under partner review.',
      status: DistributionStatus.pending,
      imageUrl:
          'https://images.unsplash.com/photo-1492691527719-9d1e07e534b4?auto=format&fit=crop&w=1400&q=80',
    ),
    DistributionProject(
      id: 'ds-villa',
      title: 'Heritage Villa Teaser',
      producer: 'Indus Pictures',
      releaseWindow: 'Aug 14 - Aug 21',
      territories: 'Cinema teaser + social',
      missingItems: 'Poster approval',
      statusNote: 'Release window ready after poster lock.',
      status: DistributionStatus.ready,
      imageUrl:
          'https://images.unsplash.com/photo-1478720568477-152d9b164e26?auto=format&fit=crop&w=1400&q=80',
    ),
  ];

  static const contacts = [
    DistributorContact(
      id: 'ct-cineplex',
      name: 'CineStar Circuit',
      channel: 'Cinema',
      territory: 'Pakistan',
      contactRole: 'Programming Lead',
      priorProject: 'Karachi Monsoon',
      notes: 'Prefers family titles and clear Thursday delivery windows.',
      status: DistributionStatus.approved,
    ),
    DistributorContact(
      id: 'ct-streamwave',
      name: 'StreamWave MENA',
      channel: 'OTT',
      territory: 'GCC + MENA',
      contactRole: 'Acquisitions Manager',
      priorProject: 'The Last Take',
      notes: 'Needs Arabic subtitle package and holdback note.',
      status: DistributionStatus.pending,
    ),
    DistributorContact(
      id: 'ct-paktv',
      name: 'PakTV Network',
      channel: 'Television',
      territory: 'Pakistan',
      contactRole: 'Content Syndication',
      priorProject: 'Eid Stories',
      notes: 'Requests clean broadcast master and cue sheet.',
      status: DistributionStatus.ready,
    ),
    DistributorContact(
      id: 'ct-diaspora',
      name: 'Diaspora Screens UK',
      channel: 'Cinema',
      territory: 'United Kingdom',
      contactRole: 'Regional Buyer',
      priorProject: 'Punjab Nights',
      notes: 'Weekend family slots available in Bradford and Birmingham.',
      status: DistributionStatus.activeWindow,
    ),
  ];

  static const handoverItems = [
    ReleaseHandoverItem(
      id: 'ho-master',
      label: 'Final master files',
      detail: 'DCP, ProRes master and audio stems uploaded.',
    ),
    ReleaseHandoverItem(
      id: 'ho-metadata',
      label: 'Metadata pack',
      detail: 'Synopsis, cast, runtime, languages and subtitle metadata.',
    ),
    ReleaseHandoverItem(
      id: 'ho-campaign',
      label: 'Campaign visibility records',
      detail: 'Trailer, poster, sponsor visibility and usage proof.',
    ),
    ReleaseHandoverItem(
      id: 'ho-approval',
      label: 'Partner approvals',
      detail: 'Producer, brand and distributor approvals captured.',
    ),
    ReleaseHandoverItem(
      id: 'ho-deadline',
      label: 'Deadline note',
      detail: 'Release window deadline and escalation contact logged.',
      mandatory: false,
    ),
  ];

  static const reports = [
    DistributionReportRecord(
      id: 'rp-cinepak',
      partner: 'CineStar Circuit',
      territory: 'Pakistan',
      channel: 'Cinema',
      audience: '182K admits',
      revenue: 'PKR 31M',
      status: DistributionStatus.submitted,
    ),
    DistributionReportRecord(
      id: 'rp-streamwave',
      partner: 'StreamWave MENA',
      territory: 'GCC',
      channel: 'OTT',
      audience: '1.4M views',
      revenue: 'USD 96K',
      status: DistributionStatus.pending,
    ),
    DistributionReportRecord(
      id: 'rp-uktour',
      partner: 'Diaspora Screens UK',
      territory: 'United Kingdom',
      channel: 'Cinema',
      audience: '41K admits',
      revenue: 'GBP 118K',
      status: DistributionStatus.approved,
    ),
    DistributionReportRecord(
      id: 'rp-tv',
      partner: 'PakTV Network',
      territory: 'Pakistan',
      channel: 'Television',
      audience: '6.8M reach',
      revenue: 'PKR 14M',
      status: DistributionStatus.completed,
    ),
  ];

  static const reportChart = [
    DistributionChartPoint(
        label: 'Cinema', value: 31, tone: DistributionTone.gold),
    DistributionChartPoint(
        label: 'OTT', value: 27, tone: DistributionTone.blue),
    DistributionChartPoint(
        label: 'TV', value: 14, tone: DistributionTone.purple),
    DistributionChartPoint(
        label: 'Events', value: 8, tone: DistributionTone.green),
  ];

  static String statusLabel(DistributionStatus status) {
    return switch (status) {
      DistributionStatus.ready => 'Ready',
      DistributionStatus.missingItems => 'Missing Items',
      DistributionStatus.pending => 'Pending',
      DistributionStatus.approved => 'Approved',
      DistributionStatus.activeWindow => 'Active Window',
      DistributionStatus.submitted => 'Submitted',
      DistributionStatus.completed => 'Completed',
      DistributionStatus.delayed => 'Delayed',
      DistributionStatus.escalated => 'Escalated',
      DistributionStatus.closed => 'Closed',
      DistributionStatus.draft => 'Draft',
    };
  }
}

class DistributionPartnerDemoStore extends ChangeNotifier {
  DistributionPartnerDemoStore._()
      : _projectStatuses = {
          for (final item in DistributionPartnerDemoData.projects)
            item.id: item.status,
        },
        _contactStatuses = {
          for (final item in DistributionPartnerDemoData.contacts)
            item.id: item.status,
        },
        _reportStatuses = {
          for (final item in DistributionPartnerDemoData.reports)
            item.id: item.status,
        };

  static final instance = DistributionPartnerDemoStore._();

  final Set<String> completedTasks = {};
  final Set<String> snoozedTasks = {};
  final Set<String> completedHandover = {'ho-master'};
  final Map<String, DistributionStatus> _projectStatuses;
  final Map<String, DistributionStatus> _contactStatuses;
  final Map<String, DistributionStatus> _reportStatuses;

  String contactFilter = 'All';
  String reportFilter = 'All';
  int auditEvents = 18;
  int exportsPrepared = 0;

  List<DistributionTask> get activeTasks => DistributionPartnerDemoData.tasks
      .where((task) => !completedTasks.contains(task.id))
      .where((task) => !snoozedTasks.contains(task.id))
      .toList();

  DistributionProject get primaryProject =>
      DistributionPartnerDemoData.projects.first;

  int get handoverProgress => (completedHandover.length /
          DistributionPartnerDemoData.handoverItems.length *
          100)
      .round();

  bool get handoverReady => DistributionPartnerDemoData.handoverItems
      .where((item) => item.mandatory)
      .every((item) => completedHandover.contains(item.id));

  DistributionStatus projectStatus(DistributionProject project) {
    return _projectStatuses[project.id] ?? project.status;
  }

  DistributionStatus contactStatus(DistributorContact contact) {
    return _contactStatuses[contact.id] ?? contact.status;
  }

  DistributionStatus reportStatus(DistributionReportRecord report) {
    return _reportStatuses[report.id] ?? report.status;
  }

  void completeTask(String id) {
    completedTasks.add(id);
    notifyListeners();
  }

  void snoozeTask(String id) {
    snoozedTasks.add(id);
    notifyListeners();
  }

  void setContactFilter(String filter) {
    contactFilter = filter;
    notifyListeners();
  }

  void setReportFilter(String filter) {
    reportFilter = filter;
    notifyListeners();
  }

  void approveContact(String id) {
    _contactStatuses[id] = DistributionStatus.approved;
    auditEvents++;
    notifyListeners();
  }

  void activateContact(String id) {
    _contactStatuses[id] = DistributionStatus.activeWindow;
    auditEvents++;
    notifyListeners();
  }

  void toggleHandover(String id) {
    if (!completedHandover.add(id)) completedHandover.remove(id);
    notifyListeners();
  }

  void saveReleaseDraft() {
    _projectStatuses[primaryProject.id] = DistributionStatus.draft;
    auditEvents++;
    notifyListeners();
  }

  void submitReleaseHandover() {
    _projectStatuses[primaryProject.id] = DistributionStatus.submitted;
    auditEvents++;
    notifyListeners();
  }

  void closeReport(String id) {
    _reportStatuses[id] = DistributionStatus.closed;
    auditEvents++;
    notifyListeners();
  }

  void escalateReport(String id) {
    _reportStatuses[id] = DistributionStatus.escalated;
    auditEvents++;
    notifyListeners();
  }

  void exportReports() {
    exportsPrepared++;
    auditEvents++;
    notifyListeners();
  }
}
