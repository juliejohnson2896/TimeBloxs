import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timebloxs/core/utils/color_utils.dart';
import 'package:timebloxs/features/schedule/widgets/create_block_sheet.dart';
import '../../../core/models/scheduled_block.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/snackbar_helper.dart';
import 'assign_task_sheet.dart';

class TimeBlockCard extends ConsumerWidget {
  final ScheduledBlock block;

  const TimeBlockCard({super.key, required this.block});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final accentColor = Theme.of(context).colorScheme.primary;

    // Project colour takes priority over category colour
    final color = block.projectColor != null
        ? parseColor(block.projectColor, fallback: accentColor)
        : parseColor(block.categoryColor, fallback: accentColor);

    final isShort = block.durationMins < 30;

    return GestureDetector(
      onTap: () => _showBlockOptions(context, ref),
      onLongPress: () => _confirmDelete(context, ref),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Container(
          decoration: BoxDecoration(
            color: color.withOpacity(0.25),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color.withOpacity(0.5),
              width: 1,
            ),
          ),
          child: IntrinsicHeight(
            child: Row(
              children: [
                // Left accent bar
                Container(
                  width: 4,
                  color: color,
                ),
                // Content
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: isShort ? 2 : 6,
                    ),
                    child: isShort
                        ? _buildShortContent()
                        : _buildFullContent(context, color),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildShortContent() {
    return Row(
      children: [
        Expanded(
          child: Text(
            block.label,
            style: const TextStyle(
              color: AppTheme.textPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        Text(
          block.startTime,
          style: const TextStyle(
            color: AppTheme.textSecondary,
            fontSize: 10,
          ),
        ),
      ],
    );
  }

  Widget _buildFullContent(BuildContext context,Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,       // add this
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                block.label,
                style: const TextStyle(
                  color: AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 2,               // allow wrapping
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (block.isDynamic && !block.isAssigned)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.primary.withOpacity(0.4),
                    width: 1,
                  ),
                ),
                child: Text(
                  'Dynamic',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        if (block.durationMins >= 30) ...[    // only show time row for longer blocks
          const Gap(2),
          Row(
            children: [
              Text(
                '${block.startTime} – ${block.endTime}',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
              if (block.categoryName != null) ...[
                const Text(
                  ' · ',
                  style: TextStyle(color: AppTheme.textDisabled, fontSize: 11),
                ),
                Text(
                  block.categoryName!,
                  style: TextStyle(
                    color: color,
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ],
          ),
        ],
        if (block.taskTemplateName != null && block.durationMins >= 45) ...[
          const Gap(4),
          Text(
            block.taskTemplateName!,
            style: const TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 11,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  void _showBlockOptions(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppTheme.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Gap(8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppTheme.surfaceVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const Gap(12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      block.label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary,
                      ),
                    ),
                  ),
                  _StatusBadge(status: block.status),
                ],
              ),
            ),
            const Gap(4),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                '${block.startTime} – ${block.endTime} · ${block.durationMins} min',
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 13,
                ),
              ),
            ),
            const Gap(8),
            const Divider(height: 1),

            // Edit block
            ListTile(
              leading: const Icon(
                Icons.edit_outlined,
                color: AppTheme.textSecondary,
              ),
              title: const Text('Edit block'),
              onTap: () {
                Navigator.pop(context);
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  backgroundColor: AppTheme.surface,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (_) => CreateBlockSheet(
                    date: block.date,
                    existingBlock: block,
                  ),
                );
              },
            ),

            // Dynamic block task management
            if (block.isDynamic) ...[
              if (block.isAssigned) ...[
                // Reassign option
                ListTile(
                  leading: Icon(
                    Icons.swap_horiz_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Reassign Task',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  subtitle: Text(
                    block.taskTemplateName ?? '',
                    style: const TextStyle(
                      color: AppTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppTheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => AssignTaskSheet(
                        blockId: block.id,
                        categoryId: block.categoryId,
                      ),
                    );
                  },
                ),
                // Unassign option
                ListTile(
                  leading: const Icon(
                    Icons.link_off_outlined,
                    color: AppTheme.textSecondary,
                  ),
                  title: const Text('Unassign Task'),
                  subtitle: const Text(
                    'Keep block, remove assigned task',
                    style: TextStyle(fontSize: 12),
                  ),
                  onTap: () async {
                    Navigator.pop(context);
                    try {
                      await ref
                          .read(scheduledBlockRepositoryProvider)
                          .unassignTask(block.id);
                    } catch (e, stack) {
                      await logger.error(
                          'TimeBlockCard.unassignTask', e, stack);
                      if (context.mounted) {
                        SnackbarHelper.showError(
                          context,
                          'Couldn\'t unassign the task. Please try again.',
                        );
                      }
                    }
                  },
                ),
              ] else ...[
                // Assign option — no task yet
                ListTile(
                  leading: Icon(
                    Icons.playlist_add_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  title: Text(
                    'Assign Task',
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                  onTap: () {
                    Navigator.pop(context);
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: AppTheme.surface,
                      shape: const RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.vertical(top: Radius.circular(20)),
                      ),
                      builder: (_) => AssignTaskSheet(
                        blockId: block.id,
                        categoryId: block.categoryId,
                      ),
                    );
                  },
                ),
              ],
            ],

            const Divider(height: 1),

            // Status actions
            if (block.status == BlockStatus.planned)
              ListTile(
                leading: const Icon(
                  Icons.play_circle_outline,
                  color: AppTheme.secondary,
                ),
                title: const Text('Start block'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(scheduledBlockRepositoryProvider)
                      .updateStatus(block.id, BlockStatus.active);
                },
              ),
            if (block.status == BlockStatus.active)
              ListTile(
                leading: const Icon(
                  Icons.check_circle_outline,
                  color: AppTheme.categoryMindfulBreaks,
                ),
                title: const Text('Complete block'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(scheduledBlockRepositoryProvider)
                      .updateStatus(block.id, BlockStatus.completed);
                },
              ),
            if (block.status == BlockStatus.planned ||
                block.status == BlockStatus.active)
              ListTile(
                leading: const Icon(
                  Icons.skip_next_outlined,
                  color: AppTheme.textSecondary,
                ),
                title: const Text('Skip block'),
                onTap: () async {
                  Navigator.pop(context);
                  await ref
                      .read(scheduledBlockRepositoryProvider)
                      .updateStatus(block.id, BlockStatus.skipped);
                },
              ),

            const Divider(height: 1),

            ListTile(
              leading: const Icon(
                Icons.delete_outline,
                color: AppTheme.error,
              ),
              title: const Text(
                'Delete block',
                style: TextStyle(color: AppTheme.error),
              ),
              onTap: () async {
                Navigator.pop(context);
                await ref
                    .read(scheduledBlockRepositoryProvider)
                    .delete(block.id);
              },
            ),
            const Gap(8),
          ],
        ),
      ),
    );
  }

  Future<void> _confirmDelete(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: AppTheme.surface,
        title: const Text('Delete block?'),
        content: Text('Remove "${block.label}" from your schedule?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppTheme.error),
            ),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await ref.read(scheduledBlockRepositoryProvider).delete(block.id);
    }
  }
}

class _StatusBadge extends StatelessWidget {
  final BlockStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3), width: 1),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Color _statusColor(BlockStatus status) {
    switch (status) {
      case BlockStatus.planned:
        return AppTheme.textSecondary;
      case BlockStatus.active:
        return AppTheme.secondary;
      case BlockStatus.completed:
        return AppTheme.categoryMindfulBreaks;
      case BlockStatus.skipped:
        return AppTheme.textDisabled;
    }
  }
}