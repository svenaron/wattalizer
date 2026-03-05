import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/domain/services/export_service.dart';
import 'package:wattalizer/presentation/providers/ride_repository_provider.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  final repo = ref.read(rideRepositoryProvider);
  return ExportService(repository: repo);
});
