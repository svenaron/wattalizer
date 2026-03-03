import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Selected tag filters. Empty set = show all.
/// keepAlive — historicalRangeProvider and rideListProvider depend on this.
// (brackets omitted: importing those providers here would be circular)
final tagFilterProvider =
    NotifierProvider<TagFilterNotifier, Set<String>>(TagFilterNotifier.new);

class TagFilterNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};

  Set<String> get tags => state;
  set tags(Set<String> value) => state = value;
  void addTag(String tag) => state = {...state, tag};
  void removeTag(String tag) => state = {...state}..remove(tag);
  void clear() => state = {};
}
