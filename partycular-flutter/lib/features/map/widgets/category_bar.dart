import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/strings.dart';
import '../../../core/theme/app_palette.dart';
import '../../events/event_filters.dart';

/// Category chips. Hidden while all events share a single category,
/// because a filter with one option adds nothing.
class CategoryBar extends ConsumerWidget {
  const CategoryBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categories = ref.watch(categoriesProvider);
    if (categories.length < 2) return const SizedBox.shrink();
    final selected = ref.watch(effectiveCategoryProvider);
    final notifier = ref.read(categoryFilterProvider.notifier);
    final options = <String?>[null, ...categories];

    return SizedBox(
      height: 36,
      child: Center(
        child: ListView.separated(
          shrinkWrap: true,
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          itemCount: options.length,
          separatorBuilder: (_, _) => const SizedBox(width: 7),
          itemBuilder: (context, index) {
            final category = options[index];
            return _CategoryChip(
              label: category ?? S.allCategories,
              selected: category == selected,
              onTap: () => notifier.select(category),
            );
          },
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  const _CategoryChip({required this.label, required this.selected, required this.onTap});

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final p = AppPalette.of(context);
    return Semantics(
      button: true,
      selected: selected,
      child: Material(
        color: selected ? Color.alphaBlend(p.accent.withValues(alpha: 0.16), p.panel) : p.panel.withValues(alpha: 0.92),
        shape: StadiumBorder(side: BorderSide(color: selected ? p.accent.withValues(alpha: 0.6) : p.border)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 15),
            child: Center(
              child: Text(
                label,
                style: TextStyle(
                  color: selected ? p.accent : p.text,
                  fontSize: 13.5,
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
