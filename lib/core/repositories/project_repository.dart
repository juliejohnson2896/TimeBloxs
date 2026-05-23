import 'package:drift/drift.dart';
import 'package:uuid/uuid.dart';
import '../database/app_database.dart';
import '../models/project.dart';

class ProjectRepository {
  final AppDatabase _db;
  final _uuid = const Uuid();

  ProjectRepository(this._db);

  Future<List<Project>> getAll() async {
    final rows = await _db.projectsDao.getAll();
    return rows.map(_fromRow).toList();
  }

  Future<List<Project>> getActive() async {
    final rows = await _db.projectsDao.getActive();
    return rows.map(_fromRow).toList();
  }

  Future<Project?> getById(String id) async {
    final row = await _db.projectsDao.getById(id);
    return row != null ? _fromRow(row) : null;
  }

  Future<Project> create(Project project) async {
    final now = DateTime.now();
    final id = _uuid.v4();
    await _db.projectsDao.insertProject(
      ProjectsTableCompanion.insert(
        id: id,
        name: project.name,
        description: Value(project.description),
        color: Value(project.color),
        icon: Value(project.icon),
        status: Value(project.status.toJson()),
        isDirty: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );
    return (await getById(id))!;
  }

  Future<Project> update(Project project) async {
    final now = DateTime.now();
    await _db.projectsDao.updateProject(
      ProjectsTableCompanion(
        id: Value(project.id),
        name: Value(project.name),
        description: Value(project.description),
        color: Value(project.color),
        icon: Value(project.icon),
        status: Value(project.status.toJson()),
        isDirty: const Value(true),
        createdAt: Value(project.created),
        updatedAt: Value(now),
      ),
    );
    return (await getById(project.id))!;
  }

  Future<void> delete(String id) async {
    await _db.projectsDao.deleteProject(id);
  }

  Project _fromRow(ProjectsTableData row) {
    return Project(
      id: row.id,
      name: row.name,
      description: row.description,
      color: row.color,
      icon: row.icon,
      status: ProjectStatus.fromString(row.status),
      created: row.createdAt,
      updated: row.updatedAt,
    );
  }
}