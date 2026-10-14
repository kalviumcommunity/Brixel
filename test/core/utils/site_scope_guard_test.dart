import 'package:brixel/core/utils/site_scope_guard.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SiteScopeGuard', () {
    test('allows a record for the active site', () {
      expect(
        () => SiteScopeGuard.validate(
          activeSiteId: 'site-jaipur-01',
          recordSiteId: 'site-jaipur-01',
        ),
        returnsNormally,
      );
    });

    test('rejects a record belonging to another site', () {
      expect(
        () => SiteScopeGuard.validate(
          activeSiteId: 'site-jaipur-01',
          recordSiteId: 'site-kota-02',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an empty active site ID', () {
      expect(
        () => SiteScopeGuard.validate(
          activeSiteId: '',
          recordSiteId: 'site-jaipur-01',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });

    test('rejects an empty record site ID', () {
      expect(
        () => SiteScopeGuard.validate(
          activeSiteId: 'site-jaipur-01',
          recordSiteId: '',
        ),
        throwsA(isA<ArgumentError>()),
      );
    });
  });
}
