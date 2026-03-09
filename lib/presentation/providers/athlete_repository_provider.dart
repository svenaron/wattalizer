import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/interfaces/athlete_repository.dart';

final athleteRepositoryProvider = Provider<AthleteRepository>(
  (ref) => throw UnimplementedError(
    'athleteRepositoryProvider must be overridden in ProviderScope',
  ),
);
