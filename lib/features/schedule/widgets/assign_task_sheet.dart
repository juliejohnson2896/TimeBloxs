import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timebloxs/core/utils/color_utils.dart';
import '../../../core/models/task_template.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../tasks/providers/task_providers.dart';

class AssignTaskSheet extends ConsumerWidget {
  final String blockId;
  final String categoryId;

  const AssignTaskSheet({
    super.key,
    required this.blockId,
    required this.categoryId,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(taskTemplatesProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(        // add this
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(20),

            Text(
              'Assign Task',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(4),
            Text(
              'Pick a task from your pool to assign to this block',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const Gap(16),

            tasksAsync.when(
              data: (tasks) {
                // Filter to same category + not archived
                final filtered = tasks
                    .where((t) =>
                !t.isArchived &&
                    t.categoryId == categoryId)
                    .toList();

                // Also include tasks from other categories
                final others = tasks
                    .where((t) =>
                !t.isArchived &&
                    t.categoryId != categoryId)
                    .toList();

                if (filtered.isEmpty && others.isEmpty) {
                  return Column(
                    children: [
                      const Icon(
                        Icons.checklist_outlined,
                        size: 48,
                        color: AppTheme.textDisabled,
                      ),
                      const Gap(12),
                      Text(
                        'No tasks in your pool yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: AppTheme.textSecondary,
                        ),
                      ),
                      const Gap(8),
                      Text(
                        'Add tasks in the Tasks tab first',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const Gap(16),
                    ],
                  );
                }

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.5,
                  ),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Same category tasks first
                        if (filtered.isNotEmpty) ...[
                          _SectionHeader(label: 'Matching Category'),
                          const Gap(8),
                          ...filtered.map((task) => _TaskOption(
                            task: task,
                            onTap: () => _assign(context, ref, task),
                          )),
                          const Gap(16),
                        ],

                        // Other category tasks
                        if (others.isNotEmpty) ...[
                          _SectionHeader(
                            label: filtered.isNotEmpty
                                ? 'Other Tasks'
                                : 'All Tasks',
                          ),
                          const Gap(8),
                          ...others.map((task) => _TaskOption(
                            task: task,
                            onTap: () => _assign(context, ref, task),
                          )),
                        ],
                      ],
                    ),
                  ),
                );
              },
              loading: () => const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              ),
              error: (e, _) => Text('Error loading tasks: $e'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _assign(
      BuildContext context, WidgetRef ref, TaskTemplate task) async {
    try {
      await ref
          .read(scheduledBlockRepositoryProvider)
          .assignTask(blockId, task.id);
      if (context.mounted) Navigator.pop(context);
    } catch (e, stack) {
      await logger.error('AssignTaskSheet._assign', e, stack);
      SnackbarHelper.showError(context, ErrorMessages.assignTaskFailed);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _TaskOption extends StatelessWidget {
  final TaskTemplate task;
  final VoidCallback onTap;

  const _TaskOption({required this.task, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final color = parseColor(task.categoryColor, fallback: accentColor);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceVariant,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.transparent),
        ),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 36,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    task.name,
                    style: const TextStyle(
                      color: AppTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                      fontSize: 14,
                    ),
                  ),
                  if (task.categoryName != null)
                    Text(
                      task.categoryName!,
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
            if (task.projectName != null) ...[
              const Icon(
                Icons.folder_outlined,
                size: 14,
                color: AppTheme.textSecondary,
              ),
              const Gap(4),
              Text(
                task.projectName!,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const Gap(8),
            const Icon(
              Icons.chevron_right,
              color: AppTheme.textSecondary,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}