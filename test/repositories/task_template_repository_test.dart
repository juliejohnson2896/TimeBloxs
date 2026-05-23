import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/models/project.dart';
import 'package:timebloxs/core/models/task_template.dart';
import 'package:timebloxs/core/repositories/project_repository.dart';
import 'package:timebloxs/core/repositories/task_category_repository.dart';
import 'package:timebloxs/core/repositories/task_template_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskTemplateRepository repo;
  late TaskCategoryRepository categoryRepo;
  late ProjectRepository projectRepo;
  late String focusCategoryId;
  late String projectId;

  setUp(() async {
    db = createTestDatabase();
    repo = TaskTemplateRepository(db);
    categoryRepo = TaskCategoryRepository(db);
    projectRepo = ProjectRepository(db);

    // Get the seeded Focus category id
    final categories = await categoryRepo.getAll();
    focusCategoryId =
        categories.firstWhere((c) => c.name == 'Focus').id;

    // Create a test project
    final project = await projectRepo.create(Project(
      id: '',
      name: 'Test Project',
      color: '#F44336',
      status: ProjectStatus.active,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
    projectId = project.id;
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to create a test task
  Future<TaskTemplate> createTestTask({
    String name = 'Test Task',
    String? categoryId,
    String? projectId,
    String? parentTaskId,
    bool isReusable = false,
  }) async {
    return repo.create(TaskTemplate(
      id: '',
      name: name,
      categoryId: categoryId ?? focusCategoryId,
      projectId: projectId,
      parentTaskId: parentTaskId,
      isSystem: false,
      isReusable: isReusable,
      isArchived: false,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
  }

  group('TaskTemplateRepository', () {
    group('getAll', () {
      test('returns seeded system tasks', () async {
        final tasks = await repo.getAll();
        expect(tasks.any((t) => t.name == 'Break Time'), isTrue);
        expect(tasks.any((t) => t.name == '10 Second Stretch'), isTrue);
      });

      test('excludes sub-tasks from main pool', () async {
        final parent = await createTestTask(name: 'Parent Task');
        await createTestTask(
          name: 'Sub Task',
          parentTaskId: parent.id,
        );

        final all = await repo.getAll();
        expect(all.any((t) => t.name == 'Sub Task'), isFalse);
        expect(all.any((t) => t.name == 'Parent Task'), isTrue);
      });

      test('excludes archived tasks', () async {
        final task = await createTestTask(name: 'Archive Me');
        await repo.archive(task.id);

        final all = await repo.getAll();
        expect(all.any((t) => t.name == 'Archive Me'), isFalse);
      });
    });

    group('create', () {
      test('creates task with generated id', () async {
        final task = await createTestTask();
        expect(task.id, isNotEmpty);
      });

      test('creates task with enriched category name', () async {
        final task = await createTestTask(name: 'Enriched Task');
        expect(task.categoryName, equals('Focus'));
      });

      test('creates task with enriched project name', () async {
        final task = await createTestTask(
          name: 'Project Task',
          projectId: projectId,
        );
        expect(task.projectName, equals('Test Project'));
      });

      test('creates reusable task', () async {
        final task =
        await createTestTask(name: 'Reusable', isReusable: true);
        expect(task.isReusable, isTrue);
      });
    });

    group('getByCategory', () {
      test('returns tasks filtered by category', () async {
        await createTestTask(name: 'Focus Task', categoryId: focusCategoryId);

        final categories = await categoryRepo.getAll();
        final choresId =
            categories.firstWhere((c) => c.name == 'Chores').id;
        await createTestTask(name: 'Chores Task', categoryId: choresId);

        final focusTasks = await repo.getByCategory(focusCategoryId);
        expect(focusTasks.every((t) => t.categoryId == focusCategoryId),
            isTrue);
        expect(focusTasks.any((t) => t.name == 'Focus Task'), isTrue);
        expect(focusTasks.any((t) => t.name == 'Chores Task'), isFalse);
      });
    });

    group('getByProject', () {
      test('returns tasks filtered by project', () async {
        await createTestTask(
            name: 'Project Task', projectId: projectId);
        await createTestTask(name: 'General Task');

        final projectTasks = await repo.getByProject(projectId);
        expect(
            projectTasks.every((t) => t.projectId == projectId), isTrue);
        expect(
            projectTasks.any((t) => t.name == 'Project Task'), isTrue);
        expect(
            projectTasks.any((t) => t.name == 'General Task'), isFalse);
      });

      test('excludes sub-tasks from project tasks', () async {
        final parent = await createTestTask(
            name: 'Parent', projectId: projectId);
        await createTestTask(
          name: 'Sub Task',
          projectId: projectId,
          parentTaskId: parent.id,
        );

        final projectTasks = await repo.getByProject(projectId);
        expect(projectTasks.any((t) => t.name == 'Sub Task'), isFalse);
      });
    });

    group('getSubTasks', () {
      test('returns sub-tasks for a parent', () async {
        final parent = await createTestTask(name: 'Parent');
        await createTestTask(name: 'Sub 1', parentTaskId: parent.id);
        await createTestTask(name: 'Sub 2', parentTaskId: parent.id);

        final subTasks = await repo.getSubTasks(parent.id);
        expect(subTasks.length, equals(2));
        expect(subTasks.any((t) => t.name == 'Sub 1'), isTrue);
        expect(subTasks.any((t) => t.name == 'Sub 2'), isTrue);
      });

      test('returns empty list when parent has no sub-tasks', () async {
        final parent = await createTestTask(name: 'Lonely Parent');
        final subTasks = await repo.getSubTasks(parent.id);
        expect(subTasks, isEmpty);
      });

      test('sub-tasks have correct parentTaskId', () async {
        final parent = await createTestTask(name: 'Parent');
        await createTestTask(name: 'Sub', parentTaskId: parent.id);

        final subTasks = await repo.getSubTasks(parent.id);
        expect(subTasks.every((t) => t.parentTaskId == parent.id), isTrue);
      });
    });

    group('getReusable', () {
      test('returns only reusable tasks', () async {
        await createTestTask(name: 'Reusable', isReusable: true);
        await createTestTask(name: 'One-off', isReusable: false);

        final reusable = await repo.getReusable();
        expect(reusable.any((t) => t.name == 'Reusable'), isTrue);
        expect(reusable.any((t) => t.name == 'One-off'), isFalse);
      });

      test('includes system reusable tasks', () async {
        final reusable = await repo.getReusable();
        expect(reusable.any((t) => t.name == 'Break Time'), isTrue);
      });
    });

    group('update', () {
      test('updates task name', () async {
        final task = await createTestTask(name: 'Old Name');
        final updated = await repo.update(task.copyWith(name: 'New Name'));

        expect(updated.name, equals('New Name'));
        expect(updated.id, equals(task.id));
      });

      test('persists update', () async {
        final task = await createTestTask(name: 'Before');
        await repo.update(task.copyWith(name: 'After'));

        final found = await repo.getById(task.id);
        expect(found!.name, equals('After'));
      });
    });

    group('archive', () {
      test('archives a task', () async {
        final task = await createTestTask(name: 'Archive Me');
        await repo.archive(task.id);

        final all = await repo.getAll();
        expect(all.any((t) => t.id == task.id), isFalse);
      });

      test('archived task not returned by getAll', () async {
        final task = await createTestTask(name: 'Will Be Archived');
        final before = await repo.getAll();

        await repo.archive(task.id);

        final after = await repo.getAll();
        expect(after.length, equals(before.length - 1));
      });
    });

    group('delete', () {
      test('deletes a task permanently', () async {
        final task = await createTestTask(name: 'Delete Me');
        await repo.delete(task.id);

        final found = await repo.getById(task.id);
        expect(found, isNull);
      });

      test('does not affect other tasks', () async {
        final keep = await createTestTask(name: 'Keep Me');
        final toDelete = await createTestTask(name: 'Delete Me');

        await repo.delete(toDelete.id);

        final found = await repo.getById(keep.id);
        expect(found, isNotNull);
      });
    });

    group('getAllIncludingSubTasks', () {
      test('includes sub-tasks', () async {
        final parent = await createTestTask(name: 'Parent');
        await createTestTask(name: 'Sub Task', parentTaskId: parent.id);

        final all = await repo.getAllIncludingSubTasks();
        expect(all.any((t) => t.name == 'Sub Task'), isTrue);
      });

      test('includes top level tasks', () async {
        await createTestTask(name: 'Top Level');
        final all = await repo.getAllIncludingSubTasks();
        expect(all.any((t) => t.name == 'Top Level'), isTrue);
      });
    });
  });
}