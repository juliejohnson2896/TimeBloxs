import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_providers.dart';
import 'task_card.dart';

class TaskList extends ConsumerWidget {
  const TaskList({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasksAsync = ref.watch(filteredTasksProvider);

    return tasksAsync.when(
      data: (tasks) {
        if (tasks.isEmpty) {
          return _buildEmpty(context);
        }

        // Separate system tasks from user tasks
        final systemTasks = tasks.where((t) => t.isSystem).toList();
        final userTasks = tasks.where((t) => !t.isSystem).toList();

        return ListView(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
          children: [
            if (systemTasks.isNotEmpty) ...[
              _buildSectionHeader('Mindful Breaks'),
              const Gap(8),
              ...systemTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(task: task),
              )),
              const Gap(16),
            ],
            if (userTasks.isNotEmpty) ...[
              _buildSectionHeader('Your Tasks'),
              const Gap(8),
              ...userTasks.map((task) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: TaskCard(task: task),
              )),
            ],
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, color: AppTheme.error, size: 48),
            const Gap(16),
            Text(
              'Failed to load tasks',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const Gap(8),
            Text(
              error.toString(),
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 12,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(
            Icons.checklist_outlined,
            size: 64,
            color: AppTheme.textDisabled,
          ),
          const Gap(16),
          Text(
            'No tasks found',
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
              color: AppTheme.textSecondary,
            ),
          ),
          const Gap(8),
          Text(
            'Tap + to create your first task',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}