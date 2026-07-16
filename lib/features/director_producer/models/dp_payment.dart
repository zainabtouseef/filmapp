class DpPayment {
  final String id;
  final String booking;
  final String stakeholder;
  final int amount;
  final String dueDate;
  final String stage;
  final String status;
  final String? rejectedReason;

  const DpPayment({
    required this.id,
    required this.booking,
    required this.stakeholder,
    required this.amount,
    required this.dueDate,
    required this.stage,
    required this.status,
    this.rejectedReason,
  });
}
