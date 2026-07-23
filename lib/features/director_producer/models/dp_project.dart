class DpProject {
  final String id;
  final String title;
  final String type;
  final String city;
  final String dateRange;
  final String status;
  final int estimatedBudget;
  final int confirmedCost;
  final double budgetHealth;
  final int pendingActions;
  final String shootDate;
  final int bookingsCount;
  final int contractsCount;
  final String paymentsStatus;
  final List<String> team;
  final double progress;
  final String? coverImageUrl;

  const DpProject({
    required this.id,
    required this.title,
    required this.type,
    required this.city,
    required this.dateRange,
    required this.status,
    required this.estimatedBudget,
    required this.confirmedCost,
    required this.budgetHealth,
    required this.pendingActions,
    required this.shootDate,
    required this.bookingsCount,
    required this.contractsCount,
    required this.paymentsStatus,
    required this.team,
    required this.progress,
    this.coverImageUrl,
  });
}
