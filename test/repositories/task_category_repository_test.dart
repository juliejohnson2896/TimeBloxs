import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/models/task_category.dart';
import 'package:timebloxs/core/repositories/task_category_repository.dart';
import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late TaskCategoryRepository repo;

  setUp(() async {
    db = createTestDatabase();
    repo = TaskCategoryRepository(db);
  });

  tearDown(() async {
    await db.close();
  });

  group('TaskCategoryRepository', () {
    group('getAll', () {
      test('returns seeded system categories on fresh database', () async {
        final categories = await repo.getAll();
        expect(categories, isNotEmpty);
        expect(
          categories.any((c) => c.name == 'Mindful Breaks'),
          isTrue,
        );
      });

      test('returns all default categories', () async {
        final categories = await repo.getAll();
        final names = categories.map((c) => c.name).toList();

        expect(names, containsAll([
          'Mindful Breaks',
          'Focus',
          'Self Care',
          'Chores',
          'Project Work',
          'Admin',
        ]));
      });

      test('returns system category with isSystem true', () async {
        final categories = await repo.getAll();
        final mindful =
        categories.firstWhere((c) => c.name == 'Mindful Breaks');
        expect(mindful.isSystem, isTrue);
      });
    });

    group('create', () {
      test('creates a new category and returns it', () async {
        final newCategory = TaskCategory(
          id: '',
          name: 'Test Category',
          color: '#FF0000',
          icon: 'star',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        );

        final created = await repo.create(newCategory);

        expect(created.id, isNotEmpty);
        expect(created.name, equals('Test Category'));
        expect(created.color, equals('#FF0000'));
        expect(created.icon, equals('star'));
        expect(created.isSystem, isFalse);
      });

      test('created category appears in getAll', () async {
        final before = await repo.getAll();

        await repo.create(TaskCategory(
          id: '',
          name: 'New Category',
          color: '#00FF00',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final after = await repo.getAll();
        expect(after.length, equals(before.length + 1));
        expect(after.any((c) => c.name == 'New Category'), isTrue);
      });

      test('generates unique id for each created category', () async {
        final cat1 = await repo.create(TaskCategory(
          id: '',
          name: 'Category 1',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final cat2 = await repo.create(TaskCategory(
          id: '',
          name: 'Category 2',
          color: '#00FF00',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        expect(cat1.id, isNot(equals(cat2.id)));
      });
    });

    group('getById', () {
      test('returns category by id', () async {
        final created = await repo.create(TaskCategory(
          id: '',
          name: 'Find Me',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final found = await repo.getById(created.id);
        expect(found, isNotNull);
        expect(found!.name, equals('Find Me'));
      });

      test('returns null for non-existent id', () async {
        final found = await repo.getById('non_existent_id');
        expect(found, isNull);
      });
    });

    group('update', () {
      test('updates category name', () async {
        final created = await repo.create(TaskCategory(
          id: '',
          name: 'Original Name',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final updated =
        await repo.update(created.copyWith(name: 'Updated Name'));

        expect(updated.name, equals('Updated Name'));
        expect(updated.id, equals(created.id));
      });

      test('updates category color', () async {
        final created = await repo.create(TaskCategory(
          id: '',
          name: 'Color Test',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final updated =
        await repo.update(created.copyWith(color: '#00FF00'));

        expect(updated.color, equals('#00FF00'));
      });

      test('updated category persists in getAll', () async {
        final created = await repo.create(TaskCategory(
          id: '',
          name: 'Before Update',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        await repo.update(created.copyWith(name: 'After Update'));

        final all = await repo.getAll();
        expect(all.any((c) => c.name == 'After Update'), isTrue);
        expect(all.any((c) => c.name == 'Before Update'), isFalse);
      });
    });

    group('delete', () {
      test('deletes a category', () async {
        final created = await repo.create(TaskCategory(
          id: '',
          name: 'Delete Me',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        await repo.delete(created.id);

        final found = await repo.getById(created.id);
        expect(found, isNull);
      });

      test('deleted category does not appear in getAll', () async {
        final created = await repo.create(TaskCategory(
          id: '',
          name: 'Delete Me Too',
          color: '#FF0000',
          isSystem: false,
          isDefault: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        ));

        final before = await repo.getAll();
        await repo.delete(created.id);
        final after = await repo.getAll();

        expect(after.length, equals(before.length - 1));
        expect(after.any((c) => c.id == created.id), isFalse);
      });
    });
  });
}