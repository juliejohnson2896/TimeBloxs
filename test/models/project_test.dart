import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/models/project.dart';

void main() {
  group('ProjectStatus', () {
    test('fromString parses all valid statuses', () {
      expect(ProjectStatus.fromString('active'), equals(ProjectStatus.active));
      expect(ProjectStatus.fromString('on_hold'), equals(ProjectStatus.onHold));
      expect(
          ProjectStatus.fromString('completed'), equals(ProjectStatus.completed));
      expect(
          ProjectStatus.fromString('archived'), equals(ProjectStatus.archived));
    });

    test('fromString defaults to active for unknown values', () {
      expect(ProjectStatus.fromString('unknown'), equals(ProjectStatus.active));
      expect(ProjectStatus.fromString(''), equals(ProjectStatus.active));
    });

    test('toJson serialises correctly', () {
      expect(ProjectStatus.active.toJson(), equals('active'));
      expect(ProjectStatus.onHold.toJson(), equals('on_hold'));
      expect(ProjectStatus.completed.toJson(), equals('completed'));
      expect(ProjectStatus.archived.toJson(), equals('archived'));
    });

    test('label returns human readable string', () {
      expect(ProjectStatus.active.label, equals('Active'));
      expect(ProjectStatus.onHold.label, equals('On Hold'));
      expect(ProjectStatus.completed.label, equals('Completed'));
      expect(ProjectStatus.archived.label, equals('Archived'));
    });

    test('toJson and fromString are inverse operations', () {
      for (final status in ProjectStatus.values) {
        expect(ProjectStatus.fromString(status.toJson()), equals(status));
      }
    });
  });

  group('Project', () {
    final sampleRecord = {
      'id': 'proj_001',
      'name': 'TitanServer',
      'description': 'Home server infrastructure',
      'color': '#F44336',
      'icon': 'server',
      'status': 'active',
      'created': '2024-01-01T09:00:00.000Z',
      'updated': '2024-01-01T09:00:00.000Z',
    };

    group('fromRecord', () {
      test('correctly parses all fields', () {
        final project = Project.fromRecord(sampleRecord);

        expect(project.id, equals('proj_001'));
        expect(project.name, equals('TitanServer'));
        expect(project.description, equals('Home server infrastructure'));
        expect(project.color, equals('#F44336'));
        expect(project.status, equals(ProjectStatus.active));
      });

      test('handles null description', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['description'] = null;
        final project = Project.fromRecord(record);
        expect(project.description, isNull);
      });

      test('handles null color', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['color'] = null;
        final project = Project.fromRecord(record);
        expect(project.color, isNull);
      });

      test('defaults to active status when missing', () {
        final record = Map<String, dynamic>.from(sampleRecord)
          ..['status'] = null;
        final project = Project.fromRecord(record);
        expect(project.status, equals(ProjectStatus.active));
      });
    });

    group('toJson', () {
      test('serialises all fields', () {
        final project = Project.fromRecord(sampleRecord);
        final json = project.toJson();

        expect(json['name'], equals('TitanServer'));
        expect(json['description'], equals('Home server infrastructure'));
        expect(json['color'], equals('#F44336'));
        expect(json['status'], equals('active'));
      });

      test('does not include id in toJson', () {
        final project = Project.fromRecord(sampleRecord);
        final json = project.toJson();
        expect(json.containsKey('id'), isFalse);
      });
    });

    group('copyWith', () {
      test('copies with updated name', () {
        final project = Project.fromRecord(sampleRecord);
        final updated = project.copyWith(name: 'MidgardServer');

        expect(updated.name, equals('MidgardServer'));
        expect(updated.id, equals(project.id));
      });

      test('copies with updated status', () {
        final project = Project.fromRecord(sampleRecord);
        final updated = project.copyWith(status: ProjectStatus.completed);

        expect(updated.status, equals(ProjectStatus.completed));
        expect(updated.name, equals(project.name));
      });

      test('preserves all unchanged fields', () {
        final project = Project.fromRecord(sampleRecord);
        final updated = project.copyWith(name: 'New Name');

        expect(updated.id, equals(project.id));
        expect(updated.description, equals(project.description));
        expect(updated.color, equals(project.color));
        expect(updated.status, equals(project.status));
        expect(updated.created, equals(project.created));
        expect(updated.updated, equals(project.updated));
      });
    });
  });
}