import 'package:drift/drift.dart';
import '../app_database.dart';
import '../tables/scheduled_blocks_table.dart';

part 'scheduled_blocks_dao.g.dart';

@DriftAccessor(tables: [ScheduledBlocksTable])
class ScheduledBlocksDao extends DatabaseAccessor<AppDatabase>
    with _$ScheduledBlocksDaoMixin {
  ScheduledBlocksDao(super.db);

  Future<List<ScheduledBlocksTableData>> getForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(scheduledBlocksTable)
      ..where((t) =>
      t.date.isBiggerOrEqualValue(startOfDay) &
      t.date.isSmallerThanValue(endOfDay))
      ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .get();
  }

  Future<List<ScheduledBlocksTableData>> getForDateRange(
      DateTime start,
      DateTime end,
      ) =>
      (select(scheduledBlocksTable)
        ..where((t) =>
        t.date.isBiggerOrEqualValue(start) &
        t.date.isSmallerOrEqualValue(end))
        ..orderBy([
              (t) => OrderingTerm.asc(t.date),
              (t) => OrderingTerm.asc(t.startTime),
        ]))
          .get();

  Future<ScheduledBlocksTableData?> getById(String id) =>
      (select(scheduledBlocksTable)..where((t) => t.id.equals(id)))
          .getSingleOrNull();

  Future<int> insertBlock(ScheduledBlocksTableCompanion entry) =>
      into(scheduledBlocksTable).insert(entry);

  Future<bool> updateBlock(ScheduledBlocksTableCompanion entry) =>
      update(scheduledBlocksTable).replace(entry);

  Future<int> deleteBlock(String id) =>
      (delete(scheduledBlocksTable)..where((t) => t.id.equals(id))).go();

  Future<List<ScheduledBlocksTableData>> getDirty() =>
      (select(scheduledBlocksTable)
        ..where((t) => t.isDirty.equals(true)))
          .get();

  Stream<List<ScheduledBlocksTableData>> watchForDate(DateTime date) {
    final startOfDay = DateTime(date.year, date.month, date.day);
    final endOfDay = startOfDay.add(const Duration(days: 1));
    return (select(scheduledBlocksTable)
      ..where((t) =>
      t.date.isBiggerOrEqualValue(startOfDay) &
      t.date.isSmallerThanValue(endOfDay))
      ..orderBy([(t) => OrderingTerm.asc(t.startTime)]))
        .watch();
  }

  Future<List<ScheduledBlocksTableData>> getByTaskTemplateId(
      String taskTemplateId) =>
      (select(scheduledBlocksTable)
        ..where((t) => t.taskTemplateId.equals(taskTemplateId)))
          .get();
}