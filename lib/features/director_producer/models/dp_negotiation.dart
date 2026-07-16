class DpNegotiation {
  final String id;
  final String project;
  final String requirement;
  final String candidate;
  final String status;
  final String currentRate;
  final String move;
  final String expiry;
  final List<DpNegotiationRound> rounds;

  const DpNegotiation({
    required this.id,
    required this.project,
    required this.requirement,
    required this.candidate,
    required this.status,
    required this.currentRate,
    required this.move,
    required this.expiry,
    required this.rounds,
  });
}

class DpNegotiationRound {
  final int round;
  final String sentBy;
  final String rate;
  final String dates;
  final String schedule;
  final String conditions;
  final String message;
  final String timestamp;
  final String expiry;

  const DpNegotiationRound({
    required this.round,
    required this.sentBy,
    required this.rate,
    required this.dates,
    required this.schedule,
    required this.conditions,
    required this.message,
    required this.timestamp,
    required this.expiry,
  });
}
