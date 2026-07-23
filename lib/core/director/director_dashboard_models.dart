import '../../features/director_producer/models/dp_payment.dart';
import '../../features/director_producer/models/dp_project.dart';
import '../../features/director_producer/models/dp_schedule_item.dart';
import '../../features/director_producer/widgets/dp_status_chip.dart';
import '../projects/project_models.dart';

class DirectorDashboard {
  final DirectorDashboardSummary summary;
  final List<Project> projects;
  final List<DirectorTimelineItem> timeline;
  final List<DirectorPaymentAttention> paymentsAttention;
  final List<DirectorPipelineItem> pipeline;
  final List<DirectorActivityItem> activity;
  final List<DirectorPriorityAction> priorityActions;

  const DirectorDashboard({
    required this.summary,
    required this.projects,
    required this.timeline,
    required this.paymentsAttention,
    required this.pipeline,
    required this.activity,
    required this.priorityActions,
  });

  factory DirectorDashboard.fromJson(Map<String, dynamic> json) {
    return DirectorDashboard(
      summary: DirectorDashboardSummary.fromJson(
        json['summary'] as Map<String, dynamic>? ?? const {},
      ),
      projects: (json['projects'] as List<dynamic>? ?? const [])
          .map((item) => Project.fromJson(item as Map<String, dynamic>))
          .toList(),
      timeline: (json['timeline'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorTimelineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      paymentsAttention:
          (json['payments_attention'] as List<dynamic>? ?? const [])
              .map((item) => DirectorPaymentAttention.fromJson(
                    item as Map<String, dynamic>,
                  ))
              .toList(),
      pipeline: (json['pipeline'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorPipelineItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      activity: (json['activity'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorActivityItem.fromJson(item as Map<String, dynamic>))
          .toList(),
      priorityActions: (json['priority_actions'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorPriorityAction.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  List<DpProject> get dpProjects =>
      projects.map((project) => project.toDpProject()).toList();

  List<DpScheduleItem> get dpTimeline =>
      timeline.map((item) => item.toDpScheduleItem()).toList();

  List<DpPayment> get dpPayments =>
      paymentsAttention.map((item) => item.toDpPayment()).toList();
}

class DirectorSchedule {
  final List<DirectorScheduleEvent> events;
  final List<DirectorScheduleRisk> risks;
  final DirectorCallSheet callSheet;

  const DirectorSchedule({
    required this.events,
    required this.risks,
    required this.callSheet,
  });

  factory DirectorSchedule.fromJson(Map<String, dynamic> json) {
    return DirectorSchedule(
      events: (json['events'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorScheduleEvent.fromJson(item as Map<String, dynamic>))
          .toList(),
      risks: (json['risks'] as List<dynamic>? ?? const [])
          .map((item) =>
              DirectorScheduleRisk.fromJson(item as Map<String, dynamic>))
          .toList(),
      callSheet: DirectorCallSheet.fromJson(
        json['call_sheet'] as Map<String, dynamic>? ?? const {},
      ),
    );
  }

  List<DpScheduleItem> get dpEvents =>
      events.map((event) => event.toDpScheduleItem()).toList();
}

class DirectorScheduleEvent {
  final String kind;
  final String publicId;
  final String projectId;
  final String projectTitle;
  final String title;
  final String? subtitle;
  final String location;
  final List<String> stakeholders;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String status;
  final String riskLevel;

  const DirectorScheduleEvent({
    required this.kind,
    required this.publicId,
    required this.projectId,
    required this.projectTitle,
    required this.title,
    required this.subtitle,
    required this.location,
    required this.stakeholders,
    required this.startsAt,
    required this.endsAt,
    required this.status,
    required this.riskLevel,
  });

  factory DirectorScheduleEvent.fromJson(Map<String, dynamic> json) {
    return DirectorScheduleEvent(
      kind: json['kind'] as String? ?? 'event',
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Project',
      title: json['title'] as String? ?? 'Production event',
      subtitle: json['subtitle'] as String?,
      location: json['location'] as String? ?? 'Pakistan',
      stakeholders: (json['stakeholders'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .toList(),
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      status: json['status'] as String? ?? 'scheduled',
      riskLevel: json['risk_level'] as String? ?? 'low',
    );
  }

  DpScheduleItem toDpScheduleItem() {
    return DpScheduleItem(
      id: publicId,
      date: _dateLabel(startsAt),
      time: _timeLabel(startsAt),
      project: projectTitle,
      location: title,
      stakeholders: [
        if (subtitle?.isNotEmpty == true) subtitle!,
        ...stakeholders,
      ],
      status: _titleCase(status),
      conflict: riskLevel == 'high' || riskLevel == 'critical',
    );
  }
}

class DirectorScheduleRisk {
  final String kind;
  final String projectId;
  final String projectTitle;
  final String title;
  final String message;
  final String riskLevel;

  const DirectorScheduleRisk({
    required this.kind,
    required this.projectId,
    required this.projectTitle,
    required this.title,
    required this.message,
    required this.riskLevel,
  });

  factory DirectorScheduleRisk.fromJson(Map<String, dynamic> json) {
    return DirectorScheduleRisk(
      kind: json['kind'] as String? ?? 'risk',
      projectId: json['project_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Project',
      title: json['title'] as String? ?? 'Schedule risk',
      message: json['message'] as String? ?? '',
      riskLevel: json['risk_level'] as String? ?? 'medium',
    );
  }

  DpTone get tone {
    return switch (riskLevel) {
      'high' || 'critical' => DpTone.danger,
      'medium' => DpTone.warning,
      'low' => DpTone.info,
      _ => DpTone.neutral,
    };
  }
}

class DirectorCallSheet {
  final String status;
  final String label;
  final DirectorScheduleEvent? event;
  final List<String> crew;
  final String weatherStatus;
  final String weatherSummary;

  const DirectorCallSheet({
    required this.status,
    required this.label,
    required this.event,
    required this.crew,
    required this.weatherStatus,
    required this.weatherSummary,
  });

  factory DirectorCallSheet.fromJson(Map<String, dynamic> json) {
    final eventJson = json['event'] as Map<String, dynamic>?;
    final weather = json['weather'] as Map<String, dynamic>? ?? const {};
    return DirectorCallSheet(
      status: json['status'] as String? ?? 'empty',
      label: json['label'] as String? ?? 'No live events',
      event:
          eventJson == null ? null : DirectorScheduleEvent.fromJson(eventJson),
      crew: (json['crew'] as List<dynamic>? ?? const [])
          .map((item) => '$item')
          .toList(),
      weatherStatus: weather['status'] as String? ?? 'provider_not_configured',
      weatherSummary: weather['summary'] as String? ??
          'Weather provider not connected yet.',
    );
  }

  List<DpScheduleItem> get dpEvents =>
      event == null ? const [] : [event!.toDpScheduleItem()];
}

class DirectorDashboardSummary {
  final int activeProjects;
  final int projectCount;
  final int committedBudgetMinor;
  final int paidMinor;
  final int pendingPaymentMinor;
  final int securedBookings;
  final int attentionCount;
  final String currency;

  const DirectorDashboardSummary({
    required this.activeProjects,
    required this.projectCount,
    required this.committedBudgetMinor,
    required this.paidMinor,
    required this.pendingPaymentMinor,
    required this.securedBookings,
    required this.attentionCount,
    required this.currency,
  });

  factory DirectorDashboardSummary.fromJson(Map<String, dynamic> json) {
    return DirectorDashboardSummary(
      activeProjects: (json['active_projects'] as num?)?.toInt() ?? 0,
      projectCount: (json['project_count'] as num?)?.toInt() ?? 0,
      committedBudgetMinor:
          (json['committed_budget_minor'] as num?)?.toInt() ?? 0,
      paidMinor: (json['paid_minor'] as num?)?.toInt() ?? 0,
      pendingPaymentMinor:
          (json['pending_payment_minor'] as num?)?.toInt() ?? 0,
      securedBookings: (json['secured_bookings'] as num?)?.toInt() ?? 0,
      attentionCount: (json['attention_count'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
    );
  }
}

class DirectorTimelineItem {
  final String publicId;
  final String projectId;
  final String projectTitle;
  final String title;
  final String subtitle;
  final DateTime? startsAt;
  final DateTime? endsAt;
  final String status;

  const DirectorTimelineItem({
    required this.publicId,
    required this.projectId,
    required this.projectTitle,
    required this.title,
    required this.subtitle,
    required this.startsAt,
    required this.endsAt,
    required this.status,
  });

  factory DirectorTimelineItem.fromJson(Map<String, dynamic> json) {
    return DirectorTimelineItem(
      publicId: json['public_id'] as String? ?? '',
      projectId: json['project_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Project',
      title: json['title'] as String? ?? 'Production event',
      subtitle: json['subtitle'] as String? ?? '',
      startsAt: DateTime.tryParse(json['starts_at'] as String? ?? ''),
      endsAt: DateTime.tryParse(json['ends_at'] as String? ?? ''),
      status: json['status'] as String? ?? 'scheduled',
    );
  }

  DpScheduleItem toDpScheduleItem() {
    return DpScheduleItem(
      id: publicId,
      date: _dateLabel(startsAt),
      time: _timeLabel(startsAt),
      project: projectTitle,
      location: title,
      stakeholders: [if (subtitle.isNotEmpty) subtitle],
      status: _titleCase(status),
      conflict: status.toLowerCase().contains('conflict'),
    );
  }
}

class DirectorPaymentAttention {
  final String publicId;
  final String bookingId;
  final String projectTitle;
  final String stakeholder;
  final String name;
  final int amountMinor;
  final String currency;
  final String status;
  final DateTime? dueAt;

  const DirectorPaymentAttention({
    required this.publicId,
    required this.bookingId,
    required this.projectTitle,
    required this.stakeholder,
    required this.name,
    required this.amountMinor,
    required this.currency,
    required this.status,
    required this.dueAt,
  });

  factory DirectorPaymentAttention.fromJson(Map<String, dynamic> json) {
    return DirectorPaymentAttention(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Project',
      stakeholder: json['stakeholder'] as String? ?? 'Stakeholder',
      name: json['name'] as String? ?? 'Milestone',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'pending',
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
    );
  }

  DpPayment toDpPayment() {
    return DpPayment(
      id: publicId,
      booking: projectTitle,
      stakeholder: stakeholder,
      amount: amountMinor ~/ 100,
      dueDate: _dateLabel(dueAt),
      stage: name,
      status: _paymentStatus(status),
    );
  }
}

class DirectorPipelineItem {
  final String kind;
  final String publicId;
  final String projectTitle;
  final String counterparty;
  final String title;
  final String status;
  final int? valueMinor;
  final String currency;

  const DirectorPipelineItem({
    required this.kind,
    required this.publicId,
    required this.projectTitle,
    required this.counterparty,
    required this.title,
    required this.status,
    required this.valueMinor,
    required this.currency,
  });

  factory DirectorPipelineItem.fromJson(Map<String, dynamic> json) {
    return DirectorPipelineItem(
      kind: json['kind'] as String? ?? 'booking',
      publicId: json['public_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Project',
      counterparty: json['counterparty'] as String? ?? 'Counterparty',
      title: json['title'] as String? ?? 'Pipeline item',
      status: json['status'] as String? ?? 'active',
      valueMinor: (json['value_minor'] as num?)?.toInt(),
      currency: json['currency'] as String? ?? 'PKR',
    );
  }
}

class DirectorActivityItem {
  final String publicId;
  final String projectTitle;
  final String itemType;
  final String title;
  final String? body;
  final DateTime? createdAt;

  const DirectorActivityItem({
    required this.publicId,
    required this.projectTitle,
    required this.itemType,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  factory DirectorActivityItem.fromJson(Map<String, dynamic> json) {
    return DirectorActivityItem(
      publicId: json['public_id'] as String? ?? '',
      projectTitle: json['project_title'] as String? ?? 'Project',
      itemType: json['item_type'] as String? ?? 'activity',
      title: json['title'] as String? ?? 'Activity',
      body: json['body'] as String?,
      createdAt: DateTime.tryParse(json['created_at'] as String? ?? ''),
    );
  }
}

class DirectorPriorityAction {
  final String tone;
  final String urgency;
  final String title;
  final String subtitle;
  final String route;
  final String? argument;

  const DirectorPriorityAction({
    required this.tone,
    required this.urgency,
    required this.title,
    required this.subtitle,
    required this.route,
    required this.argument,
  });

  factory DirectorPriorityAction.fromJson(Map<String, dynamic> json) {
    return DirectorPriorityAction(
      tone: json['tone'] as String? ?? 'neutral',
      urgency: json['urgency'] as String? ?? 'Action',
      title: json['title'] as String? ?? 'Dashboard action',
      subtitle: json['subtitle'] as String? ?? '',
      route: json['route'] as String? ?? '/director',
      argument: json['argument'] as String?,
    );
  }

  DpTone get dpTone {
    return switch (tone) {
      'danger' || 'critical' => DpTone.danger,
      'warning' => DpTone.warning,
      'success' => DpTone.success,
      'info' => DpTone.info,
      _ => DpTone.neutral,
    };
  }
}

String _dateLabel(DateTime? value) {
  if (value == null) return '-';
  final now = DateTime.now();
  if (value.year == now.year &&
      value.month == now.month &&
      value.day == now.day) {
    return 'Today';
  }
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  return '${months[value.month - 1]} ${value.day}';
}

String _timeLabel(DateTime? value) {
  if (value == null) return '-';
  final hour = value.hour % 12 == 0 ? 12 : value.hour % 12;
  final minute = value.minute.toString().padLeft(2, '0');
  final suffix = value.hour >= 12 ? 'PM' : 'AM';
  return '$hour:$minute $suffix';
}

String _paymentStatus(String status) {
  return switch (status) {
    'paid' || 'verified' => 'Verified',
    'rejected' => 'Rejected',
    'under_verification' || 'proof_uploaded' => 'Proof Uploaded',
    _ => 'Due',
  };
}

String _titleCase(String value) {
  return value
      .replaceAll('_', ' ')
      .split(' ')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}
