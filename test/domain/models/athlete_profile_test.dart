import 'package:flutter_test/flutter_test.dart';
import 'package:wattalizer/domain/models/athlete_profile.dart';

void main() {
  group('AthleteProfile', () {
    final profile = AthleteProfile(
      id: 'me',
      name: 'Me',
      createdAt: DateTime(2024),
    );

    group('copyWith', () {
      test('updates name', () {
        final updated = profile.copyWith(name: 'Alice');
        expect(updated.name, 'Alice');
        expect(updated.id, profile.id);
        expect(updated.createdAt, profile.createdAt);
      });

      test('preserves existing name when null', () {
        final copy = profile.copyWith();
        expect(copy.name, profile.name);
      });
    });

    group('fields', () {
      test('coachId defaults to null', () {
        expect(profile.coachId, isNull);
      });

      test('coachId can be set', () {
        final withCoach = AthleteProfile(
          id: 'me',
          name: 'Me',
          createdAt: DateTime(2024),
          coachId: 'coach1',
        );
        expect(withCoach.coachId, 'coach1');
      });
    });
  });
}
