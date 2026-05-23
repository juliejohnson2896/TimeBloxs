import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/models/project.dart';
import 'package:timebloxs/core/repositories/project_repository.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProjectRepository repo;

  setUp(() async {
    db = createTestDatabase();
    repo = ProjectRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  // Helper to create a test project
  Future<Project> createTestProject({
    String name = 'Test Project',
    String color = '#F44336',
    ProjectStatus status = ProjectStatus.active,
  }) async {
    return repo.create(Project(
      id: '',
      name: name,
      description: 'Test description',
      color: color,
      status: status,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
  }

  group('ProjectRepository', () {
    group('getAll', () {
      test('returns empty list on fresh database', () async {
        final projects = await repo.getAll();
        expect(projects, isEmpty);
      });

      test('returns all created projects', () async {
        await createTestProject(name: 'Project A');
        await createTestProject(name: 'Project B');

        final projects = await repo.getAll();
        expect(projects.length, equals(2));
      });

      test('returns all created projects in getAll', () async {
        await createTestProject(name: 'Project A');
        await createTestProject(name: 'Project B');
        await createTestProject(name: 'Project C');

        final projects = await repo.getAll();
        expect(projects.length, equals(3));
        expect(projects.map((p) => p.name),
            containsAll(['Project A', 'Project B', 'Project C']));
      });
    });

    group('getActive', () {
      test('returns only active projects', () async {
        await createTestProject(
            name: 'Active', status: ProjectStatus.active);
        await createTestProject(
            name: 'On Hold', status: ProjectStatus.onHold);
        await createTestProject(
            name: 'Completed', status: ProjectStatus.completed);
        await createTestProject(
            name: 'Archived', status: ProjectStatus.archived);

        final active = await repo.getActive();
        expect(active.length, equals(1));
        expect(active.first.name, equals('Active'));
      });

      test('returns empty list when no active projects', () async {
        await createTestProject(
            name: 'On Hold', status: ProjectStatus.onHold);
        final active = await repo.getActive();
        expect(active, isEmpty);
      });
    });

    group('create', () {
      test('creates project with generated id', () async {
        final project = await createTestProject();
        expect(project.id, isNotEmpty);
      });

      test('creates project with correct fields', () async {
        final project = await createTestProject(
          name: 'TitanServer',
          color: '#2196F3',
        );

        expect(project.name, equals('TitanServer'));
        expect(project.color, equals('#2196F3'));
        expect(project.status, equals(ProjectStatus.active));
      });

      test('creates multiple projects with unique ids', () async {
        final p1 = await createTestProject(name: 'Project 1');
        final p2 = await createTestProject(name: 'Project 2');
        expect(p1.id, isNot(equals(p2.id)));
      });
    });

    group('getById', () {
      test('returns project by id', () async {
        final created = await createTestProject(name: 'Find Me');
        final found = await repo.getById(created.id);

        expect(found, isNotNull);
        expect(found!.name, equals('Find Me'));
      });

      test('returns null for non-existent id', () async {
        final found = await repo.getById('does_not_exist');
        expect(found, isNull);
      });
    });

    group('update', () {
      test('updates project name', () async {
        final created = await createTestProject(name: 'Old Name');
        final updated =
        await repo.update(created.copyWith(name: 'New Name'));

        expect(updated.name, equals('New Name'));
        expect(updated.id, equals(created.id));
      });

      test('updates project status', () async {
        final created =
        await createTestProject(status: ProjectStatus.active);
        final updated = await repo.update(
            created.copyWith(status: ProjectStatus.completed));

        expect(updated.status, equals(ProjectStatus.completed));
      });

      test('updates project description', () async {
        final created = await createTestProject();
        final updated = await repo
            .update(created.copyWith(description: 'Updated description'));

        expect(updated.description, equals('Updated description'));
      });

      test('persists update in getById', () async {
        final created = await createTestProject(name: 'Before');
        await repo.update(created.copyWith(name: 'After'));

        final found = await repo.getById(created.id);
        expect(found!.name, equals('After'));
      });
    });

    group('delete', () {
      test('deletes project', () async {
        final created = await createTestProject();
        await repo.delete(created.id);

        final found = await repo.getById(created.id);
        expect(found, isNull);
      });

      test('reduces total count by one', () async {
        await createTestProject(name: 'Keep Me');
        final toDelete = await createTestProject(name: 'Delete Me');

        final before = await repo.getAll();
        await repo.delete(toDelete.id);
        final after = await repo.getAll();

        expect(after.length, equals(before.length - 1));
      });

      test('does not affect other projects', () async {
        final keep = await createTestProject(name: 'Keep Me');
        final toDelete = await createTestProject(name: 'Delete Me');

        await repo.delete(toDelete.id);

        final found = await repo.getById(keep.id);
        expect(found, isNotNull);
        expect(found!.name, equals('Keep Me'));
      });
    });
  });
}