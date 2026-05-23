import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/scheduled_block.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/schedule_providers.dart';
import 'time_block_card.dart';
import '../../settings/providers/settings_providers.dart';

class TimeGrid extends ConsumerStatefulWidget {
  const TimeGrid({super.key});

  @override
  ConsumerState<TimeGrid> createState() => _TimeGridState();
}

class _TimeGridState extends ConsumerState<TimeGrid> {
  static const double pixelsPerHour = 80.0;
  static const double hourLabelWidth = 52.0;
  static const int dayStartHour = 0;    // midnight
  static const int dayEndHour = 24;     // midnight
  static const int totalHours = dayEndHour - dayStartHour;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToCurrentTime());
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  void _scrollToCurrentTime() {
    final now = DateTime.now();
    final minutes = now.hour * 60 + now.minute;
    final offset = minutes / 60 * pixelsPerHour - 100;
    _scrollController.animateTo(
      offset.clamp(0, double.infinity),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final blocksAsync = ref.watch(scheduledBlocksForDateProvider);
    final selectedDate = ref.watch(selectedDateProvider);
    final dayStart = ref.watch(dayStartTimeProvider);
    final dayEnd = ref.watch(dayEndTimeProvider);
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return blocksAsync.when(
      data: (blocks) => _buildGrid(blocks, isToday, now, dayStart, dayEnd),
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (e, _) => Center(child: Text('Error loading schedule: $e')),
    );
  }

  Widget _buildGrid(List<ScheduledBlock> blocks, bool isToday, DateTime now,
      String dayStart, String dayEnd) {
    const totalHeight = totalHours * pixelsPerHour;
    const topPadding = 16.0;
    const bottomPadding = 0.0;

    // These are ONLY for the marker positions, not the grid itself
    final dayStartMarkerHour = int.parse(dayStart.split(':')[0]);
    final dayEndMarkerHour = int.parse(dayEnd.split(':')[0]);

    return SingleChildScrollView(
      controller: _scrollController,
      padding: const EdgeInsets.only(bottom: 80),  // was 100
      child: SizedBox(
        height: totalHeight + topPadding + bottomPadding,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            // ── Left column: hour labels only ──
            SizedBox(
              width: hourLabelWidth,
              child: Stack(
                clipBehavior: Clip.none,
                children: List.generate(totalHours + 1, (i) {
                  final hour = (dayStartHour + i) % 24;
                  final top = i * pixelsPerHour + topPadding;
                  return Positioned(
                    top: top - 8,
                    left: 0,
                    right: 4,
                    child: Text(
                      _formatHour(hour),
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                        color: AppTheme.textDisabled,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                }),
              ),
            ),

            // ── Right column: grid lines, markers, blocks ──
            Expanded(
              child: Stack(
                clipBehavior: Clip.none,
                children: [

                  // Full hour grid lines
                  ...List.generate(totalHours + 1, (i) {
                    final top = i * pixelsPerHour + topPadding;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: AppTheme.surfaceVariant.withOpacity(0.4),
                      ),
                    );
                  }),

                  // Half hour grid lines
                  ...List.generate(totalHours, (i) {
                    final top = i * pixelsPerHour + pixelsPerHour / 2 + topPadding;
                    return Positioned(
                      top: top,
                      left: 0,
                      right: 0,
                      child: Container(
                        height: 1,
                        color: AppTheme.surfaceVariant.withOpacity(0.2),
                      ),
                    );
                  }),

                  // Day start marker (9am)
                  _buildDayMarker(dayStartMarkerHour, topPadding, 'Day Start'),

                  // Day end marker (5pm)
                  _buildDayMarker(dayEndMarkerHour, topPadding, 'Day End'),

                  // Current time indicator
                  if (isToday) _buildCurrentTimeIndicator(now, topPadding),

                  // Blocks
                  ...blocks.map((block) => _buildBlock(block, topPadding)),
                ],
              ),
            ),

            const SizedBox(width: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildDayMarker(int hour, double topPadding, String label) {
    final top = (hour - dayStartHour) * pixelsPerHour + topPadding;
    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                width: 1,
              ),
            ),
            child: Text(
              label,
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontSize: 9,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          Expanded(
            child: Container(
              height: 1,
              color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCurrentTimeIndicator(DateTime now, double topPadding) {
    final minutes = now.hour * 60 + now.minute;
    final top = minutes / 60 * pixelsPerHour + topPadding;

    return Positioned(
      top: top,
      left: 0,
      right: 0,
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Container(
              height: 2,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBlock(ScheduledBlock block, double topPadding) {
    final parts = block.startTime.split(':');
    final startMinutes = int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final top = startMinutes / 60 * pixelsPerHour + topPadding;
    final height = (block.durationMins / 60 * pixelsPerHour)
        .clamp(32.0, double.infinity);

    return Positioned(
      top: top,
      left: 4,
      right: 4,
      height: height,
      child: TimeBlockCard(block: block),
    );
  }

  String _formatHour(int hour) {
    if (hour == 0 || hour == 24) return '12am';
    if (hour == 12) return '12pm';
    if (hour < 12) return '${hour}am';
    return '${hour - 12}pm';
  }
}