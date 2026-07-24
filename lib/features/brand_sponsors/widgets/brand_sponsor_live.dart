import '../../../core/network/api_exception.dart';
import '../../../core/specialist/specialist_models.dart';
import '../../../shared/formatters/cine_format.dart';
import '../models/brand_sponsor_models.dart';

BrandOpportunityDto? activeBrandOpportunity(
  List<BrandOpportunityDto> opportunities,
) {
  if (opportunities.isEmpty) return null;
  return opportunities.first;
}

BrandApplicationDto? activeBrandApplication(
  List<BrandApplicationDto> applications,
) {
  if (applications.isEmpty) return null;
  for (final application in applications) {
    if (application.status == 'negotiating' ||
        application.status == 'shortlisted') {
      return application;
    }
  }
  return applications.first;
}

String brandMoney(int? amountMinor, {String currency = 'PKR'}) {
  if (amountMinor == null || amountMinor <= 0) return 'Budget not set';
  final amount = amountMinor / 100;
  if (currency == 'PKR') return CineFormat.currency(amount, compact: true);
  return '$currency ${CineFormat.count(amount, compact: true)}';
}

String brandDate(DateTime? value, {String fallback = 'No deadline'}) {
  if (value == null) return fallback;
  return CineFormat.date(value.toLocal(), includeYear: true);
}

String readableBrandStatus(String value) {
  if (value.isEmpty) return 'Unknown';
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String brandStatusLabel(BrandStatus status) {
  return switch (status) {
    BrandStatus.draft => 'Draft',
    BrandStatus.active => 'Active',
    BrandStatus.pending => 'Pending',
    BrandStatus.reviewing => 'Reviewing',
    BrandStatus.shortlisted => 'Shortlisted',
    BrandStatus.negotiation => 'Negotiation',
    BrandStatus.approved => 'Approved',
    BrandStatus.revision => 'Revision',
    BrandStatus.delivered => 'Delivered',
    BrandStatus.paymentPending => 'Payment Due',
    BrandStatus.verified => 'Verified',
    BrandStatus.closed => 'Closed',
    BrandStatus.disputed => 'Issue',
  };
}

String brandAudienceSummary(Map<String, dynamic> metrics) {
  if (metrics.isEmpty) return 'Audience metrics not provided';
  return metrics.entries
      .take(3)
      .map((entry) => '${readableBrandStatus(entry.key)}: ${entry.value}')
      .join(' | ');
}

String brandApiMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'The request could not be completed. Try again.';
}
