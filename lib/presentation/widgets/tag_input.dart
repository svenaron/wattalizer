import 'package:flutter/material.dart';

/// Editable tag input: shows current tags as removable chips, frequent tags
/// as quick-add suggestions, and a text field with autocomplete.
class TagInput extends StatefulWidget {
  const TagInput({
    required this.currentTags,
    required this.allTags,
    required this.onTagsChanged,
    super.key,
  });

  final List<String> currentTags;
  final List<String> allTags;
  final ValueChanged<List<String>> onTagsChanged;

  @override
  State<TagInput> createState() => _TagInputState();
}

class _TagInputState extends State<TagInput> {
  List<String> get _suggestions {
    final current = widget.currentTags.toSet();
    return widget.allTags.where((t) => !current.contains(t)).toList();
  }

  void _addTag(String tag) {
    final trimmed = tag.trim().toLowerCase();
    if (trimmed.isEmpty) return;
    if (widget.currentTags.contains(trimmed)) return;
    widget.onTagsChanged([...widget.currentTags, trimmed]);
  }

  void _removeTag(String tag) {
    widget.onTagsChanged(widget.currentTags.where((t) => t != tag).toList());
  }

  @override
  Widget build(BuildContext context) {
    final suggestions = _suggestions;
    final quickAdd = suggestions.take(5).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.currentTags.isNotEmpty)
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: widget.currentTags
                .map(
                  (tag) => InputChip(
                    label: Text(tag),
                    onDeleted: () => _removeTag(tag),
                  ),
                )
                .toList(),
          ),
        if (quickAdd.isNotEmpty) ...[
          const SizedBox(height: 8),
          Wrap(
            spacing: 6,
            runSpacing: 4,
            children: quickAdd
                .map(
                  (tag) => ActionChip(
                    label: Text(tag),
                    onPressed: () => _addTag(tag),
                  ),
                )
                .toList(),
          ),
        ],
        const SizedBox(height: 8),
        Autocomplete<String>(
          optionsBuilder: (value) {
            if (value.text.isEmpty) return const Iterable<String>.empty();
            final query = value.text.toLowerCase();
            return suggestions.where((t) => t.contains(query));
          },
          onSelected: _addTag,
          fieldViewBuilder: (context, controller, focusNode, onSubmitted) {
            return TextField(
              controller: controller,
              focusNode: focusNode,
              decoration: const InputDecoration(
                hintText: 'Add tag\u2026',
                isDense: true,
                border: OutlineInputBorder(),
              ),
              onSubmitted: (value) {
                _addTag(value);
                controller.clear();
              },
            );
          },
        ),
      ],
    );
  }
}
