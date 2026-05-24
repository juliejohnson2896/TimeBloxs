import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/models/scheduled_block.dart';

void main() {
  group('BlockType', () {
    test('fromString parses static and dynamic', () {
      expect(BlockType.fromString('static'), equals(BlockType.static));
      expect(BlockType.fromString('dynamic'), equals(BlockType.dynamic));
    });

    test('fromString defaults to static for unknown values', () {
      expect(BlockType.fromString('unknown'), equals(BlockType.static));
    });

    test('toJson returns correct string', () {
      expect(BlockType.static.toJson(), equals('static'));
      expect(BlockType.dynamic.toJson(), equals('dynamic'));
    });

    test('toJson and fromString are inverse operations', () {
      expect(BlockType.fromString(BlockType.static.toJson()),
          equals(BlockType.static));
      expect(BlockType.fromString(BlockType.dynamic.toJson()),
          equals(BlockType.dynamic));
    });
  });

  group('BlockStatus', () {
    test('fromString parses all valid statuses', () {
      expect(BlockStatus.fromString('planned'), equals(BlockStatus.planned));
      expect(BlockStatus.fromString('active'), equals(BlockStatus.active));
      expect(
          BlockStatus.fromString('completed'), equals(BlockStatus.completed));
      expect(BlockStatus.fromString('skipped'), equals(BlockStatus.skipped));
    });

    test('fromString defaults to planned for unknown values', () {
      expect(BlockStatus.fromString('unknown'), equals(BlockStatus.planned));
    });

    test('toJson serialises correctly', () {
      expect(BlockStatus.planned.toJson(), equals('planned'));
      expect(BlockStatus.active.toJson(), equals('active'));
      expect(BlockStatus.completed.toJson(), equals('completed'));
      expect(BlockStatus.skipped.toJson(), equals('skipped'));
    });

    test('label returns human readable string', () {
      expect(BlockStatus.planned.label, equals('Planned'));
      expect(BlockStatus.active.label, equals('Active'));
      expect(BlockStatus.completed.label, equals('Completed'));
      expect(BlockStatus.skipped.label, equals('Skipped'));
    });
  });

  group('ScheduledBlock', () {
    final sampleRecord = {
      'id': 'block_001',
      'date': '2024-01-15T00:00:00.000Z',
      'start_time': '09:00',
      'duration_mins': 60,
      'label': 'Morning Focus',
      'block_type': 'static',
      'task_template': 'task_001',
      'category': 'cat_001',
      'status': 'planned',
      'notes': null,
      'user': 'user_001',
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    final dynamicRecord = {
      'id': 'block_002',
      'date': '2024-01-15T00:00:00.000Z',
      'start_time': '14:00',
      'duration_mins': 90,
      'label': 'Afternoon Block',
      'block_type': 'dynamic',
      'task_template': null,
      'category': 'cat_002',
      'status': 'planned',
      'notes': 'Some notes',
      'user': 'user_001',
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    group('fromRecord', () {
      test('correctly parses static block', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);

        expect(block.id, equals('block_001'));
        expect(block.startTime, equals('09:00'));
        expect(block.durationMins, equals(60));
        expect(block.label, equals('Morning Focus'));
        expect(block.blockType, equals(BlockType.static));
        expect(block.taskTemplateId, equals('task_001'));
        expect(block.status, equals(BlockStatus.planned));
      });

      test('correctly parses dynamic block', () {
        final block = ScheduledBlock.fromRecord(dynamicRecord);

        expect(block.blockType, equals(BlockType.dynamic));
        expect(block.taskTemplateId, isNull);
        expect(block.notes, equals('Some notes'));
      });

      test('handles expanded task_template relation', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['expand'] = {
            'task_template': {'name': 'Fix login bug'},
          };
        final block = ScheduledBlock.fromRecord(record);
        expect(block.taskTemplateName, equals('Fix login bug'));
      });

      test('handles expanded category relation', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['expand'] = {
            'category': {'name': 'Focus', 'color': '#2196F3'},
          };
        final block = ScheduledBlock.fromRecord(record);
        expect(block.categoryName, equals('Focus'));
        expect(block.categoryColor, equals('#2196F3'));
      });

      test('handles expanded task category colour', () async {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['expand'] = {
            'task_template': {'name': 'Fix login bug'},
            'category': {'name': 'Focus', 'color': '#2196F3'},
          };
        final block = ScheduledBlock.fromRecord(record);
        expect(block.taskCategoryColor, isNull); // fromRecord doesn't set this
      });

      test('taskCategoryColor defaults to null', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        expect(block.taskCategoryColor, isNull);
      });
    });

    group('computed properties', () {
      test('endTime calculates correctly for 60 min block', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        expect(block.endTime, equals('10:00'));
      });

      test('endTime calculates correctly for 90 min block', () {
        final block = ScheduledBlock.fromRecord(dynamicRecord);
        expect(block.endTime, equals('15:30'));
      });

      test('endTime handles midnight rollover', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['start_time'] = '23:00'
          ..['duration_mins'] = 90;
        final block = ScheduledBlock.fromRecord(record);
        expect(block.endTime, equals('00:30'));
      });

      test('isDynamic returns true for dynamic blocks', () {
        final block = ScheduledBlock.fromRecord(dynamicRecord);
        expect(block.isDynamic, isTrue);
      });

      test('isDynamic returns false for static blocks', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        expect(block.isDynamic, isFalse);
      });

      test('isAssigned returns true when task is set', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        expect(block.isAssigned, isTrue);
      });

      test('isAssigned returns false when task is null', () {
        final block = ScheduledBlock.fromRecord(dynamicRecord);
        expect(block.isAssigned, isFalse);
      });
    });

    group('toJson', () {
      test('serialises date as date only string', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final json = block.toJson();
        expect(json['date'], equals('2024-01-15'));
      });

      test('serialises all required fields', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final json = block.toJson();

        expect(json['start_time'], equals('09:00'));
        expect(json['duration_mins'], equals(60));
        expect(json['label'], equals('Morning Focus'));
        expect(json['block_type'], equals('static'));
        expect(json['category'], equals('cat_001'));
        expect(json['status'], equals('planned'));
      });

      test('includes task_template when set', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final json = block.toJson();
        expect(json['task_template'], equals('task_001'));
      });

      test('omits task_template when null', () {
        final block = ScheduledBlock.fromRecord(dynamicRecord);
        final json = block.toJson();
        expect(json.containsKey('task_template'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with updated status', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final updated = block.copyWith(status: BlockStatus.completed);

        expect(updated.status, equals(BlockStatus.completed));
        expect(updated.id, equals(block.id));
      });

      test('copies with updated label', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final updated = block.copyWith(label: 'Deep Work Session');

        expect(updated.label, equals('Deep Work Session'));
        expect(updated.startTime, equals(block.startTime));
      });

      test('copies with cleared task template', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final updated = block.copyWith(taskTemplateId: null);

        expect(updated.taskTemplateId, isNull);
        expect(updated.label, equals(block.label));
      });

      test('preserves all unchanged fields', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final updated = block.copyWith(label: 'New Label');

        expect(updated.id, equals(block.id));
        expect(updated.date, equals(block.date));
        expect(updated.startTime, equals(block.startTime));
        expect(updated.durationMins, equals(block.durationMins));
        expect(updated.blockType, equals(block.blockType));
        expect(updated.categoryId, equals(block.categoryId));
        expect(updated.status, equals(block.status));
      });

      test('copies with updated taskCategoryColor', () {
        final block = ScheduledBlock.fromRecord(sampleRecord);
        final updated = block.copyWith(taskCategoryColor: '#9C27B0');
        expect(updated.taskCategoryColor, equals('#9C27B0'));
        expect(updated.label, equals(block.label));
      });

      test('can clear taskCategoryColor via copyWith', () {
        final block = ScheduledBlock.fromRecord(sampleRecord)
            .copyWith(taskCategoryColor: '#9C27B0');
        final cleared = block.copyWith(taskCategoryColor: null);
        expect(cleared.taskCategoryColor, isNull);
      });
    });
  });
}