import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../main.dart';
import 'task_category_repository.dart';
import 'project_repository.dart';
import 'task_template_repository.dart';
import 'scheduled_block_repository.dart';

final taskCategoryRepositoryProvider = Provider<TaskCategoryRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskCategoryRepository(db);
});

final projectRepositoryProvider = Provider<ProjectRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ProjectRepository(db);
});

final taskTemplateRepositoryProvider = Provider<TaskTemplateRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return TaskTemplateRepository(db);
});

final scheduledBlockRepositoryProvider =
Provider<ScheduledBlockRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  return ScheduledBlockRepository(db);
});