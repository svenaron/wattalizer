import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:wattalizer/presentation/providers/all_tags_provider.dart';
import 'package:wattalizer/presentation/providers/tag_filter_provider.dart';

class TagFilter extends ConsumerWidget {
  const TagFilter({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allTagsAsync = ref.watch<AsyncValue<List<String>>>(allTagsProvider);
    final selectedTags = ref.watch(tagFilterProvider);

    return allTagsAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (allTags) {
        if (allTags.isEmpty) return const SizedBox.shrink();
        return SizedBox(
          height: 40,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: allTags.length,
            separatorBuilder: (_, __) => const SizedBox(width: 6),
            itemBuilder: (context, i) {
              final tag = allTags[i];
              final isSelected = selectedTags.contains(tag);
              return FilterChip(
                label: Text(tag),
                selected: isSelected,
                onSelected: (_) {
                  final notifier = ref.read(tagFilterProvider.notifier);
                  if (isSelected) {
                    notifier.removeTag(tag);
                  } else {
                    notifier.addTag(tag);
                  }
                },
              );
            },
          ),
        );
      },
    );
  }
}
