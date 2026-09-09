import 'package:cineconnect/core/specialist/specialist_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Brand terms normalize legacy object payment schedules', () {
    final term = BrandTermDto.fromJson({
      'public_id': 'BTM-LEGACY',
      'payment_schedule': {'advance': 50, 'delivery': 50},
    });

    expect(term.paymentSchedule, [
      {'key': 'advance', 'percent': 50},
      {'key': 'delivery', 'percent': 50},
    ]);
  });

  test('Brand terms retain list payment schedules', () {
    final term = BrandTermDto.fromJson({
      'public_id': 'BTM-CURRENT',
      'payment_schedule': [
        {'key': 'advance', 'percent': 40},
      ],
    });

    expect(term.paymentSchedule, [
      {'key': 'advance', 'percent': 40},
    ]);
  });
}
