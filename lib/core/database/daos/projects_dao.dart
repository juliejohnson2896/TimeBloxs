import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/projects_table.dart';

part 'projects_dao.g.dart';

@DriftAccessor(tables: [ProjectsTable])
class ProjectsDao extends DatabaseAccessor<AppDatabase>
    with _$ProjectsDaoMixin {
  ProjectsDao(super.db);

  Future<List<ProjectsTableData>> getAll() =>
      (select(projectsTable)..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .get();

  Future<List<ProjectsTableData>> getActive() =>
      (select(projectsTable)
        ..where((t) => t.status.equals('active'))
        ..orderBy([(t) => OrderingTerm.asc(t.name)]))
          .get();

  Future<ProjectsTableData?> getById(String id) =>
      (select(projectsTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertProject(ProjectsTableCompanion entry) =>
      into(projectsTable).insert(entry);

  Future<bool> updateProject(ProjectsTableCompanion entry) =>
      update(projectsTable).replace(entry);

  Future<int> deleteProject(String id) =>
      (delete(projectsTable)..where((t) => t.id.equals(id))).go();

  Future<List<ProjectsTableData>> getDirty() =>
      (select(projectsTable)..where((t) => t.isDirty.equals(true))).get();
}