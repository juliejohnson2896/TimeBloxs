import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/schedule_providers.dart';

class ScheduleHeader extends ConsumerWidget {
  final DateTime selectedDate;

  const ScheduleHeader({super.key, required this.selectedDate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final now = DateTime.now();
    final isToday = selectedDate.year == now.year &&
        selectedDate.month == now.month &&
        selectedDate.day == now.day;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        color: AppTheme.surface,
        border: Border(
          bottom: BorderSide(color: AppTheme.surfaceVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          // Previous day
          IconButton(
            onPressed: () => _changeDate(ref, -1),
            icon: const Icon(Icons.chevron_left),
            color: AppTheme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
          const Gap(8),

          // Date display
          Expanded(
            child: GestureDetector(
              onTap: () => _showDatePicker(context, ref),
              child: Column(
                children: [
                  Text(
                    DateFormat('EEEE').format(selectedDate),
                    style: TextStyle(
                      color: isToday ? Theme.of(context).colorScheme.primary : AppTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const Gap(2),
                  Text(
                    DateFormat('MMMM d, yyyy').format(selectedDate),
                    style: TextStyle(
                      color: isToday ? Theme.of(context).colorScheme.primary : AppTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const Gap(8),

          // Next day
          IconButton(
            onPressed: () => _changeDate(ref, 1),
            icon: const Icon(Icons.chevron_right),
            color: AppTheme.textSecondary,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }

  void _changeDate(WidgetRef ref, int days) {
    final current = ref.read(selectedDateProvider);
    ref.read(selectedDateProvider.notifier).state =
        current.add(Duration(days: days));
  }

  Future<void> _showDatePicker(BuildContext context, WidgetRef ref) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: Theme.of(context).colorScheme.primary,
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) {
      ref.read(selectedDateProvider.notifier).state = picked;
    }
  }
}