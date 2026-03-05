import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

/// All distinct tags across all rides, sorted alphabetically.
/// autoDispose — only alive while a screen consuming it is mounted.
// ignore: specify_nonobvious_property_types
final allTagsProvider = FutureProvider.autoDispose<List<String>>((ref) {
  final repo = ref.read(rideRepositoryProvider);
  return repo.getAllTags();
});
