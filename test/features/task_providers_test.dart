import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/features/tasks/providers/task_providers.dart';
import 'package:timebloxs/main.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('taskCategoriesProvider', () {
    test('returns seeded categories', () async {
      final categories =
      await container.read(taskCategoriesProvider.future);
      expect(categories, isNotEmpty);
      expect(
        categories.any((c) => c.name == 'Mindful Breaks'),
        isTrue,
      );
    });

    test('returns all default categories', () async {
      final categories =
      await container.read(taskCategoriesProvider.future);
      expect(categories.length, greaterThanOrEqualTo(6));
    });
  });

  group('projectsProvider', () {
    test('returns empty list on fresh database', () async {
      final projects =
      await container.read(projectsProvider.future);
      expect(projects, isEmpty);
    });
  });

  group('taskTemplatesProvider', () {
    test('returns seeded system tasks', () async {
      final tasks =
      await container.read(taskTemplatesProvider.future);
      expect(tasks.any((t) => t.name == 'Break Time'), isTrue);
    });

    test('excludes sub-tasks', () async {
      final tasks =
      await container.read(taskTemplatesProvider.future);
      expect(tasks.every((t) => !t.isSubTask), isTrue);
    });
  });

  group('taskFilterProvider', () {
    test('initial state is all', () {
      final filter = container.read(taskFilterProvider);
      expect(filter, equals(TaskFilter.all));
    });

    test('can be updated to reusable', () {
      container.read(taskFilterProvider.notifier).state =
          TaskFilter.reusable;
      expect(
        container.read(taskFilterProvider),
        equals(TaskFilter.reusable),
      );
    });

    test('can be updated to oneOff', () {
      container.read(taskFilterProvider.notifier).state =
          TaskFilter.oneOff;
      expect(
        container.read(taskFilterProvider),
        equals(TaskFilter.oneOff),
      );
    });
  });

  group('selectedCategoryProvider', () {
    test('initial state is null', () {
      final selected = container.read(selectedCategoryProvider);
      expect(selected, isNull);
    });

    test('can be set to a category id', () {
      container.read(selectedCategoryProvider.notifier).state =
      'cat_001';
      expect(
        container.read(selectedCategoryProvider),
        equals('cat_001'),
      );
    });

    test('can be cleared back to null', () {
      container.read(selectedCategoryProvider.notifier).state =
      'cat_001';
      container.read(selectedCategoryProvider.notifier).state = null;
      expect(container.read(selectedCategoryProvider), isNull);
    });
  });

  group('selectedProjectProvider', () {
    test('initial state is null', () {
      final selected = container.read(selectedProjectProvider);
      expect(selected, isNull);
    });

    test('can be set to a project id', () {
      container.read(selectedProjectProvider.notifier).state =
      'proj_001';
      expect(
        container.read(selectedProjectProvider),
        equals('proj_001'),
      );
    });
  });

  group('taskSearchQueryProvider', () {
    test('initial state is empty string', () {
      final query = container.read(taskSearchQueryProvider);
      expect(query, equals(''));
    });

    test('can be updated', () {
      container.read(taskSearchQueryProvider.notifier).state =
      'dishes';
      expect(
        container.read(taskSearchQueryProvider),
        equals('dishes'),
      );
    });
  });

  group('allTasksForPickerProvider', () {
    test('includes system tasks', () async {
      final tasks =
      await container.read(allTasksForPickerProvider.future);
      expect(tasks.any((t) => t.isSystem), isTrue);
    });
  });

  // Add these groups to the existing task_providers_test.dart

  group('filteredTasksProvider', () {
    test('returns all non-archived tasks when filter is all', () async {
      final tasks =
      await container.read(taskTemplatesProvider.future);
      expect(tasks.every((t) => !t.isArchived), isTrue);
    });

    test('filter all includes system tasks', () async {
      container.read(taskFilterProvider.notifier).state =
          TaskFilter.all;

      final tasks =
      await container.read(taskTemplatesProvider.future);
      expect(tasks.any((t) => t.isSystem), isTrue);
    });

    test('filter reusable returns only reusable tasks', () async {
      container.read(taskFilterProvider.notifier).state =
          TaskFilter.reusable;

      // System tasks are reusable so they should appear
      final tasks =
      await container.read(taskTemplatesProvider.future);
      final reusable = tasks.where((t) => t.isReusable).toList();
      expect(reusable, isNotEmpty);
    });

    test('search query filters by name', () async {
      container.read(taskSearchQueryProvider.notifier).state =
      'break';

      final tasks =
      await container.read(taskTemplatesProvider.future);
      final matching = tasks
          .where((t) =>
          t.name.toLowerCase().contains('break'))
          .toList();
      expect(matching, isNotEmpty);
    });

    test('search query is case insensitive', () async {
      container.read(taskSearchQueryProvider.notifier).state =
      'BREAK';

      final tasks =
      await container.read(taskTemplatesProvider.future);
      final matching = tasks
          .where((t) =>
          t.name.toLowerCase().contains('break'))
          .toList();
      expect(matching, isNotEmpty);
    });

    test('empty search query returns all tasks', () async {
      container.read(taskSearchQueryProvider.notifier).state = '';

      final tasks =
      await container.read(taskTemplatesProvider.future);
      expect(tasks, isNotEmpty);
    });
  });

  group('subTasksProvider', () {
    test('returns empty stream for task with no sub-tasks', () async {
      final tasks =
      await container.read(taskTemplatesProvider.future);
      final firstTask = tasks.first;

      final subTasks = await container
          .read(subTasksProvider(firstTask.id).future);
      expect(subTasks, isEmpty);
    });
  });
}