import 'package:drift/drift.dart';

class ScheduledBlocksTable extends Table {
  TextColumn get id => text()();
  DateTimeColumn get date => dateTime()();
  TextColumn get startTime => text()();
  IntColumn get durationMins => integer()();
  TextColumn get label => text()();
  TextColumn get blockType => text()();
  TextColumn get taskTemplateId => text().nullable()();
  TextColumn get categoryId => text()();
  TextColumn get status => text().withDefault(const Constant('planned'))();
  TextColumn get notes => text().nullable()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  // Sync state
  TextColumn get syncId => text().nullable()();
  BoolColumn get isDirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column> get primaryKey => {id};
}