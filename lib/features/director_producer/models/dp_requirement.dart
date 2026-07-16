class DpRequirement {
  final String id;
  final String projectId;
  final String category;
  final String title;
  final String summary;
  final String budgetRange;
  final String dates;
  final int candidateCount;
  final String status;

  const DpRequirement({
    required this.id,
    required this.projectId,
    required this.category,
    required this.title,
    required this.summary,
    required this.budgetRange,
    required this.dates,
    required this.candidateCount,
    required this.status,
  });
}
