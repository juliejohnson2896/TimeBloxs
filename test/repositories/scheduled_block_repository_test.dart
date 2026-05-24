import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/models/scheduled_block.dart';
import 'package:timebloxs/core/models/task_template.dart';
import 'package:timebloxs/core/repositories/scheduled_block_repository.dart';
import 'package:timebloxs/core/repositories/task_category_repository.dart';
import 'package:timebloxs/core/repositories/task_template_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ScheduledBlockRepository repo;
  late TaskCategoryRepository categoryRepo;
  late TaskTemplateRepository taskRepo;
  late String focusCategoryId;
  late String taskId;
  final testDate = DateTime(2024, 1, 15);

  setUp(() async {
    db = createTestDatabase();
    repo = ScheduledBlockRepository(db);
    categoryRepo = TaskCategoryRepository(db);
    taskRepo = TaskTemplateRepository(db);

    final categories = await categoryRepo.getAll();
    focusCategoryId =
        categories.firstWhere((c) => c.name == 'Focus').id;

    final task = await taskRepo.create(TaskTemplate(
      id: '',
      name: 'Test Task',
      categoryId: focusCategoryId,
      isSystem: false,
      isReusable: false,
      isArchived: false,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
    taskId = task.id;
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to create a test block
  Future<ScheduledBlock> createTestBlock({
    DateTime? date,
    String startTime = '09:00',
    int durationMins = 60,
    String label = 'Test Block',
    BlockType blockType = BlockType.dynamic,
    String? taskTemplateId,
    String? categoryId,
  }) async {
    return repo.create(ScheduledBlock(
      id: '',
      date: date ?? testDate,
      startTime: startTime,
      durationMins: durationMins,
      label: label,
      blockType: blockType,
      taskTemplateId: taskTemplateId,
      categoryId: categoryId ?? focusCategoryId,
      status: BlockStatus.planned,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
  }

  group('ScheduledBlockRepository', () {
    group('create', () {
      test('creates block with generated id', () async {
        final block = await createTestBlock();
        expect(block.id, isNotEmpty);
      });

      test('creates block with correct fields', () async {
        final block = await createTestBlock(
          label: 'Morning Focus',
          startTime: '09:00',
          durationMins: 90,
        );

        expect(block.label, equals('Morning Focus'));
        expect(block.startTime, equals('09:00'));
        expect(block.durationMins, equals(90));
        expect(block.status, equals(BlockStatus.planned));
      });

      test('creates static block with task assigned', () async {
        final block = await createTestBlock(
          blockType: BlockType.static,
          taskTemplateId: taskId,
        );

        expect(block.blockType, equals(BlockType.static));
        expect(block.taskTemplateId, equals(taskId));
        expect(block.isAssigned, isTrue);
      });

      test('creates dynamic block without task', () async {
        final block = await createTestBlock(
          blockType: BlockType.dynamic,
        );

        expect(block.isDynamic, isTrue);
        expect(block.isAssigned, isFalse);
      });
    });

    group('getForDate', () {
      test('returns blocks for correct date', () async {
        await createTestBlock(date: testDate, label: 'Today Block');
        await createTestBlock(
          date: testDate.add(const Duration(days: 1)),
          label: 'Tomorrow Block',
        );

        final blocks = await repo.getForDate(testDate);
        expect(blocks.any((b) => b.label == 'Today Block'), isTrue);
        expect(blocks.any((b) => b.label == 'Tomorrow Block'), isFalse);
      });

      test('returns empty list for date with no blocks', () async {
        final blocks =
        await repo.getForDate(DateTime(2099, 12, 31));
        expect(blocks, isEmpty);
      });

      test('returns blocks sorted by start time', () async {
        await createTestBlock(startTime: '14:00', label: 'Afternoon');
        await createTestBlock(startTime: '09:00', label: 'Morning');
        await createTestBlock(startTime: '12:00', label: 'Noon');

        final blocks = await repo.getForDate(testDate);
        final labels = blocks.map((b) => b.label).toList();

        expect(labels.indexOf('Morning'),
            lessThan(labels.indexOf('Noon')));
        expect(labels.indexOf('Noon'),
            lessThan(labels.indexOf('Afternoon')));
      });

      test('returns multiple blocks for same date', () async {
        await createTestBlock(startTime: '09:00', label: 'Block 1');
        await createTestBlock(startTime: '11:00', label: 'Block 2');
        await createTestBlock(startTime: '14:00', label: 'Block 3');

        final blocks = await repo.getForDate(testDate);
        expect(blocks.length, equals(3));
      });
    });

    group('getForDateRange', () {
      test('returns blocks within range', () async {
        await createTestBlock(
            date: testDate, label: 'Day 1');
        await createTestBlock(
            date: testDate.add(const Duration(days: 1)),
            label: 'Day 2');
        await createTestBlock(
            date: testDate.add(const Duration(days: 2)),
            label: 'Day 3');
        await createTestBlock(
            date: testDate.add(const Duration(days: 5)),
            label: 'Outside Range');

        final blocks = await repo.getForDateRange(
          testDate,
          testDate.add(const Duration(days: 2)),
        );

        expect(blocks.length, equals(3));
        expect(
            blocks.any((b) => b.label == 'Outside Range'), isFalse);
      });
    });

    group('update', () {
      test('updates block label', () async {
        final block = await createTestBlock(label: 'Old Label');
        final updated =
        await repo.update(block.copyWith(label: 'New Label'));

        expect(updated.label, equals('New Label'));
        expect(updated.id, equals(block.id));
      });

      test('updates block status', () async {
        final block = await createTestBlock();
        final updated = await repo
            .update(block.copyWith(status: BlockStatus.completed));

        expect(updated.status, equals(BlockStatus.completed));
      });

      test('persists update', () async {
        final block = await createTestBlock(label: 'Before');
        await repo.update(block.copyWith(label: 'After'));

        final found = await repo.getById(block.id);
        expect(found!.label, equals('After'));
      });
    });

    group('updateStatus', () {
      test('updates status to active', () async {
        final block = await createTestBlock();
        final updated =
        await repo.updateStatus(block.id, BlockStatus.active);

        expect(updated.status, equals(BlockStatus.active));
      });

      test('updates status to completed', () async {
        final block = await createTestBlock();
        final updated =
        await repo.updateStatus(block.id, BlockStatus.completed);

        expect(updated.status, equals(BlockStatus.completed));
      });

      test('updates status to skipped', () async {
        final block = await createTestBlock();
        final updated =
        await repo.updateStatus(block.id, BlockStatus.skipped);

        expect(updated.status, equals(BlockStatus.skipped));
      });
    });

    group('assignTask', () {
      test('assigns task to dynamic block', () async {
        final block = await createTestBlock(
          blockType: BlockType.dynamic,
        );
        expect(block.isAssigned, isFalse);

        final assigned = await repo.assignTask(block.id, taskId);
        expect(assigned.taskTemplateId, equals(taskId));
        expect(assigned.isAssigned, isTrue);
      });

      test('reassigns task to already assigned block', () async {
        final task2 = await taskRepo.create(TaskTemplate(
          id: '',
          name: 'Task 2',
          categoryId: focusCategoryId,
          isSystem: false,
          isReusable: false,
          isArchived: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final block = await createTestBlock(taskTemplateId: taskId);
        final reassigned = await repo.assignTask(block.id, task2.id);

        expect(reassigned.taskTemplateId, equals(task2.id));
      });
    });

    group('unassignTask', () {
      test('removes task from assigned block', () async {
        final block = await createTestBlock(
          blockType: BlockType.dynamic,
          taskTemplateId: taskId,
        );
        expect(block.isAssigned, isTrue);

        final unassigned = await repo.unassignTask(block.id);
        expect(unassigned.taskTemplateId, isNull);
        expect(unassigned.isAssigned, isFalse);
      });

      test('persists unassign', () async {
        final block = await createTestBlock(taskTemplateId: taskId);
        await repo.unassignTask(block.id);

        final found = await repo.getById(block.id);
        expect(found!.taskTemplateId, isNull);
      });
    });

    group('delete', () {
      test('deletes a block', () async {
        final block = await createTestBlock();
        await repo.delete(block.id);

        final found = await repo.getById(block.id);
        expect(found, isNull);
      });

      test('deleted block not returned by getForDate', () async {
        final block = await createTestBlock(label: 'Delete Me');
        final before = await repo.getForDate(testDate);

        await repo.delete(block.id);

        final after = await repo.getForDate(testDate);
        expect(after.length, equals(before.length - 1));
        expect(after.any((b) => b.id == block.id), isFalse);
      });

      test('does not affect other blocks', () async {
        final keep = await createTestBlock(label: 'Keep Me');
        final toDelete = await createTestBlock(label: 'Delete Me');

        await repo.delete(toDelete.id);

        final found = await repo.getById(keep.id);
        expect(found, isNotNull);
      });
    });

    group('getByTaskTemplateId', () {
      test('returns blocks assigned to a specific task', () async {
        final block1 = await createTestBlock(
          label: 'Block with task',
          taskTemplateId: taskId,
          blockType: BlockType.static,
        );
        await createTestBlock(
          label: 'Block without task',
        );

        final blocks = await repo.getByTaskTemplateId(taskId);
        expect(blocks.length, equals(1));
        expect(blocks.first.id, equals(block1.id));
      });

      test('returns empty list when no blocks assigned to task', () async {
        final blocks =
        await repo.getByTaskTemplateId('non_existent_task');
        expect(blocks, isEmpty);
      });

      test('returns multiple blocks assigned to same task', () async {
        await createTestBlock(
          label: 'Block 1',
          taskTemplateId: taskId,
          startTime: '09:00',
        );
        await createTestBlock(
          label: 'Block 2',
          taskTemplateId: taskId,
          startTime: '14:00',
        );
        await createTestBlock(
          label: 'Block 3 no task',
        );

        final blocks = await repo.getByTaskTemplateId(taskId);
        expect(blocks.length, equals(2));
        expect(blocks.every((b) => b.taskTemplateId == taskId), isTrue);
      });
    });
  });
}