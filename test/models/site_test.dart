import 'package:brixel/features/sites/models/site.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('stores the supplied site fields', () {
    const site = Site(
      id: 'site-001',
      name: 'Jaipur Tower Project',
      location: 'Jaipur',
    );

    expect(site.id, 'site-001');
    expect(site.name, 'Jaipur Tower Project');
    expect(site.location, 'Jaipur');
  });
}
