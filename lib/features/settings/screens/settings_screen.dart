import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/widgets/desktop_constrained.dart';
import '../providers/settings_providers.dart';
import '../../../core/utils/snackbar_helper.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dayStart = ref.watch(dayStartTimeProvider);
    final dayEnd = ref.watch(dayEndTimeProvider);
    final accentColor = ref.watch(accentColorProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: DesktopConstrained(
        maxWidth: 600,  // settings looks better narrower
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [

            // ── Day Window ──────────────────────────────
            const _SectionHeader(label: 'Day Window'),
            const Gap(8),
            _SettingsCard(
              children: [
                _TimeTile(
                  label: 'Day starts at',
                  value: dayStart,
                  onTap: () => _pickTime(
                    context,
                    ref,
                    current: dayStart,
                    isStart: true,
                  ),
                ),
                const Divider(height: 1),
                _TimeTile(
                  label: 'Day ends at',
                  value: dayEnd,
                  onTap: () => _pickTime(
                    context,
                    ref,
                    current: dayEnd,
                    isStart: false,
                  ),
                ),
              ],
            ),
            const Gap(8),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                'These times are shown as markers on your schedule.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ),
            const Gap(24),

            // ── Accent Colour ───────────────────────────
            const _SectionHeader(label: 'Accent Colour'),
            const Gap(8),
            _SettingsCard(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Choose your accent colour',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      const Gap(16),
                      Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: accentColorOptions.map((color) {
                          final isSelected = accentColor.toARGB32() == color.toARGB32();
                          return GestureDetector(
                            onTap: () => ref
                                .read(accentColorProvider.notifier)
                                .setColor(color),
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 150),
                              width: 40,
                              height: 40,
                              decoration: BoxDecoration(
                                color: color,
                                shape: BoxShape.circle,
                                border: Border.all(
                                  color: isSelected
                                      ? Colors.white
                                      : Colors.transparent,
                                  width: 2.5,
                                ),
                                boxShadow: isSelected
                                    ? [
                                  BoxShadow(
                                    color: color.withValues(alpha: 0.6),
                                    blurRadius: 8,
                                    spreadRadius: 1,
                                  )
                                ]
                                    : null,
                              ),
                              child: isSelected
                                  ? const Icon(
                                Icons.check,
                                color: Colors.white,
                                size: 20,
                              )
                                  : null,
                            ),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Gap(24),

            // ── Sync ────────────────────────────────────
            const _SectionHeader(label: 'Sync'),
            const Gap(8),
            _SettingsCard(
              children: [
                ListTile(
                  leading: const Icon(
                    Icons.cloud_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Cloud Sync'),
                  subtitle: const Text('Coming in a future update'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Text(
                      'Soon',
                      style: TextStyle(
                        color: AppTheme.textSecondary,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const Gap(24),

            // ── About ────────────────────────────────────
            const _SectionHeader(label: 'About'),
            const Gap(8),
            const _SettingsCard(
              children: [
                ListTile(
                  leading: Icon(
                    Icons.view_timeline_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  title: Text('Timebloxs'),
                  trailing: Text(
                    'v1.0.0',
                    style: TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const Gap(100),
          ],
        ),
      ),
    );
  }

  Future<void> _pickTime(
      BuildContext context,
      WidgetRef ref, {
        required String current,
        required bool isStart,
      }) async {
    final parts = current.split(':');
    final initial = TimeOfDay(
      hour: int.parse(parts[0]),
      minute: int.parse(parts[1]),
    );

    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      builder: (context, child) => Theme(
        data: Theme.of(context).copyWith(
          colorScheme: ColorScheme.dark(
            primary: ref.read(accentColorProvider),
            surface: AppTheme.surface,
          ),
        ),
        child: child!,
      ),
    );

    if (picked == null) return;

    // Get the other time for validation
    final dayStart = ref.read(dayStartTimeProvider);
    final dayEnd = ref.read(dayEndTimeProvider);

    final pickedMinutes = picked.hour * 60 + picked.minute;

    if (isStart) {
      // Validate: start must be before end
      final endParts = dayEnd.split(':');
      final endMinutes =
          int.parse(endParts[0]) * 60 + int.parse(endParts[1]);

      if (pickedMinutes >= endMinutes) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context,
            'Day start must be earlier than day end ($dayEnd).',
          );
        }
        return;
      }
    } else {
      // Validate: end must be after start
      final startParts = dayStart.split(':');
      final startMinutes =
          int.parse(startParts[0]) * 60 + int.parse(startParts[1]);

      if (pickedMinutes <= startMinutes) {
        if (context.mounted) {
          SnackbarHelper.showError(
            context,
            'Day end must be later than day start ($dayStart).',
          );
        }
        return;
      }
    }

    // Validation passed — save
    final timeStr =
        '${picked.hour.toString().padLeft(2, '0')}:${picked.minute.toString().padLeft(2, '0')}';

    if (isStart) {
      ref.read(dayStartTimeProvider.notifier).setTime(timeStr);
    } else {
      ref.read(dayEndTimeProvider.notifier).setTime(timeStr);
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: const TextStyle(
        color: AppTheme.textSecondary,
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
      ),
    );
  }
}

class _SettingsCard extends StatelessWidget {
  final List<Widget> children;

  const _SettingsCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceVariant, width: 1),
      ),
      child: Column(children: children),
    );
  }
}

class _TimeTile extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onTap;

  const _TimeTile({
    required this.label,
    required this.value,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(label),
      trailing: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            value,
            style: TextStyle(
              color: Theme.of(context).colorScheme.primary,
              fontWeight: FontWeight.w600,
              fontSize: 14,
            ),
          ),
        ),
      ),
    );
  }
}