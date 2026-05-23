import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timebloxs/core/utils/color_utils.dart';
import 'package:timebloxs/features/projects/widgets/create_project_sheet.dart';
import '../../../core/models/project.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../tasks/providers/task_providers.dart';
import '../providers/project_providers.dart';

enum _ProjectDeleteChoice {
  deleteTasks,
  moveToPool,
}

class ProjectCard extends ConsumerWidget {
  final Project project;

  const ProjectCard({super.key, required this.project});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final color = parseColor(project.color, fallback: accentColor);

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Color indicator + icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: color.withValues(alpha: 0.3),
                  width: 1,
                ),
              ),
              child: Icon(
                Icons.folder_outlined,
                color: color,
                size: 22,
              ),
            ),
            const Gap(12),

            // Project info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    project.name,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (project.description != null &&
                      project.description!.isNotEmpty) ...[
                    const Gap(2),
                    Text(
                      project.description!,
                      style: Theme.of(context).textTheme.bodySmall,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const Gap(4),
                  _StatusBadge(status: project.status),
                ],
              ),
            ),

            // Options menu
            IconButton(
              icon: const Icon(Icons.more_vert, size: 18),
              color: AppTheme.textSecondary,
              onPressed: () => _showOptions(context, ref),
            ),
          ],
        ),
      ),
    );
  }

  void _showOptions(BuildContext context, WidgetRef ref) {
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

            // Edit Option
            ListTile(
              leading: const Icon(Icons.edit_outlined),
              title: const Text('Edit project'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => CreateProjectSheet(existingProject: project),
                );
              },
            ),

            // Status options
            ...ProjectStatus.values.where((s) => s != project.status).map(
                  (status) => ListTile(
                leading: Icon(_statusIcon(status)),
                title: Text('Mark as ${status.label}'),
                onTap: () async {
                  Navigator.pop(context);
                  final repo = ref.read(projectRepositoryProvider);
                  await repo.update(project.copyWith(status: status));
                  ref.invalidate(allProjectsProvider);
                },
              ),
            ),

            const Divider(height: 1),

            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
              ),
              title: const Text(
                'Delete project',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                await _handleDelete(context, ref);
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return Icons.play_circle_outline;
      case ProjectStatus.onHold:
        return Icons.pause_circle_outline;
      case ProjectStatus.completed:
        return Icons.check_circle_outline;
      case ProjectStatus.archived:
        return Icons.archive_outlined;
    }
  }

  Future<void> _handleDelete(BuildContext context, WidgetRef ref) async {
    try {
      final taskRepo = ref.read(taskTemplateRepositoryProvider);
      final projectRepo = ref.read(projectRepositoryProvider);

      // Check for tasks belonging to this project
      final tasks = await taskRepo.getByProject(project.id);

      if (tasks.isEmpty) {
        // No tasks — just delete
        if(!context.mounted) return;
        final confirmed = await _confirmDelete(context);
        if (confirmed != true) return;
        await projectRepo.delete(project.id);
        ref.invalidate(allProjectsProvider);
        ref.invalidate(projectsProvider);
        return;
      }

      // Has tasks — show choice dialog
      if (!context.mounted) return;
      final choice = await _showTaskChoiceDialog(context, tasks.length);
      if (choice == null) return; // cancelled

      if (choice == _ProjectDeleteChoice.deleteTasks) {
        // Delete all tasks then delete project
        for (final task in tasks) {
          await taskRepo.delete(task.id);
        }
        await projectRepo.delete(project.id);
      } else {
        // Move tasks to general pool then delete project
        for (final task in tasks) {
          await taskRepo.update(
            task.copyWith(projectId: null),
          );
        }
        await projectRepo.delete(project.id);
      }

      ref.invalidate(allProjectsProvider);
      ref.invalidate(projectsProvider);
      ref.invalidate(taskTemplatesProvider);

    } catch (e, stack) {
      await logger.error('ProjectCard._handleDelete', e, stack);
      if (context.mounted) {
        SnackbarHelper.showError(context, ErrorMessages.deleteProjectFailed);
      }
    }
  }

  Future<bool?> _confirmDelete(BuildContext context) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete project?'),
        content: Text(
          'Are you sure you want to delete "${project.name}"?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }

  Future<_ProjectDeleteChoice?> _showTaskChoiceDialog(
      BuildContext context, int taskCount) {
    return showDialog<_ProjectDeleteChoice>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Project has tasks'),
        content: Text(
          '"${project.name}" has $taskCount ${taskCount == 1 ? 'task' : 'tasks'}. '
              'What would you like to do with ${taskCount == 1 ? 'it' : 'them'}?',
        ),
        actions: [
          // Cancel
          TextButton(
            onPressed: () => Navigator.pop(context, null),
            child: const Text('Cancel'),
          ),
          // Move to general pool
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ProjectDeleteChoice.moveToPool,
            ),
            child: const Text('Move to pool'),
          ),
          // Delete tasks too
          TextButton(
            onPressed: () => Navigator.pop(
              context,
              _ProjectDeleteChoice.deleteTasks,
            ),
            child: const Text(
              'Delete tasks',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final ProjectStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.active:
        return AppTheme.secondary;
      case ProjectStatus.onHold:
        return AppTheme.categoryAdmin;
      case ProjectStatus.completed:
        return AppTheme.categoryMindfulBreaks;
      case ProjectStatus.archived:
        return AppTheme.textDisabled;
    }
  }


}