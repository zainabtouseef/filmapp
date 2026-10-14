import 'package:cineconnect/core/insurance/insurance_models.dart';
import 'package:cineconnect/core/operations/operations_models.dart';
import 'package:cineconnect/core/specialist/specialist_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Owner API fields remain available when reopening private forms', () {
    expect(
        LocationPropertyDto.fromJson({'private_address': 'Private entrance'})
            .privateAddress,
        'Private entrance');
    expect(EquipmentItemDto.fromJson({'serial': 'SERIAL-123'}).serial,
        'SERIAL-123');
    expect(
        BrandProfileDto.fromJson({'billing_details': 'Invoice address'})
            .billingDetails,
        'Invoice address');
    final contact = DistributorContactDto.fromJson(
        {'email': 'contact@example.com', 'phone': '+923001234567'});
    expect(contact.email, 'contact@example.com');
    expect(contact.phone, '+923001234567');
    expect(
        InsuranceProfileDto.fromJson({'license_number': 'LIC-123'})
            .licenseNumber,
        'LIC-123');
  });

  test('Old records without recoverable private fields remain empty', () {
    expect(LocationPropertyDto.fromJson({}).privateAddress, isNull);
    expect(EquipmentItemDto.fromJson({}).serial, isNull);
    expect(BrandProfileDto.fromJson({}).billingDetails, isNull);
    expect(DistributorContactDto.fromJson({}).email, isNull);
    expect(DistributorContactDto.fromJson({}).phone, isNull);
    expect(InsuranceProfileDto.fromJson({}).licenseNumber, isNull);
  });
}
