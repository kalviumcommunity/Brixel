import 'package:brixel/features/auth/models/user_model.dart';
import 'package:brixel/features/auth/repositories/user_repository.dart';
import 'package:brixel/features/sites/models/site_model.dart';
import 'package:brixel/features/sites/repositories/site_repository.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeUserRepository implements UserRepository {
  FakeUserRepository({required this.profiles, this.error});

  final Map<String, UserModel?> profiles;
  final Object? error;

  @override
  Stream<UserModel?> watchUserProfile(String uid) {
    if (error != null) {
      return Stream<UserModel?>.error(error!);
    }

    return Stream.value(profiles[uid]);
  }
}

class FakeSiteRepository implements SiteRepository {
  FakeSiteRepository(this.sites);

  final List<SiteModel> sites;

  @override
  Stream<List<SiteModel>> watchAssignedSites(List<String> siteIds) {
    final assignedSites = sites
        .where((site) => siteIds.contains(site.id))
        .toList();

    return Stream.value(assignedSites);
  }
}

void main() {
  final createdAt = DateTime(2026, 10, 13);

  test('user repository exposes profile and assigned site ids', () async {
    final repository = FakeUserRepository(
      profiles: {
        'user-1': UserModel(
          uid: 'user-1',
          email: 'nimra@example.com',
          displayName: 'Nimra',
          role: 'pending',
          assignedSiteIds: const ['site-jaipur-01', 'site-kota-02'],
          createdAt: createdAt,
        ),
      },
    );

    final profile = await repository.watchUserProfile('user-1').first;

    expect(profile, isNotNull);
    expect(profile!.role, 'pending');
    expect(profile.assignedSiteIds, ['site-jaipur-01', 'site-kota-02']);
  });

  test('missing profile stays missing instead of inventing a user', () async {
    final repository = FakeUserRepository(profiles: const {});

    final profile = await repository.watchUserProfile('unknown-user').first;

    expect(profile, isNull);
  });

  test('site repository returns only requested assigned sites', () async {
    final repository = FakeSiteRepository([
      SiteModel(
        id: 'site-jaipur-01',
        name: 'Jaipur Residential Project',
        location: 'Jaipur',
        status: 'active',
        expectedHeadcount: 50,
        createdAt: createdAt,
      ),
      SiteModel(
        id: 'site-kota-02',
        name: 'Kota Commercial Project',
        location: 'Kota',
        status: 'active',
        expectedHeadcount: 35,
        createdAt: createdAt,
      ),
      SiteModel(
        id: 'site-delhi-03',
        name: 'Delhi Project',
        location: 'Delhi',
        status: 'active',
        expectedHeadcount: 80,
        createdAt: createdAt,
      ),
    ]);

    final sites = await repository.watchAssignedSites([
      'site-jaipur-01',
      'site-kota-02',
    ]).first;

    expect(sites.length, 2);
    expect(
      sites.map((site) => site.id),
      containsAll(['site-jaipur-01', 'site-kota-02']),
    );

    expect(sites.map((site) => site.id), isNot(contains('site-delhi-03')));
  });

  test('repository errors are propagated to the caller', () async {
    final repository = FakeUserRepository(
      profiles: const {},
      error: StateError('Firestore unavailable'),
    );

    expectLater(
      repository.watchUserProfile('user-1'),
      emitsError(isA<StateError>()),
    );
  });
}
