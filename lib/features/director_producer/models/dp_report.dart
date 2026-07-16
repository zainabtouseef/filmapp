class DpReport {
  final String id;
  final String title;
  final String project;
  final List<String> sections;
  final String generatedDate;
  final String status;

  const DpReport({
    required this.id,
    required this.title,
    required this.project,
    required this.sections,
    required this.generatedDate,
    required this.status,
  });
}
