import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';
import 'package:wattalizer/presentation/providers/athlete_repository_provider.dart';

final FutureProvider<List<AthleteProfile>> athleteListProvider =
    FutureProvider.autoDispose<List<AthleteProfile>>((ref) async {
  final repo = ref.watch(athleteRepositoryProvider);
  return repo.getAthletes();
});
