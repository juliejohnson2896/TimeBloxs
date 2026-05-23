import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scheduled_block.dart';
import '../../../core/repositories/repository_providers.dart';

// Currently viewed date
final selectedDateProvider = StateProvider<DateTime>((ref) {
  final now = DateTime.now();
  return DateTime(now.year, now.month, now.day);
});

// Blocks for the selected date — uses a stream so updates are reactive
final scheduledBlocksForDateProvider =
StreamProvider<List<ScheduledBlock>>((ref) {
  final date = ref.watch(selectedDateProvider);
  final repo = ref.watch(scheduledBlockRepositoryProvider);
  return repo.watchForDate(date);
});