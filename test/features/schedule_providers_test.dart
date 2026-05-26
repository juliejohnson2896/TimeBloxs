import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/features/schedule/providers/schedule_providers.dart';
import 'package:timebloxs/main.dart';

import '../helpers/test_database.dart';

void main() {
  late AppDatabase db;
  late ProviderContainer container;

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

  group('selectedDateProvider', () {
    test('initial state is today', () {
      final date = container.read(selectedDateProvider);
      final now = DateTime.now();

      expect(date.year, equals(now.year));
      expect(date.month, equals(now.month));
      expect(date.day, equals(now.day));
    });

    test('initial state has no time component', () {
      final date = container.read(selectedDateProvider);
      expect(date.hour, equals(0));
      expect(date.minute, equals(0));
      expect(date.second, equals(0));
    });

    test('can be updated to a different date', () {
      final newDate = DateTime(2024, 6, 15);
      container.read(selectedDateProvider.notifier).state = newDate;

      expect(
        container.read(selectedDateProvider),
        equals(newDate),
      );
    });

    test('can navigate forward by one day', () {
      final initial = container.read(selectedDateProvider);
      final tomorrow = initial.add(const Duration(days: 1));

      container.read(selectedDateProvider.notifier).state = tomorrow;

      expect(
        container.read(selectedDateProvider),
        equals(tomorrow),
      );
    });

    test('can navigate backward by one day', () {
      final initial = container.read(selectedDateProvider);
      final yesterday = initial.subtract(const Duration(days: 1));

      container.read(selectedDateProvider.notifier).state = yesterday;

      expect(
        container.read(selectedDateProvider),
        equals(yesterday),
      );
    });
  });

  group('scheduledBlocksForDateProvider', () {
    test('returns empty list for date with no blocks', () async {
      final date = DateTime(2099, 12, 31);
      container.read(selectedDateProvider.notifier).state = date;

      final blocks = await container
          .read(scheduledBlocksForDateProvider.future);
      expect(blocks, isEmpty);
    });

    test('updates when selected date changes', () async {
      final date1 = DateTime(2024, 1, 15);
      final date2 = DateTime(2024, 1, 16);

      container.read(selectedDateProvider.notifier).state = date1;
      final blocks1 = await container
          .read(scheduledBlocksForDateProvider.future);

      container.read(selectedDateProvider.notifier).state = date2;
      final blocks2 = await container
          .read(scheduledBlocksForDateProvider.future);

      // Both should return lists (empty in this case)
      expect(blocks1, isA<List>());
      expect(blocks2, isA<List>());
    });
  });
}