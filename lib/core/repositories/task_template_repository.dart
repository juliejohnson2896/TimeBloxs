import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/task_template.dart';

class TaskTemplateRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TaskTemplateRepository(this._db);

  Future<List<TaskTemplate>> getAll() async {
    final rows = await _db.taskTemplatesDao.getAll();
    return _enrichRows(rows);
  }

  Future<List<TaskTemplate>> getAllIncludingSubTasks() async {
    final rows = await _db.taskTemplatesDao.getAllIncludingSubTasks();
    return _enrichRows(rows);
  }

  Future<List<TaskTemplate>> getByCategory(String categoryId) async {
    final rows = await _db.taskTemplatesDao.getByCategory(categoryId);
    return _enrichRows(rows);
  }

  Future<List<TaskTemplate>> getByProject(String projectId) async {
    final rows = await _db.taskTemplatesDao.getByProject(projectId);
    return _enrichRows(rows);
  }

  Future<List<TaskTemplate>> getSubTasks(String parentTaskId) async {
    final rows = await _db.taskTemplatesDao.getSubTasks(parentTaskId);
    return _enrichRows(rows);
  }

  Future<List<TaskTemplate>> getReusable() async {
    final rows = await _db.taskTemplatesDao.getReusable();
    return _enrichRows(rows);
  }

  Future<TaskTemplate?> getById(String id) async {
    final row = await _db.taskTemplatesDao.getById(id);
    if (row == null) return null;
    final enriched = await _enrichRows([row]);
    return enriched.first;
  }

  Future<TaskTemplate> create(TaskTemplate task) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.taskTemplatesDao.insertTask(
      TaskTemplatesTableCompanion.insert(
        id: id,
        name: task.name,
        categoryId: task.categoryId,
        projectId: Value(task.projectId),
        parentTaskId: Value(task.parentTaskId),
        notes: Value(task.notes),
        isSystem: Value(task.isSystem),
        isReusable: Value(task.isReusable),
        isArchived: Value(task.isArchived),
        isDirty: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await getById(id))!;
  }

  Future<TaskTemplate> update(TaskTemplate task) async {
    final now = DateTime.now();
    await _db.taskTemplatesDao.updateTask(
      TaskTemplatesTableCompanion(
        id: Value(task.id),
        name: Value(task.name),
        categoryId: Value(task.categoryId),
        projectId: Value(task.projectId),
        parentTaskId: Value(task.parentTaskId),
        notes: Value(task.notes),
        isSystem: Value(task.isSystem),
        isReusable: Value(task.isReusable),
        isArchived: Value(task.isArchived),
        isDirty: const Value(true),
        createdAt: Value(task.created),
        updatedAt: Value(now),
      ),
    );
    return (await getById(task.id))!;
  }

  Future<void> archive(String id) async {
    await _db.taskTemplatesDao.archiveTask(id);
  }

  Future<void> delete(String id) async {
    await _db.taskTemplatesDao.deleteTask(id);
  }

  /// Enriches task rows with category and project names
  Future<List<TaskTemplate>> _enrichRows(
      List<TaskTemplatesTableData> rows) async {
    if (rows.isEmpty) return [];

    final categories = await _db.taskCategoriesDao.getAll();
    final projects = await _db.projectsDao.getAll();

    final categoryMap = {for (final c in categories) c.id: c};
    final projectMap = {for (final p in projects) p.id: p};

    return rows.map((row) {
      final category = categoryMap[row.categoryId];
      final project = row.projectId != null ? projectMap[row.projectId] : null;

      return TaskTemplate(
        id: row.id,
        name: row.name,
        categoryId: row.categoryId,
        projectId: row.projectId,
        parentTaskId: row.parentTaskId,
        notes: row.notes,
        isSystem: row.isSystem,
        isReusable: row.isReusable,
        isArchived: row.isArchived,
        created: row.createdAt,
        updated: row.updatedAt,
        categoryName: category?.name,
        categoryColor: category?.color,
        projectName: project?.name,
        projectColor: project?.color,
      );
    }).toList();
  }

  Stream<List<TaskTemplate>> watchSubTasks(String parentTaskId) {
    return _db.taskTemplatesDao.watchSubTasks(parentTaskId).asyncMap(
          (rows) => _enrichRows(rows),
    );
  }
}