class DpBooking {
  final String id;
  final String projectId;
  final String requirement;
  final String candidate;
  final int statusIndex;
  final String fee;
  final String dateRange;
  final String stage;
  final String expiry;

  const DpBooking({
    required this.id,
    required this.projectId,
    required this.requirement,
    required this.candidate,
    required this.statusIndex,
    required this.fee,
    required this.dateRange,
    required this.stage,
    required this.expiry,
  });
}
