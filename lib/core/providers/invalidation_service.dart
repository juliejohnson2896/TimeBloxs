import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/tasks/providers/task_providers.dart';
import '../../features/projects/providers/project_providers.dart';
import '../../features/schedule/providers/schedule_providers.dart';

/// Centralised invalidation service.
/// Call the appropriate method whenever data is mutated.
/// Handles all cascading invalidations automatically.
class InvalidationService {
  final Ref _ref;

  InvalidationService(this._ref);

  /// Call when a project is added, edited, or deleted.
  /// Projects → Tasks → SubTasks → Schedule
  void onProjectChanged() {
    _ref.invalidate(allProjectsProvider);
    _ref.invalidate(projectsProvider);
    _ref.invalidate(activeProjectsProvider);
    onTaskChanged(); // cascade down
  }

  /// Call when a task is added, edited, archived, or deleted.
  /// Tasks → SubTasks → Schedule
  void onTaskChanged() {
    _ref.invalidate(taskTemplatesProvider);
    _ref.invalidate(allTasksForPickerProvider);
    _ref.invalidate(filteredTasksProvider);
    onScheduleChanged(); // cascade down
  }

  /// Call when a sub-task is added, edited, or deleted.
  /// SubTasks → Schedule
  void onSubTaskChanged(String parentTaskId) {
    _ref.invalidate(subTasksProvider(parentTaskId));
    _ref.invalidate(allTasksForPickerProvider);
    onScheduleChanged();
  }

  /// Call when a scheduled block is added, edited, or deleted.
  void onScheduleChanged() {
    _ref.invalidate(scheduledBlocksForDateProvider);
  }
}

final invalidationServiceProvider = Provider<InvalidationService>((ref) {
  return InvalidationService(ref);
});