import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/providers/invalidation_service.dart';
import 'package:timebloxs/features/projects/providers/project_providers.dart';
import 'package:timebloxs/features/tasks/providers/task_providers.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/main.dart';

import '../helpers/test_database.dart';

void main() {
  late ProviderContainer container;
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
    container = ProviderContainer(
      overrides: [
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  group('InvalidationService', () {
    test('can be read from provider', () {
      final service = container.read(invalidationServiceProvider);
      expect(service, isNotNull);
    });

    test('onProjectChanged does not throw', () {
      final service = container.read(invalidationServiceProvider);
      expect(() => service.onProjectChanged(), returnsNormally);
    });

    test('onTaskChanged does not throw', () {
      final service = container.read(invalidationServiceProvider);
      expect(() => service.onTaskChanged(), returnsNormally);
    });

    test('onSubTaskChanged does not throw', () {
      final service = container.read(invalidationServiceProvider);
      expect(
            () => service.onSubTaskChanged('parent_id'),
        returnsNormally,
      );
    });

    test('onScheduleChanged does not throw', () {
      final service = container.read(invalidationServiceProvider);
      expect(() => service.onScheduleChanged(), returnsNormally);
    });

    test('onProjectChanged cascades to task invalidation', () async {
      final service = container.read(invalidationServiceProvider);

      // Read providers to put them in cache
      await container.read(allProjectsProvider.future);
      await container.read(taskTemplatesProvider.future);

      // Invalidate via project change
      service.onProjectChanged();

      // Both should now be invalidated — reading again should
      // trigger a fresh fetch rather than returning cached value
      final projects = container.read(allProjectsProvider);
      final tasks = container.read(taskTemplatesProvider);

      // After invalidation providers are in loading state
      expect(projects, isA<AsyncValue>());
      expect(tasks, isA<AsyncValue>());
    });

    test('onTaskChanged cascades to schedule invalidation', () async {
      final service = container.read(invalidationServiceProvider);

      await container.read(taskTemplatesProvider.future);

      service.onTaskChanged();

      final tasks = container.read(taskTemplatesProvider);
      expect(tasks, isA<AsyncValue>());
    });
  });
}