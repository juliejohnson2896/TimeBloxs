import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/models/task_category.dart';

void main() {
  group('TaskCategory', () {
    // Sample raw record as it comes from the database
    final sampleRecord = {
      'id': 'test_id_001',
      'name': 'Focus',
      'color': '#2196F3',
      'icon': 'center_focus_strong',
      'is_system': false,
      'is_default': true,
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    group('fromRecord', () {
      test('correctly parses all fields', () {
        final category = TaskCategory.fromRecord(sampleRecord);

        expect(category.id, equals('test_id_001'));
        expect(category.name, equals('Focus'));
        expect(category.color, equals('#2196F3'));
        expect(category.icon, equals('center_focus_strong'));
        expect(category.isSystem, isFalse);
        expect(category.isDefault, isTrue);
      });

      test('handles null icon gracefully', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['icon'] = null;
        final category = TaskCategory.fromRecord(record);
        expect(category.icon, isNull);
      });

      test('defaults isSystem to false when missing', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..remove('is_system');
        final category = TaskCategory.fromRecord(record);
        expect(category.isSystem, isFalse);
      });

      test('defaults isDefault to false when missing', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..remove('is_default');
        final category = TaskCategory.fromRecord(record);
        expect(category.isDefault, isFalse);
      });

      test('parses created and updated timestamps', () {
        final category = TaskCategory.fromRecord(sampleRecord);
        expect(category.created, isA<DateTime>());
        expect(category.updated, isA<DateTime>());
      });
    });

    group('toJson', () {
      test('serialises all fields correctly', () {
        final category = TaskCategory.fromRecord(sampleRecord);
        final json = category.toJson();

        expect(json['name'], equals('Focus'));
        expect(json['color'], equals('#2196F3'));
        expect(json['icon'], equals('center_focus_strong'));
        expect(json['is_system'], isFalse);
        expect(json['is_default'], isTrue);
      });

      test('does not include id in toJson', () {
        final category = TaskCategory.fromRecord(sampleRecord);
        final json = category.toJson();
        expect(json.containsKey('id'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with updated name', () {
        final category = TaskCategory.fromRecord(sampleRecord);
        final updated = category.copyWith(name: 'Deep Focus');

        expect(updated.name, equals('Deep Focus'));
        expect(updated.id, equals(category.id));
        expect(updated.color, equals(category.color));
      });

      test('copies with updated color', () {
        final category = TaskCategory.fromRecord(sampleRecord);
        final updated = category.copyWith(color: '#FF0000');

        expect(updated.color, equals('#FF0000'));
        expect(updated.name, equals(category.name));
      });

      test('preserves all unchanged fields', () {
        final category = TaskCategory.fromRecord(sampleRecord);
        final updated = category.copyWith(name: 'New Name');

        expect(updated.id, equals(category.id));
        expect(updated.color, equals(category.color));
        expect(updated.icon, equals(category.icon));
        expect(updated.isSystem, equals(category.isSystem));
        expect(updated.isDefault, equals(category.isDefault));
        expect(updated.created, equals(category.created));
        expect(updated.updated, equals(category.updated));
      });
    });
  });
}