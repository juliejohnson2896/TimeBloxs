import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/project.dart';
import '../../../core/repositories/repository_providers.dart';

final allProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getAll();
});

final activeProjectsProvider = FutureProvider<List<Project>>((ref) async {
  final repo = ref.watch(projectRepositoryProvider);
  return repo.getActive();
});

enum ProjectStatusFilter { all, active, onHold, completed, archived }

final projectStatusFilterProvider = StateProvider<ProjectStatusFilter>(
      (ref) => ProjectStatusFilter.all,
);

final filteredProjectsProvider =
Provider<AsyncValue<List<Project>>>((ref) {
  final projectsAsync = ref.watch(allProjectsProvider);
  final filter = ref.watch(projectStatusFilterProvider);

  return projectsAsync.whenData((projects) {
    switch (filter) {
      case ProjectStatusFilter.active:
        return projects
            .where((p) => p.status == ProjectStatus.active)
            .toList();
      case ProjectStatusFilter.onHold:
        return projects
            .where((p) => p.status == ProjectStatus.onHold)
            .toList();
      case ProjectStatusFilter.completed:
        return projects
            .where((p) => p.status == ProjectStatus.completed)
            .toList();
      case ProjectStatusFilter.archived:
        return projects
            .where((p) => p.status == ProjectStatus.archived)
            .toList();
      case ProjectStatusFilter.all:
        return projects;
    }
  });
});