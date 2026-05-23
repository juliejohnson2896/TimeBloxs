
import 'package:drift/drift.dart' hide isNotNull, isNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/database/tables/task_categories_table.dart';
import 'package:timebloxs/core/database/tables/task_templates_table.dart';
import 'package:timebloxs/core/database/tables/projects_table.dart';
import 'package:timebloxs/core/database/tables/scheduled_blocks_table.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  // ── TaskCategoriesDao ──────────────────────────────────────

  group('TaskCategoriesDao', () {
    test('getAll returns seeded categories', () async {
      final categories = await db.taskCategoriesDao.getAll();
      expect(categories, isNotEmpty);
      expect(
        categories.any((c) => c.name == 'Mindful Breaks'),
        isTrue,
      );
    });

    test('getById returns correct category', () async {
      final all = await db.taskCategoriesDao.getAll();
      final first = all.first;
      final found = await db.taskCategoriesDao.getById(first.id);
      expect(found, isNotNull);
      expect(found!.id, equals(first.id));
    });

    test('getById returns null for missing id', () async {
      final found = await db.taskCategoriesDao.getById('missing');
      expect(found, isNull);
    });

    test('getSystemCategories returns only system categories', () async {
      final system = await db.taskCategoriesDao.getSystemCategories();
      expect(system.every((c) => c.isSystem), isTrue);
      expect(system.any((c) => c.name == 'Mindful Breaks'), isTrue);
    });

    test('insertCategory adds a new category', () async {
      final before = await db.taskCategoriesDao.getAll();

      await db.taskCategoriesDao.insertCategory(
        TaskCategoriesTableCompanion.insert(
          id: 'test_cat_001',
          name: 'New Category',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final after = await db.taskCategoriesDao.getAll();
      expect(after.length, equals(before.length + 1));
      expect(after.any((c) => c.id == 'test_cat_001'), isTrue);
    });

    test('updateCategory updates fields', () async {
      final all = await db.taskCategoriesDao.getAll();
      final nonSystem = all.firstWhere((c) => !c.isSystem);

      await db.taskCategoriesDao.updateCategory(
        TaskCategoriesTableCompanion(
          id: Value(nonSystem.id),
          name: const Value('Updated Name'),
          color: Value(nonSystem.color),
          isSystem: Value(nonSystem.isSystem),
          isDefault: Value(nonSystem.isDefault),
          createdAt: Value(nonSystem.createdAt),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final updated = await db.taskCategoriesDao.getById(nonSystem.id);
      expect(updated!.name, equals('Updated Name'));
    });

    test('deleteCategory removes the category', () async {
      await db.taskCategoriesDao.insertCategory(
        TaskCategoriesTableCompanion.insert(
          id: 'delete_me',
          name: 'Delete Me',
          color: '#FF0000',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      await db.taskCategoriesDao.deleteCategory('delete_me');
      final found = await db.taskCategoriesDao.getById('delete_me');
      expect(found, isNull);
    });

    test('getDirty returns only dirty categories', () async {
      await db.taskCategoriesDao.insertCategory(
        TaskCategoriesTableCompanion.insert(
          id: 'dirty_cat',
          name: 'Dirty Category',
          color: '#FF0000',
          isDirty: const Value(true),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final dirty = await db.taskCategoriesDao.getDirty();
      expect(dirty.any((c) => c.id == 'dirty_cat'), isTrue);
    });

    test('watchAll emits current categories', () async {
      final categories =
      await db.taskCategoriesDao.watchAll().first;
      expect(categories, isNotEmpty);
    });
  });

  // ── ProjectsDao ────────────────────────────────────────────

  group('ProjectsDao', () {
    Future<void> insertTestProject({
      required String id,
      required String name,
      String status = 'active',
      bool isDirty = false,
    }) async {
      await db.projectsDao.insertProject(
        ProjectsTableCompanion.insert(
          id: id,
          name: name,
          status: Value(status),
          isDirty: Value(isDirty),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    test('getAll returns empty on fresh database', () async {
      final projects = await db.projectsDao.getAll();
      expect(projects, isEmpty);
    });

    test('insertProject adds project', () async {
      await insertTestProject(id: 'proj_001', name: 'Test Project');
      final projects = await db.projectsDao.getAll();
      expect(projects.any((p) => p.id == 'proj_001'), isTrue);
    });

    test('getActive returns only active projects', () async {
      await insertTestProject(
          id: 'active_001', name: 'Active', status: 'active');
      await insertTestProject(
          id: 'hold_001', name: 'On Hold', status: 'on_hold');
      await insertTestProject(
          id: 'done_001', name: 'Completed', status: 'completed');

      final active = await db.projectsDao.getActive();
      expect(active.length, equals(1));
      expect(active.first.id, equals('active_001'));
    });

    test('getById returns correct project', () async {
      await insertTestProject(id: 'find_me', name: 'Find Me');
      final found = await db.projectsDao.getById('find_me');
      expect(found, isNotNull);
      expect(found!.name, equals('Find Me'));
    });

    test('getById returns null for missing id', () async {
      final found = await db.projectsDao.getById('missing');
      expect(found, isNull);
    });

    test('updateProject updates fields', () async {
      await insertTestProject(id: 'update_me', name: 'Before');

      await db.projectsDao.updateProject(
        ProjectsTableCompanion(
          id: const Value('update_me'),
          name: const Value('After'),
          status: const Value('active'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final updated = await db.projectsDao.getById('update_me');
      expect(updated!.name, equals('After'));
    });

    test('deleteProject removes the project', () async {
      await insertTestProject(id: 'delete_me', name: 'Delete Me');
      await db.projectsDao.deleteProject('delete_me');
      final found = await db.projectsDao.getById('delete_me');
      expect(found, isNull);
    });

    test('getDirty returns only dirty projects', () async {
      await insertTestProject(
          id: 'dirty_proj', name: 'Dirty', isDirty: true);
      await insertTestProject(
          id: 'clean_proj', name: 'Clean', isDirty: false);

      final dirty = await db.projectsDao.getDirty();
      expect(dirty.any((p) => p.id == 'dirty_proj'), isTrue);
      expect(dirty.any((p) => p.id == 'clean_proj'), isFalse);
    });

    test('watchAll emits current projects', () async {
      await insertTestProject(id: 'watch_proj', name: 'Watch Me');
      final projects = await db.projectsDao.watchAll().first;
      expect(projects.any((p) => p.id == 'watch_proj'), isTrue);
    });
  });

  // ── TaskTemplatesDao ───────────────────────────────────────

  group('TaskTemplatesDao', () {
    late String categoryId;

    setUp(() async {
      final categories = await db.taskCategoriesDao.getAll();
      categoryId = categories.first.id;
    });

    Future<void> insertTestTask({
      required String id,
      required String name,
      String? parentTaskId,
      bool isArchived = false,
      bool isSystem = false,
      bool isReusable = false,
      bool isDirty = false,
    }) async {
      await db.taskTemplatesDao.insertTask(
        TaskTemplatesTableCompanion.insert(
          id: id,
          name: name,
          categoryId: categoryId,
          parentTaskId: Value(parentTaskId),
          isArchived: Value(isArchived),
          isSystem: Value(isSystem),
          isReusable: Value(isReusable),
          isDirty: Value(isDirty),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    test('getAll excludes archived tasks', () async {
      await insertTestTask(id: 'active_task', name: 'Active');
      await insertTestTask(
          id: 'archived_task', name: 'Archived', isArchived: true);

      final all = await db.taskTemplatesDao.getAll();
      expect(all.any((t) => t.id == 'active_task'), isTrue);
      expect(all.any((t) => t.id == 'archived_task'), isFalse);
    });

    test('getAll excludes sub-tasks', () async {
      await insertTestTask(id: 'parent_task', name: 'Parent');
      await insertTestTask(
        id: 'sub_task',
        name: 'Sub',
        parentTaskId: 'parent_task',
      );

      final all = await db.taskTemplatesDao.getAll();
      expect(all.any((t) => t.id == 'parent_task'), isTrue);
      expect(all.any((t) => t.id == 'sub_task'), isFalse);
    });

    test('getAllIncludingSubTasks includes sub-tasks', () async {
      await insertTestTask(id: 'parent_task', name: 'Parent');
      await insertTestTask(
        id: 'sub_task',
        name: 'Sub',
        parentTaskId: 'parent_task',
      );

      final all =
      await db.taskTemplatesDao.getAllIncludingSubTasks();
      expect(all.any((t) => t.id == 'sub_task'), isTrue);
    });

    test('getByCategory returns filtered tasks', () async {
      await insertTestTask(
          id: 'in_cat', name: 'In Category');

      final categories = await db.taskCategoriesDao.getAll();
      final otherId =
          categories.firstWhere((c) => c.id != categoryId).id;

      await db.taskTemplatesDao.insertTask(
        TaskTemplatesTableCompanion.insert(
          id: 'other_cat',
          name: 'Other Category',
          categoryId: otherId,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );

      final filtered =
      await db.taskTemplatesDao.getByCategory(categoryId);
      expect(filtered.any((t) => t.id == 'in_cat'), isTrue);
      expect(filtered.any((t) => t.id == 'other_cat'), isFalse);
    });

    test('getSubTasks returns only children of parent', () async {
      await insertTestTask(id: 'parent_a', name: 'Parent A');
      await insertTestTask(id: 'parent_b', name: 'Parent B');
      await insertTestTask(
          id: 'sub_a', name: 'Sub A', parentTaskId: 'parent_a');
      await insertTestTask(
          id: 'sub_b', name: 'Sub B', parentTaskId: 'parent_b');

      final subs = await db.taskTemplatesDao.getSubTasks('parent_a');
      expect(subs.length, equals(1));
      expect(subs.first.id, equals('sub_a'));
    });

    test('getReusable returns only reusable tasks', () async {
      await insertTestTask(
          id: 'reusable', name: 'Reusable', isReusable: true);
      await insertTestTask(
          id: 'one_off', name: 'One Off', isReusable: false);

      final reusable = await db.taskTemplatesDao.getReusable();
      expect(reusable.any((t) => t.id == 'reusable'), isTrue);
      expect(reusable.any((t) => t.id == 'one_off'), isFalse);
    });

    test('archiveTask marks task as archived', () async {
      await insertTestTask(id: 'archive_me', name: 'Archive Me');
      await db.taskTemplatesDao.archiveTask('archive_me');

      final all = await db.taskTemplatesDao.getAll();
      expect(all.any((t) => t.id == 'archive_me'), isFalse);
    });

    test('deleteTask removes task', () async {
      await insertTestTask(id: 'delete_me', name: 'Delete Me');
      await db.taskTemplatesDao.deleteTask('delete_me');

      final found = await db.taskTemplatesDao.getById('delete_me');
      expect(found, isNull);
    });

    test('getDirty returns only dirty tasks', () async {
      await insertTestTask(
          id: 'dirty_task', name: 'Dirty', isDirty: true);
      await insertTestTask(
          id: 'clean_task', name: 'Clean', isDirty: false);

      final dirty = await db.taskTemplatesDao.getDirty();
      expect(dirty.any((t) => t.id == 'dirty_task'), isTrue);
      expect(dirty.any((t) => t.id == 'clean_task'), isFalse);
    });

    test('watchAll emits current tasks', () async {
      await insertTestTask(id: 'watch_task', name: 'Watch Me');
      final tasks = await db.taskTemplatesDao.watchAll().first;
      expect(tasks.any((t) => t.id == 'watch_task'), isTrue);
    });

    test('watchAllIncludingSubTasks includes sub-tasks', () async {
      await insertTestTask(id: 'parent', name: 'Parent');
      await insertTestTask(
          id: 'sub', name: 'Sub', parentTaskId: 'parent');

      final tasks = await db.taskTemplatesDao
          .watchAllIncludingSubTasks()
          .first;
      expect(tasks.any((t) => t.id == 'sub'), isTrue);
    });

    test('watchSubTasks emits sub-tasks for parent', () async {
      await insertTestTask(id: 'parent', name: 'Parent');
      await insertTestTask(
          id: 'sub', name: 'Sub', parentTaskId: 'parent');

      final subs =
      await db.taskTemplatesDao.watchSubTasks('parent').first;
      expect(subs.any((t) => t.id == 'sub'), isTrue);
    });
  });

  // ── ScheduledBlocksDao ─────────────────────────────────────

  group('ScheduledBlocksDao', () {
    late String categoryId;
    final testDate = DateTime(2024, 1, 15);

    setUp(() async {
      final categories = await db.taskCategoriesDao.getAll();
      categoryId = categories.first.id;
    });

    Future<void> insertTestBlock({
      required String id,
      required String label,
      DateTime? date,
      String startTime = '09:00',
      int durationMins = 60,
      String blockType = 'dynamic',
      String status = 'planned',
      String? taskTemplateId,
      bool isDirty = false,
    }) async {
      await db.scheduledBlocksDao.insertBlock(
        ScheduledBlocksTableCompanion.insert(
          id: id,
          date: date ?? testDate,
          startTime: startTime,
          durationMins: durationMins,
          label: label,
          blockType: blockType,
          categoryId: categoryId,
          taskTemplateId: Value(taskTemplateId),
          status: Value(status),
          isDirty: Value(isDirty),
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      );
    }

    test('getForDate returns blocks for correct date', () async {
      await insertTestBlock(
          id: 'today', label: 'Today', date: testDate);
      await insertTestBlock(
        id: 'tomorrow',
        label: 'Tomorrow',
        date: testDate.add(const Duration(days: 1)),
      );

      final blocks = await db.scheduledBlocksDao.getForDate(testDate);
      expect(blocks.any((b) => b.id == 'today'), isTrue);
      expect(blocks.any((b) => b.id == 'tomorrow'), isFalse);
    });

    test('getForDate returns blocks sorted by start time', () async {
      await insertTestBlock(
          id: 'b1', label: 'B1', startTime: '14:00');
      await insertTestBlock(
          id: 'b2', label: 'B2', startTime: '09:00');
      await insertTestBlock(
          id: 'b3', label: 'B3', startTime: '11:00');

      final blocks = await db.scheduledBlocksDao.getForDate(testDate);
      final ids = blocks.map((b) => b.id).toList();
      expect(ids.indexOf('b2'), lessThan(ids.indexOf('b3')));
      expect(ids.indexOf('b3'), lessThan(ids.indexOf('b1')));
    });

    test('getForDateRange returns blocks within range', () async {
      await insertTestBlock(
          id: 'day1', label: 'Day 1', date: testDate);
      await insertTestBlock(
        id: 'day2',
        label: 'Day 2',
        date: testDate.add(const Duration(days: 1)),
      );
      await insertTestBlock(
        id: 'day5',
        label: 'Day 5',
        date: testDate.add(const Duration(days: 5)),
      );

      final blocks = await db.scheduledBlocksDao.getForDateRange(
        testDate,
        testDate.add(const Duration(days: 2)),
      );

      expect(blocks.any((b) => b.id == 'day1'), isTrue);
      expect(blocks.any((b) => b.id == 'day2'), isTrue);
      expect(blocks.any((b) => b.id == 'day5'), isFalse);
    });

    test('getById returns correct block', () async {
      await insertTestBlock(id: 'find_me', label: 'Find Me');
      final found = await db.scheduledBlocksDao.getById('find_me');
      expect(found, isNotNull);
      expect(found!.label, equals('Find Me'));
    });

    test('getById returns null for missing id', () async {
      final found = await db.scheduledBlocksDao.getById('missing');
      expect(found, isNull);
    });

    test('updateBlock updates fields', () async {
      await insertTestBlock(id: 'update_me', label: 'Before');

      await db.scheduledBlocksDao.updateBlock(
        ScheduledBlocksTableCompanion(
          id: const Value('update_me'),
          label: const Value('After'),
          date: Value(testDate),
          startTime: const Value('09:00'),
          durationMins: const Value(60),
          blockType: const Value('dynamic'),
          categoryId: Value(categoryId),
          status: const Value('planned'),
          createdAt: Value(DateTime.now()),
          updatedAt: Value(DateTime.now()),
        ),
      );

      final updated =
      await db.scheduledBlocksDao.getById('update_me');
      expect(updated!.label, equals('After'));
    });

    test('deleteBlock removes block', () async {
      await insertTestBlock(id: 'delete_me', label: 'Delete Me');
      await db.scheduledBlocksDao.deleteBlock('delete_me');

      final found = await db.scheduledBlocksDao.getById('delete_me');
      expect(found, isNull);
    });

    test('getDirty returns only dirty blocks', () async {
      await insertTestBlock(
          id: 'dirty_block', label: 'Dirty', isDirty: true);
      await insertTestBlock(
          id: 'clean_block', label: 'Clean', isDirty: false);

      final dirty = await db.scheduledBlocksDao.getDirty();
      expect(dirty.any((b) => b.id == 'dirty_block'), isTrue);
      expect(dirty.any((b) => b.id == 'clean_block'), isFalse);
    });

    test('watchForDate emits blocks for date', () async {
      await insertTestBlock(id: 'watch_block', label: 'Watch Me');
      final blocks =
      await db.scheduledBlocksDao.watchForDate(testDate).first;
      expect(blocks.any((b) => b.id == 'watch_block'), isTrue);
    });
  });

  // ── AppDatabase ────────────────────────────────────────────

  group('AppDatabase', () {
    test('seeds system category on creation', () async {
      final categories = await db.taskCategoriesDao.getAll();
      final mindful =
      categories.firstWhere((c) => c.name == 'Mindful Breaks');

      expect(mindful.isSystem, isTrue);
      expect(mindful.isDefault, isTrue);
    });

    test('seeds all default categories', () async {
      final categories = await db.taskCategoriesDao.getAll();
      final names = categories.map((c) => c.name).toList();

      expect(names, containsAll([
        'Mindful Breaks',
        'Focus',
        'Self Care',
        'Chores',
        'Project Work',
        'Admin',
      ]));
    });

    test('seeds system mindful break tasks', () async {
      final tasks = await db.taskTemplatesDao.getAllIncludingSubTasks();
      final systemTasks = tasks.where((t) => t.isSystem).toList();

      expect(systemTasks.any((t) => t.name == 'Break Time'), isTrue);
      expect(
          systemTasks.any((t) => t.name == '10 Second Stretch'), isTrue);
      expect(
          systemTasks.any((t) => t.name == 'Get Up and Walk Around'),
          isTrue);
      expect(
          systemTasks.any((t) => t.name == 'Deep Breathing'), isTrue);
      expect(systemTasks.any((t) => t.name == 'Step Outside'), isTrue);
    });

    test('system tasks are reusable', () async {
      final tasks = await db.taskTemplatesDao.getAllIncludingSubTasks();
      final systemTasks = tasks.where((t) => t.isSystem).toList();
      expect(systemTasks.every((t) => t.isReusable), isTrue);
    });

    test('system tasks have no user', () async {
      final tasks = await db.taskTemplatesDao.getAllIncludingSubTasks();
      final systemTasks = tasks.where((t) => t.isSystem).toList();
      expect(systemTasks.every((t) => t.id.startsWith('sys_')), isTrue);
    });

    test('all DAOs are accessible', () {
      expect(db.taskCategoriesDao, isNotNull);
      expect(db.projectsDao, isNotNull);
      expect(db.taskTemplatesDao, isNotNull);
      expect(db.scheduledBlocksDao, isNotNull);
    });
  });
}