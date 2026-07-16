class DpScheduleItem {
  final String id;
  final String date;
  final String time;
  final String project;
  final String location;
  final List<String> stakeholders;
  final String status;
  final bool conflict;

  const DpScheduleItem({
    required this.id,
    required this.date,
    required this.time,
    required this.project,
    required this.location,
    required this.stakeholders,
    required this.status,
    required this.conflict,
  });
}
