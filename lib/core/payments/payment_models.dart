import '../core_ui/models/shared_models.dart';

class PaymentUser {
  final String publicId;
  final String displayName;

  const PaymentUser({required this.publicId, required this.displayName});

  factory PaymentUser.fromJson(Map<String, dynamic>? json) {
    return PaymentUser(
      publicId: json?['public_id'] as String? ?? '',
      displayName: json?['display_name'] as String? ?? 'CineConnect member',
    );
  }
}

class PaymentTransaction {
  final String publicId;
  final PaymentUser payer;
  final PaymentUser payee;
  final String provider;
  final String? providerReference;
  final int amountMinor;
  final String currency;
  final String direction;
  final String status;
  final DateTime? paidAt;
  final String idempotencyKey;

  const PaymentTransaction({
    required this.publicId,
    required this.payer,
    required this.payee,
    required this.provider,
    required this.providerReference,
    required this.amountMinor,
    required this.currency,
    required this.direction,
    required this.status,
    required this.paidAt,
    required this.idempotencyKey,
  });

  factory PaymentTransaction.fromJson(Map<String, dynamic> json) {
    return PaymentTransaction(
      publicId: json['public_id'] as String? ?? '',
      payer: PaymentUser.fromJson(json['payer'] as Map<String, dynamic>?),
      payee: PaymentUser.fromJson(json['payee'] as Map<String, dynamic>?),
      provider: json['provider'] as String? ?? 'bank_transfer',
      providerReference: json['provider_reference'] as String?,
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      direction: json['direction'] as String? ?? 'outgoing',
      status: json['status'] as String? ?? 'pending',
      paidAt: DateTime.tryParse(json['paid_at'] as String? ?? ''),
      idempotencyKey: json['idempotency_key'] as String? ?? '',
    );
  }
}

class PaymentMilestoneDto {
  final String publicId;
  final String name;
  final int sequence;
  final int amountMinor;
  final DateTime? dueAt;
  final String? releaseCondition;
  final String status;
  final List<PaymentTransaction> transactions;

  const PaymentMilestoneDto({
    required this.publicId,
    required this.name,
    required this.sequence,
    required this.amountMinor,
    required this.dueAt,
    required this.releaseCondition,
    required this.status,
    required this.transactions,
  });

