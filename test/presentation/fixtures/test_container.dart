import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/providers/athlete_repository_provider.dart';
import 'package:wattalizer/presentation/providers/ble_service_provider.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

import 'fake_athlete_repository.dart';
import 'fake_ble_service.dart';
import 'fake_repository.dart';

ProviderContainer createTestContainer({
  FakeRepository? repository,
  FakeBleService? bleService,
  FakeAthleteRepository? athleteRepository,
}) {
  return ProviderContainer(
    overrides: [
      rideRepositoryProvider.overrideWithValue(
        repository ?? FakeRepository(),
      ),
      bleServiceProvider.overrideWithValue(
        bleService ?? FakeBleService(),
      ),
      athleteRepositoryProvider.overrideWithValue(
        athleteRepository ?? FakeAthleteRepository(),
      ),
    ],
  );
}
