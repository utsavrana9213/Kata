import 'package:flutter_test/flutter_test.dart';
import 'package:servekeen/service_model.dart';
import 'package:servekeen/vendor_filters.dart';

Service service(String name, {String category = '1', String? tier}) => Service(
  id: name,
  companyName: '$name Vendor',
  serviceName: name,
  categorys: category,
  membershipTier: tier,
);

void main() {
  test('tier filtering never mixes standard and premium vendors', () {
    final all = [
      service('Salon', tier: 'standard'),
      service('Salon Plus', tier: 'premium'),
    ];
    expect(
      rankRelevantServices(all, 'salon', tier: VendorTier.standard),
      hasLength(1),
    );
    expect(
      rankRelevantServices(
        all,
        'salon',
        tier: VendorTier.premium,
      ).single.serviceName,
      'Salon Plus',
    );
  });

  test('category search ranks and excludes unrelated named services', () {
    final all = [
      service('Roadside repair', category: '4'),
      service('Bridal styling', category: '6'),
    ];
    final result = rankRelevantServices(
      all,
      'automobile',
      tier: VendorTier.standard,
      categoryNames: const {'4': 'Automobile', '6': 'Spa & Salons'},
    );
    expect(result.single.serviceName, 'Roadside repair');
  });
}
