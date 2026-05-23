import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timebloxs/core/utils/color_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_providers.dart';

class TaskFilterBar extends ConsumerWidget {
  const TaskFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final selectedProject = ref.watch(selectedProjectProvider);
    final filter = ref.watch(taskFilterProvider);
    final categoriesAsync = ref.watch(taskCategoriesProvider);
    final projectsAsync = ref.watch(projectsProvider);

    return Column(
      children: [
        // Search bar
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          child: TextField(
            decoration: const InputDecoration(
              hintText: 'Search tasks...',
              prefixIcon: Icon(Icons.search),
            ),
            onChanged: (value) =>
            ref.read(taskSearchQueryProvider.notifier).state = value,
          ),
        ),
        const Gap(8),

        // Filter chips
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              // All / Reusable / One-off
              _FilterChip(
                label: 'All',
                selected: filter == TaskFilter.all,
                onTap: () => ref.read(taskFilterProvider.notifier).state =
                    TaskFilter.all,
              ),
              const Gap(8),
              _FilterChip(
                label: 'Reusable',
                selected: filter == TaskFilter.reusable,
                onTap: () => ref.read(taskFilterProvider.notifier).state =
                    TaskFilter.reusable,
              ),
              const Gap(8),
              _FilterChip(
                label: 'One-off',
                selected: filter == TaskFilter.oneOff,
                onTap: () => ref.read(taskFilterProvider.notifier).state =
                    TaskFilter.oneOff,
              ),
              const Gap(16),

              // Divider
              Container(
                width: 1,
                height: 24,
                color: AppTheme.surfaceVariant,
              ),
              const Gap(16),

              // Category filters
              categoriesAsync.when(
                data: (categories) => Row(
                  children: categories.map((category) {
                    final isSelected = selectedCategory == category.id;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _FilterChip(
                        label: category.name,
                        selected: isSelected,
                        color: parseColor(category.color, fallback:
                          Theme.of(context).colorScheme.primary),
                        onTap: () {
                          ref
                              .read(selectedCategoryProvider.notifier)
                              .state = isSelected ? null : category.id;
                          ref
                              .read(selectedProjectProvider.notifier)
                              .state = null;
                        },
                      ),
                    );
                  }).toList(),
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

              const Gap(16),

              // Project filters
              projectsAsync.when(
                data: (projects) => projects.isEmpty
                    ? const SizedBox.shrink()
                    : Row(
                  children: [
                    Container(
                      width: 1,
                      height: 24,
                      color: AppTheme.surfaceVariant,
                    ),
                    const Gap(16),
                    ...projects.map((project) {
                      final isSelected = selectedProject == project.id;
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: _FilterChip(
                          label: project.name,
                          selected: isSelected,
                          icon: Icons.folder_outlined,
                          onTap: () {
                            ref
                                .read(selectedProjectProvider.notifier)
                                .state =
                            isSelected ? null : project.id;
                            ref
                                .read(selectedCategoryProvider.notifier)
                                .state = null;
                          },
                        ),
                      );
                    }),
                  ],
                ),
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? color;
  final IconData? icon;
  final VoidCallback onTap;

  const _FilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final chipColor = color ?? Theme.of(context).colorScheme.primary;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: selected ? chipColor.withValues(alpha: 0.2) : AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected ? chipColor : Colors.transparent,
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: selected ? chipColor : AppTheme.textSecondary),
              const Gap(4),
            ],
            Text(
              label,
              style: TextStyle(
                color: selected ? chipColor : AppTheme.textSecondary,
                fontSize: 13,
                fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}