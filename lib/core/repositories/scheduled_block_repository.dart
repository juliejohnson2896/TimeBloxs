import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/scheduled_block.dart';
import 'package:rxdart/rxdart.dart';

class ScheduledBlockRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ScheduledBlockRepository(this._db);

  Future<List<ScheduledBlock>> getForDate(DateTime date) async {
    final rows = await _db.scheduledBlocksDao.getForDate(date);
    return _enrichRows(rows);
  }

  Future<List<ScheduledBlock>> getForDateRange(
      DateTime start, DateTime end) async {
    final rows = await _db.scheduledBlocksDao.getForDateRange(start, end);
    return _enrichRows(rows);
  }

  Future<ScheduledBlock?> getById(String id) async {
    final row = await _db.scheduledBlocksDao.getById(id);
    if (row == null) return null;
    final enriched = await _enrichRows([row]);
    return enriched.first;
  }

  Future<ScheduledBlock> create(ScheduledBlock block) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.scheduledBlocksDao.insertBlock(
      ScheduledBlocksTableCompanion.insert(
        id: id,
        date: block.date,
        startTime: block.startTime,
        durationMins: block.durationMins,
        label: block.label,
        blockType: block.blockType.toJson(),
        taskTemplateId: Value(block.taskTemplateId),
        categoryId: block.categoryId,
        status: Value(block.status.toJson()),
        notes: Value(block.notes),
        isDirty: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await getById(id))!;
  }

  Future<ScheduledBlock> update(ScheduledBlock block) async {
    final now = DateTime.now();
    await _db.scheduledBlocksDao.updateBlock(
      ScheduledBlocksTableCompanion(
        id: Value(block.id),
        date: Value(block.date),
        startTime: Value(block.startTime),
        durationMins: Value(block.durationMins),
        label: Value(block.label),
        blockType: Value(block.blockType.toJson()),
        taskTemplateId: Value(block.taskTemplateId),
        categoryId: Value(block.categoryId),
        status: Value(block.status.toJson()),
        notes: Value(block.notes),
        isDirty: const Value(true),
        createdAt: Value(block.created), // preserve original
        updatedAt: Value(now),
      ),
    );
    return (await getById(block.id))!;
  }

  Future<ScheduledBlock> assignTask(
      String blockId, String taskTemplateId) async {
    final block = await getById(blockId);
    if (block == null) throw Exception('Block not found');
    return update(block.copyWith(taskTemplateId: taskTemplateId));
  }

  Future<ScheduledBlock> updateStatus(
      String blockId, BlockStatus status) async {
    final block = await getById(blockId);
    if (block == null) throw Exception('Block not found');
    return update(block.copyWith(status: status));
  }

  Future<void> delete(String id) async {
    await _db.scheduledBlocksDao.deleteBlock(id);
  }

  Stream<List<ScheduledBlock>> watchForDate(DateTime date) {
    final blocksStream = _db.scheduledBlocksDao.watchForDate(date);
    final categoriesStream = _db.taskCategoriesDao.watchAll();
    final tasksStream = _db.taskTemplatesDao.watchAllIncludingSubTasks(); // changed
    final projectsStream = _db.projectsDao.watchAll();

    return Rx.combineLatest4(
      blocksStream,
      categoriesStream,
      tasksStream,
      projectsStream,
          (blocks, categories, tasks, projects) {
        final categoryMap = {for (final c in categories) c.id: c};
        final taskMap = {for (final t in tasks) t.id: t};
        final projectMap = {for (final p in projects) p.id: p};

        return blocks.map((row) {
          final blockCategory = categoryMap[row.categoryId];
          final task = row.taskTemplateId != null
              ? taskMap[row.taskTemplateId]
              : null;
          final taskCategory = task != null
              ? categoryMap[task.categoryId]
              : null;
          final project = task?.projectId != null
              ? projectMap[task!.projectId]
              : null;

          return ScheduledBlock(
            id: row.id,
            date: row.date,
            startTime: row.startTime,
            durationMins: row.durationMins,
            label: row.label,
            blockType: BlockType.fromString(row.blockType),
            taskTemplateId: row.taskTemplateId,
            categoryId: row.categoryId,
            status: BlockStatus.fromString(row.status),
            notes: row.notes,
            created: row.createdAt,
            updated: row.updatedAt,
            taskTemplateName: task?.name,
            categoryName: blockCategory?.name,
            categoryColor: blockCategory?.color,
            taskCategoryColor: taskCategory?.color,  // add this
            projectColor: project?.color,
          );
        }).toList();
      },
    );
  }

  Future<List<ScheduledBlock>> _enrichRows(
      List<ScheduledBlocksTableData> rows) async {
    if (rows.isEmpty) return [];

    final categories = await _db.taskCategoriesDao.getAll();
    final tasks = await _db.taskTemplatesDao.getAllIncludingSubTasks();
    final projects = await _db.projectsDao.getAll();

    final categoryMap = {for (final c in categories) c.id: c};
    final taskMap = {for (final t in tasks) t.id: t};
    final projectMap = {for (final p in projects) p.id: p};

    return rows.map((row) {
      final blockCategory = categoryMap[row.categoryId];
      final task = row.taskTemplateId != null
          ? taskMap[row.taskTemplateId]
          : null;
      final taskCategory = task != null
          ? categoryMap[task.categoryId]
          : null;
      final project = task?.projectId != null
          ? projectMap[task!.projectId]
          : null;

      return ScheduledBlock(
        id: row.id,
        date: row.date,
        startTime: row.startTime,
        durationMins: row.durationMins,
        label: row.label,
        blockType: BlockType.fromString(row.blockType),
        taskTemplateId: row.taskTemplateId,
        categoryId: row.categoryId,
        status: BlockStatus.fromString(row.status),
        notes: row.notes,
        created: row.createdAt,
        updated: row.updatedAt,
        taskTemplateName: task?.name,
        categoryName: blockCategory?.name,
        categoryColor: blockCategory?.color,
        taskCategoryColor: taskCategory?.color,  // add this
        projectColor: project?.color,
      );
    }).toList();
  }

  Future<ScheduledBlock> unassignTask(String blockId) async {
    final block = await getById(blockId);
    if (block == null) throw Exception('Block not found');
    final now = DateTime.now();
    await _db.scheduledBlocksDao.updateBlock(
      ScheduledBlocksTableCompanion(
        id: Value(block.id),
        date: Value(block.date),
        startTime: Value(block.startTime),
        durationMins: Value(block.durationMins),
        label: Value(block.label),
        blockType: Value(block.blockType.toJson()),
        taskTemplateId: const Value(null), // explicitly clear
        categoryId: Value(block.categoryId),
        status: Value(block.status.toJson()),
        notes: Value(block.notes),
        isDirty: const Value(true),
        createdAt: Value(block.created),
        updatedAt: Value(now),
      ),
    );
    return (await getById(blockId))!;
  }

  Future<List<ScheduledBlock>> getByTaskTemplateId(
      String taskTemplateId) async {
    final rows = await _db.scheduledBlocksDao.getByTaskTemplateId(taskTemplateId);
    return _enrichRows(rows);
  }
}