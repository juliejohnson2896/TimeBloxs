import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/models/task_template.dart';

void main() {
  group('TaskTemplate', () {
    final sampleRecord = {
      'id': 'task_001',
      'name': 'Fix login bug',
      'category': 'cat_001',
      'project': 'proj_001',
      'parent_task': null,
      'notes': 'Check the auth middleware',
      'is_system': false,
      'is_reusable': false,
      'is_archived': false,
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    final systemRecord = {
      'id': 'sys_task_break',
      'name': 'Break Time',
      'category': 'sys_cat_mindful',
      'project': null,
      'parent_task': null,
      'notes': null,
      'is_system': true,
      'is_reusable': true,
      'is_archived': false,
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    final subTaskRecord = {
      'id': 'task_002',
      'name': 'Write unit tests',
      'category': 'cat_001',
      'project': 'proj_001',
      'parent_task': 'task_001',
      'notes': null,
      'is_system': false,
      'is_reusable': false,
      'is_archived': false,
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    group('fromRecord', () {
      test('correctly parses all fields', () {
        final task = TaskTemplate.fromRecord(sampleRecord);

        expect(task.id, equals('task_001'));
        expect(task.name, equals('Fix login bug'));
        expect(task.categoryId, equals('cat_001'));
        expect(task.projectId, equals('proj_001'));
        expect(task.notes, equals('Check the auth middleware'));
        expect(task.isSystem, isFalse);
        expect(task.isReusable, isFalse);
        expect(task.isArchived, isFalse);
      });

      test('parses system task correctly', () {
        final task = TaskTemplate.fromRecord(systemRecord);

        expect(task.isSystem, isTrue);
        expect(task.isReusable, isTrue);
        expect(task.projectId, isNull);
      });

      test('parses sub-task correctly', () {
        final task = TaskTemplate.fromRecord(subTaskRecord);

        expect(task.parentTaskId, equals('task_001'));
        expect(task.isSubTask, isTrue);
      });

      test('handles expanded category relation', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['expand'] = {
            'category': {'name': 'Focus', 'color': '#2196F3'},
          };
        final task = TaskTemplate.fromRecord(record);

        expect(task.categoryName, equals('Focus'));
        expect(task.categoryColor, equals('#2196F3'));
      });

      test('handles expanded project relation', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['expand'] = {
            'project': {'name': 'TitanServer'},
          };
        final task = TaskTemplate.fromRecord(record);

        expect(task.projectName, equals('TitanServer'));
      });
    });

    group('computed properties', () {
      test('hasProject returns true when projectId is set', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        expect(task.hasProject, isTrue);
      });

      test('hasProject returns false when projectId is null', () {
        final task = TaskTemplate.fromRecord(systemRecord);
        expect(task.hasProject, isFalse);
      });

      test('isSubTask returns true when parentTaskId is set', () {
        final task = TaskTemplate.fromRecord(subTaskRecord);
        expect(task.isSubTask, isTrue);
      });

      test('isSubTask returns false when parentTaskId is null', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        expect(task.isSubTask, isFalse);
      });
    });

    group('toJson', () {
      test('serialises required fields', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        final json = task.toJson();

        expect(json['name'], equals('Fix login bug'));
        expect(json['category'], equals('cat_001'));
        expect(json['is_system'], isFalse);
        expect(json['is_reusable'], isFalse);
        expect(json['is_archived'], isFalse);
      });

      test('includes project when set', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        final json = task.toJson();
        expect(json['project'], equals('proj_001'));
      });

      test('omits project when null', () {
        final task = TaskTemplate.fromRecord(systemRecord);
        final json = task.toJson();
        expect(json.containsKey('project'), isFalse);
      });

      test('includes notes when set', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        final json = task.toJson();
        expect(json['notes'], equals('Check the auth middleware'));
      });

      test('omits notes when null', () {
        final task = TaskTemplate.fromRecord(systemRecord);
        final json = task.toJson();
        expect(json.containsKey('notes'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with updated name', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        final updated = task.copyWith(name: 'Fix logout bug');

        expect(updated.name, equals('Fix logout bug'));
        expect(updated.id, equals(task.id));
      });

      test('copies with archived set to true', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        final updated = task.copyWith(isArchived: true);

        expect(updated.isArchived, isTrue);
        expect(updated.name, equals(task.name));
      });

      test('preserves all unchanged fields', () {
        final task = TaskTemplate.fromRecord(sampleRecord);
        final updated = task.copyWith(name: 'New Name');

        expect(updated.id, equals(task.id));
        expect(updated.categoryId, equals(task.categoryId));
        expect(updated.projectId, equals(task.projectId));
        expect(updated.isSystem, equals(task.isSystem));
        expect(updated.isReusable, equals(task.isReusable));
        expect(updated.created, equals(task.created));
      });
    });
  });
}