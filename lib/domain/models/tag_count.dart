/// Tag with its usage count across rides. Used for tag input suggestions.
class TagCount {
  const TagCount({required this.tag, required this.count});

  final String tag;
  final int count;
}
