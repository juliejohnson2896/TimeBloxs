import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/task_category.dart';

class TaskCategoryRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  TaskCategoryRepository(this._db);

  Future<List<TaskCategory>> getAll() async {
    final rows = await _db.taskCategoriesDao.getAll();
    return rows.map(_fromRow).toList();
  }

  Future<TaskCategory?> getById(String id) async {
    final row = await _db.taskCategoriesDao.getById(id);
    return row != null ? _fromRow(row) : null;
  }

  Future<TaskCategory> create(TaskCategory category) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.taskCategoriesDao.insertCategory(
      TaskCategoriesTableCompanion.insert(
        id: id,
        name: category.name,
        color: category.color,
        icon: Value(category.icon),
        isSystem: Value(category.isSystem),
        isDefault: Value(category.isDefault),
        isDirty: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await getById(id))!;
  }

  Future<TaskCategory> update(TaskCategory category) async {
    final now = DateTime.now();
    await _db.taskCategoriesDao.updateCategory(
      TaskCategoriesTableCompanion(
        id: Value(category.id),
        name: Value(category.name),
        color: Value(category.color),
        icon: Value(category.icon),
        isSystem: Value(category.isSystem),
        isDefault: Value(category.isDefault),
        isDirty: const Value(true),
        createdAt: Value(category.created),
        updatedAt: Value(now),
      ),
    );
    return (await getById(category.id))!;
  }

  Future<void> delete(String id) async {
    await _db.taskCategoriesDao.deleteCategory(id);
  }

  TaskCategory _fromRow(TaskCategoriesTableData row) {
    return TaskCategory(
      id: row.id,
      name: row.name,
      color: row.color,
      icon: row.icon,
      isSystem: row.isSystem,
      isDefault: row.isDefault,
      created: row.createdAt,
      updated: row.updatedAt,
    );
  }
}