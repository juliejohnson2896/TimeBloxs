import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/task_categories_table.dart';

part 'task_categories_dao.g.dart';

@DriftAccessor(tables: [TaskCategoriesTable])
class TaskCategoriesDao extends DatabaseAccessor<AppDatabase>
    with _$TaskCategoriesDaoMixin {
  TaskCategoriesDao(super.db);

  Future<List<TaskCategoriesTableData>> getAll() =>
      select(taskCategoriesTable).get();

  Future<TaskCategoriesTableData?> getById(String id) =>
      (select(taskCategoriesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<List<TaskCategoriesTableData>> getSystemCategories() =>
      (select(taskCategoriesTable)
        ..where((t) => t.isSystem.equals(true)))
          .get();

  Future<int> insertCategory(TaskCategoriesTableCompanion entry) =>
      into(taskCategoriesTable).insert(entry);

  Future<bool> updateCategory(TaskCategoriesTableCompanion entry) =>
      update(taskCategoriesTable).replace(entry);

  Future<int> deleteCategory(String id) =>
      (delete(taskCategoriesTable)..where((t) => t.id.equals(id))).go();

  Future<List<TaskCategoriesTableData>> getDirty() =>
      (select(taskCategoriesTable)
        ..where((t) => t.isDirty.equals(true)))
          .get();
}