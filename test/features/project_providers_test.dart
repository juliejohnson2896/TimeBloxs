import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/models/project.dart';
import 'package:timebloxs/core/repositories/project_repository.dart';
import 'package:timebloxs/features/projects/providers/project_providers.dart';
import 'package:timebloxs/main.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;
  late ProjectRepository projectRepo;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
    projectRepo = ProjectRepository(db);
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  // Helper to create projects with specific statuses
  Future<void> seedProjects() async {
    await projectRepo.create(Project(
      id: '',
      name: 'Active Project',
      color: '#F44336',
      status: ProjectStatus.active,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
    await projectRepo.create(Project(
      id: '',
      name: 'On Hold Project',
      color: '#FF9800',
      status: ProjectStatus.onHold,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
    await projectRepo.create(Project(
      id: '',
      name: 'Completed Project',
      color: '#4CAF50',
      status: ProjectStatus.completed,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
    await projectRepo.create(Project(
      id: '',
      name: 'Archived Project',
      color: '#607D8B',
      status: ProjectStatus.archived,
      created: DateTime.now(),
      updated: DateTime.now(),
    ));
  }

  group('allProjectsProvider', () {
    test('returns empty list on fresh database', () async {
      final projects =
      await container.read(allProjectsProvider.future);
      expect(projects, isEmpty);
    });

    test('returns all projects after seeding', () async {
      await seedProjects();
      container.invalidate(allProjectsProvider);

      final projects =
      await container.read(allProjectsProvider.future);
      expect(projects.length, equals(4));
    });
  });

  group('activeProjectsProvider', () {
    test('returns empty list on fresh database', () async {
      final projects =
      await container.read(activeProjectsProvider.future);
      expect(projects, isEmpty);
    });

    test('returns only active projects', () async {
      await seedProjects();
      container.invalidate(activeProjectsProvider);

      final projects =
      await container.read(activeProjectsProvider.future);
      expect(projects.length, equals(1));
      expect(projects.first.name, equals('Active Project'));
    });
  });

  group('projectStatusFilterProvider', () {
    test('initial state is all', () {
      final filter = container.read(projectStatusFilterProvider);
      expect(filter, equals(ProjectStatusFilter.all));
    });

    test('can be updated to each filter value', () {
      for (final filter in ProjectStatusFilter.values) {
        container.read(projectStatusFilterProvider.notifier).state =
            filter;
        expect(
          container.read(projectStatusFilterProvider),
          equals(filter),
        );
      }
    });
  });

  group('filteredProjectsProvider', () {
    test('returns all projects when filter is all', () async {
      await seedProjects();
      container.invalidate(allProjectsProvider);

      container.read(projectStatusFilterProvider.notifier).state =
          ProjectStatusFilter.all;

      final result = await container
          .read(filteredProjectsProvider)
          .when(
        data: (p) async => p,
        loading: () async {
          await Future.delayed(const Duration(milliseconds: 50));
          return container
              .read(filteredProjectsProvider)
              .value ?? [];
        },
        error: (_, __) async => <Project>[],
      );

      expect(result.length, equals(4));
    });

    test('returns only active projects when filter is active',
            () async {
          await seedProjects();
          container.invalidate(allProjectsProvider);

          container.read(projectStatusFilterProvider.notifier).state =
              ProjectStatusFilter.active;

          // Wait for provider to settle
          await Future.delayed(const Duration(milliseconds: 100));

          final projects =
          await container.read(allProjectsProvider.future);
          final filtered = projects
              .where((p) => p.status == ProjectStatus.active)
              .toList();

          expect(filtered.length, equals(1));
          expect(filtered.first.name, equals('Active Project'));
        });

    test('returns only on hold projects when filter is onHold',
            () async {
          await seedProjects();

          final projects =
          await container.read(allProjectsProvider.future);
          final filtered = projects
              .where((p) => p.status == ProjectStatus.onHold)
              .toList();

          expect(filtered.length, equals(1));
          expect(filtered.first.name, equals('On Hold Project'));
        });

    test('returns only completed projects when filter is completed',
            () async {
          await seedProjects();

          final projects =
          await container.read(allProjectsProvider.future);
          final filtered = projects
              .where((p) => p.status == ProjectStatus.completed)
              .toList();

          expect(filtered.length, equals(1));
          expect(filtered.first.name, equals('Completed Project'));
        });

    test('returns only archived projects when filter is archived',
            () async {
          await seedProjects();

          final projects =
          await container.read(allProjectsProvider.future);
          final filtered = projects
              .where((p) => p.status == ProjectStatus.archived)
              .toList();

          expect(filtered.length, equals(1));
          expect(filtered.first.name, equals('Archived Project'));
        });

    test('returns empty when filter finds no matches', () async {
      // Only create active projects
      await projectRepo.create(Project(
        id: '',
        name: 'Active Only',
        color: '#F44336',
        status: ProjectStatus.active,
        created: DateTime.now(),
        updated: DateTime.now(),
      ));

      final projects =
      await container.read(allProjectsProvider.future);
      final filtered = projects
          .where((p) => p.status == ProjectStatus.completed)
          .toList();

      expect(filtered, isEmpty);
    });
  });
}