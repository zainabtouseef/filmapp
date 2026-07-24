import 'package:flutter/foundation.dart';

import '../../../core/bookings/booking_models.dart';
import '../../../core/network/api_exception.dart';
import '../../../core/operations/operations_models.dart';
import '../models/location_owner_models.dart';

class LocationOwnerSelectionStore extends ChangeNotifier {
  LocationOwnerSelectionStore._();

  static final instance = LocationOwnerSelectionStore._();

  String? activePropertyId;

  void setActiveProperty(String? propertyId) {
    if (activePropertyId == propertyId) return;
    activePropertyId = propertyId;
    notifyListeners();
  }
}

LocationPropertyDto? activeLocationProperty(
  List<LocationPropertyDto> properties,
) {
  if (properties.isEmpty) return null;
  final selected = LocationOwnerSelectionStore.instance.activePropertyId;
  for (final property in properties) {
    if (property.publicId == selected) return property;
  }
  return properties.first;
}

String locationBookingStatusLabel(LocationBookingStatus status) {
  return switch (status) {
    LocationBookingStatus.requestReceived => 'Request',
    LocationBookingStatus.underNegotiation => 'Negotiating',
    LocationBookingStatus.contractPending => 'Contract',
    LocationBookingStatus.depositPending => 'Deposit Due',
    LocationBookingStatus.secured => 'Secured',
    LocationBookingStatus.inProgress => 'Live',
    LocationBookingStatus.closed => 'Closed',
    LocationBookingStatus.disputed => 'Issue',
  };
}

LocationBookingStatus locationBookingStatusFromBooking(Booking booking) {
  return switch (booking.status) {
    'sent' || 'viewed' => LocationBookingStatus.requestReceived,
    'under_negotiation' => LocationBookingStatus.underNegotiation,
    'accepted' => LocationBookingStatus.contractPending,
    'secured' => LocationBookingStatus.secured,
    'in_progress' => LocationBookingStatus.inProgress,
    'disputed' => LocationBookingStatus.disputed,
    'completed' || 'rejected' || 'cancelled' => LocationBookingStatus.closed,
    _ => LocationBookingStatus.requestReceived,
  };
}

String locationBookingDates(Booking booking) {
  return '${shortLocationDate(booking.startAt)} - '
      '${shortLocationDate(booking.endAt)}';
}

String locationBookingAmount(Booking booking) {
  final amount = booking.activeOffer?.feeMinor ?? booking.agreedAmountMinor;
  if (amount == null || amount <= 0) return 'Rate not set';
  return '${booking.currency} ${compactLocationMoney(amount ~/ 100)}';
}

String compactLocationMoney(int amount) {
  if (amount >= 1000000) {
    final millions = amount / 1000000;
    return '${millions.toStringAsFixed(millions == millions.round() ? 0 : 1)}M';
  }
  if (amount >= 1000) {
    final thousands = amount / 1000;
    return '${thousands.toStringAsFixed(thousands == thousands.round() ? 0 : 1)}k';
  }
  return '$amount';
}

String shortLocationDate(DateTime value) {
  const months = [
    'Jan',
    'Feb',
    'Mar',
    'Apr',
    'May',
    'Jun',
    'Jul',
    'Aug',
    'Sep',
    'Oct',
    'Nov',
    'Dec',
  ];
  final local = value.toLocal();
  return '${months[local.month - 1]} ${local.day}';
}

String readableLocationStatus(String value) {
  if (value.isEmpty) return 'Unknown';
  return value
      .split('_')
      .where((part) => part.isNotEmpty)
      .map((part) => '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');
}

String locationApiMessage(Object error) {
  if (error is ApiException) return error.message;
  return 'The request could not be completed. Try again.';
}
