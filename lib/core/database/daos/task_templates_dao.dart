import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/task_templates_table.dart';

part 'task_templates_dao.g.dart';

@DriftAccessor(tables: [TaskTemplatesTable])
class TaskTemplatesDao extends DatabaseAccessor<AppDatabase>
    with _$TaskTemplatesDaoMixin {
  TaskTemplatesDao(super.db);

  Future<List<TaskTemplatesTableData>> getAll() =>
      (select(taskTemplatesTable)
        ..where((t) => t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<TaskTemplatesTableData>> getByCategory(String categoryId) =>
      (select(taskTemplatesTable)
        ..where((t) =>
        t.categoryId.equals(categoryId) &
        t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<TaskTemplatesTableData>> getByProject(String projectId) =>
      (select(taskTemplatesTable)
        ..where((t) =>
        t.projectId.equals(projectId) &
        t.isArchived.equals(false) &
        t.parentTaskId.isNull())
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<TaskTemplatesTableData>> getSubTasks(String parentTaskId) =>
      (select(taskTemplatesTable)
        ..where((t) =>
        t.parentTaskId.equals(parentTaskId) &
        t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<List<TaskTemplatesTableData>> getReusable() =>
      (select(taskTemplatesTable)
        ..where((t) =>
        t.isReusable.equals(true) & t.isArchived.equals(false))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<TaskTemplatesTableData?> getById(String id) =>
      (select(taskTemplatesTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertTask(TaskTemplatesTableCompanion entry) =>
      into(taskTemplatesTable).insert(entry);

  Future<bool> updateTask(TaskTemplatesTableCompanion entry) =>
      update(taskTemplatesTable).replace(entry);

  Future<int> archiveTask(String id) =>
      (update(taskTemplatesTable)..where((t) => t.id.equals(id)))
          .write(const TaskTemplatesTableCompanion(
        isArchived: Value(true),
      ));

  Future<int> deleteTask(String id) =>
      (delete(taskTemplatesTable)..where((t) => t.id.equals(id))).go();

  Future<List<TaskTemplatesTableData>> getDirty() =>
      (select(taskTemplatesTable)
        ..where((t) => t.isDirty.equals(true)))
          .get();

  Stream<List<TaskTemplatesTableData>> watchAll() =>
      (select(taskTemplatesTable)
        ..where((t) => t.isArchived.equals(false)))
          .watch();
}