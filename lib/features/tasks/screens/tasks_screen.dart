import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/task_providers.dart';
import '../widgets/task_filter_bar.dart';
import '../widgets/task_list.dart';
import '../widgets/create_task_sheet.dart';

class TasksScreen extends ConsumerWidget {
  const TasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Task Pool'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateTask(context, ref),
          ),
        ],
      ),
      body: const Column(
        children: [
          TaskFilterBar(),
          Gap(8),
          Expanded(child: TaskList()),
        ],
      ),
    );
  }

  void _showCreateTask(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => const CreateTaskSheet(),
    );
  }
}