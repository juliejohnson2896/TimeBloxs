import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timebloxs/core/repositories/repository_providers.dart';
import '../../../core/models/task_template.dart';
import '../../../core/providers/invalidation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/color_utils.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/task_providers.dart';
import 'create_task_sheet.dart';

class TaskCard extends ConsumerWidget {
  final TaskTemplate task;

  const TaskCard({super.key, required this.task});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.primary;

    // Project colour takes priority over category colour
    final color = parseColor(
        hierarchyCheck(task.projectColor, task.categoryColor),
        fallback: accentColor
    );

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant, width: 1),
      ),
      child: Column(
        children: [
          // Main task row
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                // Category colour indicator
                Container(
                  width: 4,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const Gap(12),

                // Task info
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.name,
                        style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const Gap(2),
                      Row(
                        children: [
                          if (task.categoryName != null) ...[
                            Flexible(
                              child: Text(
                                task.categoryName!,
                                style: TextStyle(
                                  color: color,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                          if (task.projectName != null) ...[
                            const Text(
                              ' · ',
                              style: TextStyle(
                                color: AppTheme.textDisabled,
                                fontSize: 12,
                              ),
                            ),
                            const Icon(
                              Icons.folder_outlined,
                              size: 12,
                              color: AppTheme.textSecondary,
                            ),
                            const Gap(2),
                            Flexible(
                              child: Text(
                                task.projectName!,
                                style: Theme.of(context).textTheme.bodySmall,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),

                // Badges
                Row(
                  children: [
                    if (task.isSystem)
                      const _Badge(
                        label: 'System',
                        color: AppTheme.textDisabled,
                      ),
                    if (task.isReusable && !task.isSystem)
                      const _Badge(
                        label: 'Reusable',
                        color: AppTheme.secondary,
                      ),
                    if (!task.isSystem)
                      IconButton(
                        icon: const Icon(Icons.more_vert, size: 18),
                        color: AppTheme.textSecondary,
                        onPressed: () => _showOptions(context, ref),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                  ],
                ),
              ],
            ),
          ),

          // Sub tasks if any
          if (task.hasProject && !task.isSubTask)
            _SubTaskPreview(parentTaskId: task.id),
        ],
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
    final invalidation = ref.read(invalidationServiceProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(16),

            // Only show Add sub-task for top level non-system tasks
            if (!task.isSystem && !task.isSubTask)
              ListTile(
                leading: Icon(
                  Icons.add_task,
                  color: Theme.of(context).colorScheme.primary,
                ),
                title: Text(
                  'Add sub-task',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => CreateTaskSheet(
                      parentTask: task,
                    ),
                  );
                },
              ),

            if (!task.isSystem)
              ListTile(
                leading: const Icon(Icons.edit_outlined),
                title: const Text('Edit task'),
                onTap: () {
                  Navigator.pop(context);
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    backgroundColor: AppTheme.surface,
                    shape: const RoundedRectangleBorder(
                      borderRadius:
                      BorderRadius.vertical(top: Radius.circular(20)),
                    ),
                    builder: (_) => CreateTaskSheet(existingTask: task),
                  );
                },
              ),

            if (!task.isSystem && task.isReusable)
              ListTile(
                leading: const Icon(Icons.archive_outlined),
                title: const Text('Archive task'),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final repo = ref.read(taskTemplateRepositoryProvider);
                    await repo.archive(task.id);
                    invalidation.onTaskChanged();
                  } catch (e, stack) {
                    await logger.error('TaskCard.archive', e, stack);
                    if (context.mounted) {
                      SnackbarHelper.showError(
                          context, ErrorMessages.archiveTaskFailed);
                    }
                  }
                },
              ),

            if (!task.isSystem)
              ListTile(
                leading: const Icon(
                  Icons.delete_outline,
                  color: AppTheme.error,
                ),
                title: const Text(
                  'Delete task',
                  style: TextStyle(color: AppTheme.error),
                ),
                onTap: () async {
                  Navigator.pop(context);
                  try {
                    final repo = ref.read(taskTemplateRepositoryProvider);
                    await repo.delete(task.id);
                    invalidation.onTaskChanged();
                  } catch (e, stack) {
                    await logger.error('TaskCard.delete', e, stack);
                    if (context.mounted) {
                      SnackbarHelper.showError(
                          context, ErrorMessages.deleteTaskFailed);
                    }
                  }
                },
              ),

            const Gap(8),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(right: 4),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _SubTaskPreview extends ConsumerWidget {
  final String parentTaskId;

  const _SubTaskPreview({required this.parentTaskId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subTasksAsync = ref.watch(subTasksProvider(parentTaskId));

    return subTasksAsync.when(
      data: (subTasks) {
        if (subTasks.isEmpty) return const SizedBox.shrink();

        return Column(
          children: [
            const Divider(height: 1, color: AppTheme.surfaceVariant),
            ...subTasks.map((sub) => _SubTaskRow(subTask: sub)),
          ],
        );
      },
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }
}

class _SubTaskRow extends ConsumerWidget {
  final TaskTemplate subTask;

  const _SubTaskRow({required this.subTask});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = parseColor(
      subTask.categoryColor,
      fallback: Theme.of(context).colorScheme.primary,
    );

    return GestureDetector(
      onTap: () => _showSubTaskOptions(context, ref),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
        child: Row(
          children: [
            const Icon(
              Icons.subdirectory_arrow_right,
              size: 14,
              color: AppTheme.textDisabled,
            ),
            const Gap(8),
            Container(
              width: 3,
              height: 24,
              decoration: BoxDecoration(
                color: color,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(8),
            Expanded(
              child: Text(
                subTask.name,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: AppTheme.textPrimary,
                ),
              ),
            ),
            if (subTask.categoryName != null)
              Text(
                subTask.categoryName!,
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            const Gap(8),
            const Icon(
              Icons.more_vert,
              size: 14,
              color: AppTheme.textSecondary,
            ),
          ],
        ),
      ),
    );
  }

  void _showSubTaskOptions(BuildContext context, WidgetRef ref) {
    final invalidation = ref.read(invalidationServiceProvider);
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  subTask.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.textPrimary,
                  ),
                ),
              ),
            ),
            const Gap(8),
            const Divider(height: 1),
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit sub-task'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius:
                    BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => CreateTaskSheet(existingTask: subTask),
                );
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
              ),
              title: const Text(
                'Delete sub-task',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                try {
                  final repo = ref.read(taskTemplateRepositoryProvider);
                  await repo.delete(subTask.id);
                  invalidation.onSubTaskChanged(subTask.parentTaskId!);
                } catch (e, stack) {
                  await logger.error('SubTaskRow.delete', e, stack);
                  if (context.mounted) {
                    SnackbarHelper.showError(
                        context, ErrorMessages.deleteTaskFailed);
                  }
                }
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }
}