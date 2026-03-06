/// Material 3 canonical breakpoints for responsive layout.
enum LayoutSize { compact, medium, expanded }

/// Determine layout size from available width.
LayoutSize layoutSizeOf(double width) {
  if (width < 600) return LayoutSize.compact;
  if (width < 900) return LayoutSize.medium;
  return LayoutSize.expanded;
}