  factory PaymentMilestoneDto.fromJson(Map<String, dynamic> json) {
    return PaymentMilestoneDto(
      publicId: json['public_id'] as String? ?? '',
      name: json['name'] as String? ?? 'Milestone',
      sequence: (json['sequence'] as num?)?.toInt() ?? 1,
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      dueAt: DateTime.tryParse(json['due_at'] as String? ?? ''),
      releaseCondition: json['release_condition'] as String?,
      status: json['status'] as String? ?? 'due',
      transactions: (json['transactions'] as List<dynamic>? ?? const [])
          .map((item) =>
              PaymentTransaction.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  String get amountLabel => '${_money(amountMinor)} PKR';
}

class PaymentScheduleDto {
  final String publicId;
  final String bookingId;
  final String? contractId;
  final int totalMinor;
  final String currency;
  final String status;
  final List<PaymentMilestoneDto> milestones;

  const PaymentScheduleDto({
    required this.publicId,
    required this.bookingId,
    required this.contractId,
    required this.totalMinor,
    required this.currency,
    required this.status,
    required this.milestones,
  });

  factory PaymentScheduleDto.fromJson(Map<String, dynamic> json) {
    return PaymentScheduleDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      contractId: json['contract_id'] as String?,
      totalMinor: (json['total_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'active',
      milestones: (json['milestones'] as List<dynamic>? ?? const [])
          .map((item) =>
              PaymentMilestoneDto.fromJson(item as Map<String, dynamic>))
          .toList(),
    );
  }

  String get totalLabel => '${_money(totalMinor)} $currency';
}

class PaymentDashboardDto {
  final List<PaymentScheduleDto> schedules;
  final int debitMinor;
  final int creditMinor;
  final int pendingReleaseMinor;

  const PaymentDashboardDto({
    required this.schedules,
    required this.debitMinor,
    required this.creditMinor,
    required this.pendingReleaseMinor,
  });

  factory PaymentDashboardDto.fromJson(Map<String, dynamic> json) {
    final totals = json['totals'] as Map<String, dynamic>? ?? const {};
    return PaymentDashboardDto(
      schedules: (json['schedules'] as List<dynamic>? ?? const [])
          .map((item) =>
              PaymentScheduleDto.fromJson(item as Map<String, dynamic>))
          .toList(),
      debitMinor: (totals['debit_minor'] as num?)?.toInt() ?? 0,
      creditMinor: (totals['credit_minor'] as num?)?.toInt() ?? 0,
      pendingReleaseMinor:
          (totals['pending_release_minor'] as num?)?.toInt() ?? 0,
    );
  }
}

class PaymentProofDto {
  final String publicId;
  final String transactionId;
  final String milestoneId;
  final String bookingId;
  final int claimedAmountMinor;
  final String method;
  final String? transactionReference;
  final PaymentUser submittedBy;
  final String status;
  final int riskScore;
  final PaymentUser? reviewedBy;
  final DateTime? reviewedAt;
  final String? rejectionReason;
  final String? filePublicUrl;
  final String? fileDownloadUrl;
  final String? fileMimeType;

  const PaymentProofDto({
    required this.publicId,
    required this.transactionId,
    required this.milestoneId,
    required this.bookingId,
    required this.claimedAmountMinor,
    required this.method,
    required this.transactionReference,
    required this.submittedBy,
    required this.status,
    required this.riskScore,
    required this.reviewedBy,
    required this.reviewedAt,
    required this.rejectionReason,
    this.filePublicUrl,
    this.fileDownloadUrl,
    this.fileMimeType,
  });

  factory PaymentProofDto.fromJson(Map<String, dynamic> json) {
    final reviewer = json['reviewed_by'] as Map<String, dynamic>?;
    final file = json['file'] as Map<String, dynamic>?;
    return PaymentProofDto(
      publicId: json['public_id'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      milestoneId: json['milestone_id'] as String? ?? '',
      bookingId: json['booking_id'] as String? ?? '',
      claimedAmountMinor: (json['claimed_amount_minor'] as num?)?.toInt() ?? 0,
      method: json['method'] as String? ?? 'bank_transfer',
      transactionReference: json['transaction_reference'] as String?,
      submittedBy:
          PaymentUser.fromJson(json['submitted_by'] as Map<String, dynamic>?),
      status: json['status'] as String? ?? 'pending',
      riskScore: (json['risk_score'] as num?)?.toInt() ?? 0,
      reviewedBy: reviewer == null ? null : PaymentUser.fromJson(reviewer),
      reviewedAt: DateTime.tryParse(json['reviewed_at'] as String? ?? ''),
      rejectionReason: json['rejection_reason'] as String?,
      filePublicUrl: file?['public_url'] as String?,
      fileDownloadUrl: file?['download_url'] as String?,
      fileMimeType: file?['mime_type'] as String?,
    );
  }

  String get amountLabel => '${_money(claimedAmountMinor)} PKR';
}

class LedgerEntryDto {
  final String publicId;
  final String? bookingId;
  final String? transactionId;
  final String entryType;
  final String direction;
  final int amountMinor;
  final String currency;
  final String status;
  final DateTime? occurredAt;
  final String description;

  const LedgerEntryDto({
    required this.publicId,
    required this.bookingId,
    required this.transactionId,
    required this.entryType,
    required this.direction,
    required this.amountMinor,
    required this.currency,
    required this.status,
    required this.occurredAt,
    required this.description,
  });

  factory LedgerEntryDto.fromJson(Map<String, dynamic> json) {
    return LedgerEntryDto(
      publicId: json['public_id'] as String? ?? '',
      bookingId: json['booking_id'] as String?,
      transactionId: json['transaction_id'] as String?,
      entryType: json['entry_type'] as String? ?? 'payment',
      direction: json['direction'] as String? ?? 'debit',
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'pending',
      occurredAt: DateTime.tryParse(json['occurred_at'] as String? ?? ''),
      description: json['description'] as String? ?? 'Ledger entry',
    );
  }

  LedgerRowData toLedgerRow() {
    return LedgerRowData(
      projectName: description,
      bookingId: bookingId ?? 'Booking',
      milestone: entryType.replaceAll('_', ' '),
      amount: amountMinor ~/ 100,
      direction: direction == 'credit'
          ? LedgerDirection.incoming
          : LedgerDirection.outgoing,
      status: _ledgerStatus(status),
      date: occurredAt == null ? 'Now' : _shortDate(occurredAt!),
      receiptId: publicId,
      transactionId: transactionId ?? publicId,
    );
  }
}

class ReceiptDto {
  final String publicId;
  final String receiptNumber;
  final String transactionId;
  final PaymentUser issuedTo;
  final int amountMinor;
  final String currency;
  final String status;

  const ReceiptDto({
    required this.publicId,
    required this.receiptNumber,
    required this.transactionId,
    required this.issuedTo,
    required this.amountMinor,
    required this.currency,
    required this.status,
  });

  factory ReceiptDto.fromJson(Map<String, dynamic> json) {
    return ReceiptDto(
      publicId: json['public_id'] as String? ?? '',
      receiptNumber: json['receipt_number'] as String? ?? '',
      transactionId: json['transaction_id'] as String? ?? '',
      issuedTo:
          PaymentUser.fromJson(json['issued_to'] as Map<String, dynamic>?),
      amountMinor: (json['amount_minor'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'PKR',
      status: json['status'] as String? ?? 'issued',
    );
  }
}

class PayoutAccountDto {
  final String publicId;
  final String provider;
  final String accountMasked;
  final String accountName;
  final String status;
  final bool isDefault;

  const PayoutAccountDto({
    required this.publicId,
    required this.provider,
    required this.accountMasked,
    required this.accountName,
    required this.status,
    required this.isDefault,
  });

  factory PayoutAccountDto.fromJson(Map<String, dynamic> json) {
    return PayoutAccountDto(
      publicId: json['public_id'] as String? ?? '',
      provider: json['provider'] as String? ?? 'sandbox',
      accountMasked: json['account_masked'] as String? ?? '****',
      accountName: json['account_name'] as String? ?? 'Payout account',
      status: json['status'] as String? ?? 'pending',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class AdminPaymentProofDetailDto {
  final PaymentProofDto proof;
  final List<Map<String, dynamic>> bookingEvents;

  const AdminPaymentProofDetailDto({
    required this.proof,
    required this.bookingEvents,
  });

  factory AdminPaymentProofDetailDto.fromJson(Map<String, dynamic> json) {
    return AdminPaymentProofDetailDto(
      proof: PaymentProofDto.fromJson(json['proof'] as Map<String, dynamic>),
      bookingEvents: (json['booking_events'] as List<dynamic>? ?? const [])
          .map((item) => item as Map<String, dynamic>)
          .toList(),
    );
  }
}

class PaymentDecisionResultDto {
  final PaymentProofDto proof;
  final ReceiptDto? receipt;

  const PaymentDecisionResultDto({required this.proof, required this.receipt});

  factory PaymentDecisionResultDto.fromJson(Map<String, dynamic> json) {
    final receipt = json['receipt'] as Map<String, dynamic>?;
    return PaymentDecisionResultDto(
      proof: PaymentProofDto.fromJson(json['proof'] as Map<String, dynamic>),
      receipt: receipt == null ? null : ReceiptDto.fromJson(receipt),
    );
  }
}

LedgerStatus _ledgerStatus(String value) {
  return switch (value) {
    'verified' || 'posted' || 'released' => LedgerStatus.verified,
    'pending_verification' ||
    'pending_release' =>
      LedgerStatus.pendingVerification,
    'refunded' => LedgerStatus.refunded,
    'disputed' || 'rejected' => LedgerStatus.disputed,
    _ => LedgerStatus.notPaid,
  };
}

String _money(int minor) {
  final amount = minor / 100;
  if (amount >= 1000000) return '${(amount / 1000000).toStringAsFixed(1)}M';
  if (amount >= 1000) return '${(amount / 1000).toStringAsFixed(0)}K';
  return amount.toStringAsFixed(0);
}

String _shortDate(DateTime value) {
  return '${value.year}-${value.month.toString().padLeft(2, '0')}-${value.day.toString().padLeft(2, '0')}';
}
