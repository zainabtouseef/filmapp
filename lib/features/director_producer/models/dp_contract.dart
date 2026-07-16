class DpContract {
  final String id;
  final String title;
  final String project;
  final String candidate;
  final String value;
  final String status;
  final double signatureProgress;
  final String createdDate;

  const DpContract({
    required this.id,
    required this.title,
    required this.project,
    required this.candidate,
    required this.value,
    required this.status,
    required this.signatureProgress,
    required this.createdDate,
  });
}
