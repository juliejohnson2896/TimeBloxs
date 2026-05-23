import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/task_category.dart';
import '../../../core/models/task_template.dart';
import '../../../core/models/project.dart';
import '../../../core/repositories/repository_providers.dart';

// ─── Categories ───────────────────────────────────────────────

final taskCategoriesProvider =
FutureProvider<List<TaskCategory>>((ref) async {
  final repo = ref.watch(taskCategoryRepositoryProvider);
  return repo.getAll();
});

// ─── Projects ─────────────────────────────────────────────────

final projectsProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getAll();
});

// ─── Filter state ─────────────────────────────────────────────

enum TaskFilter { all, reusable, oneOff }

final taskFilterProvider = StateProvider<TaskFilter>(
      (ref) => TaskFilter.all,
);

final selectedCategoryProvider = StateProvider<String?>(
      (ref) => null,
);

final selectedProjectProvider = StateProvider<String?>(
      (ref) => null,
);

// ─── Tasks ────────────────────────────────────────────────────

final taskTemplatesProvider =
FutureProvider<List<TaskTemplate>>((ref) async {
  final repo = ref.watch(taskTemplateRepositoryProvider);
  final selectedCategory = ref.watch(selectedCategoryProvider);
  final selectedProject = ref.watch(selectedProjectProvider);

  if (selectedProject != null) {
    return repo.getByProject(selectedProject);
  }

  if (selectedCategory != null) {
    return repo.getByCategory(selectedCategory);
  }

  return repo.getAll();
});

// Filtered view of tasks based on filter + search
final filteredTasksProvider =
Provider<AsyncValue<List<TaskTemplate>>>((ref) {
  final tasksAsync = ref.watch(taskTemplatesProvider);
  final filter = ref.watch(taskFilterProvider);
  final searchQuery = ref.watch(taskSearchQueryProvider).toLowerCase();

  return tasksAsync.whenData((tasks) {
    var filtered = tasks.where((t) => !t.isArchived).toList();

    // Apply reusable/one-off filter
    switch (filter) {
      case TaskFilter.reusable:
        filtered = filtered.where((t) => t.isReusable).toList();
      case TaskFilter.oneOff:
        filtered = filtered.where((t) => !t.isReusable).toList();
      case TaskFilter.all:
        break;
    }

    // Apply search
    if (searchQuery.isNotEmpty) {
      filtered = filtered
          .where((t) => t.name.toLowerCase().contains(searchQuery))
          .toList();
    }

    return filtered;
  });
});

final taskSearchQueryProvider = StateProvider<String>((ref) => '');

// Sub tasks for a given parent
final subTasksProvider =
StreamProvider.family<List<TaskTemplate>, String>((ref, parentId) {
  final repo = ref.watch(taskTemplateRepositoryProvider);
  return repo.watchSubTasks(parentId);
});

// Used by assign task sheet and block sheet — includes sub-tasks
final allTasksForPickerProvider =
FutureProvider<List<TaskTemplate>>((ref) async {
  final repo = ref.watch(taskTemplateRepositoryProvider);
  return repo.getAllIncludingSubTasks();
});