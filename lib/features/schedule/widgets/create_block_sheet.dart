import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:timebloxs/core/utils/color_utils.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/scheduled_block.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../../tasks/providers/task_providers.dart';

class CreateBlockSheet extends ConsumerStatefulWidget {
  final DateTime date;
  final ScheduledBlock? existingBlock; // null = create, set = edit

  const CreateBlockSheet({
    super.key,
    required this.date,
    this.existingBlock,
  });

  @override
  ConsumerState<CreateBlockSheet> createState() => _CreateBlockSheetState();
}

class _CreateBlockSheetState extends ConsumerState<CreateBlockSheet> {
  final _labelController = TextEditingController();
  late TimeOfDay _startTime;
  late int _durationMins;
  late BlockType _blockType;
  String? _selectedCategoryId;
  String? _selectedTaskId;
  bool _isLoading = false;

  final List<int> _durationOptions = [15, 30, 45, 60, 90, 120];

  bool get _isEditing => widget.existingBlock != null;

  @override
  void initState() {
    super.initState();
    final block = widget.existingBlock;
    if (block != null) {
      // Pre-populate fields from existing block
      _labelController.text = block.label;
      final parts = block.startTime.split(':');
      _startTime = TimeOfDay(
        hour: int.parse(parts[0]),
        minute: int.parse(parts[1]),
      );
      // Clamp to nearest duration option or add it
      _durationMins = _durationOptions.contains(block.durationMins)
          ? block.durationMins
          : _durationOptions.first;
      _blockType = block.blockType;
      _selectedCategoryId = block.categoryId;
      _selectedTaskId = block.taskTemplateId;
    } else {
      _startTime = TimeOfDay.now();
      _durationMins = 60;
      _blockType = BlockType.dynamic;
    }
  }

  @override
  void dispose() {
    _labelController.dispose();
    super.dispose();
  }

  bool get _isValid {
    if (_labelController.text.trim().isEmpty) return false;
    if (_selectedCategoryId == null) return false;
    if (_blockType == BlockType.static && _selectedTaskId == null) {
      return false;
    }
    return true;
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
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
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(scheduledBlockRepositoryProvider);
      final startTimeStr =
          '${_startTime.hour.toString().padLeft(2, '0')}:${_startTime.minute.toString().padLeft(2, '0')}';

      if (_isEditing) {
        // Update existing block
        final updated = widget.existingBlock!.copyWith(
          label: _labelController.text.trim(),
          startTime: startTimeStr,
          durationMins: _durationMins,
          blockType: _blockType,
          categoryId: _selectedCategoryId,
          taskTemplateId: _selectedTaskId,
        );
        await repo.update(updated);
      } else {
        // Create new block
        final block = ScheduledBlock(
          id: '',
          date: widget.date,
          startTime: startTimeStr,
          durationMins: _durationMins,
          label: _labelController.text.trim(),
          blockType: _blockType,
          taskTemplateId: _selectedTaskId,
          categoryId: _selectedCategoryId!,
          status: BlockStatus.planned,
          created: DateTime.now(),
          updated: DateTime.now(),
        );
        await repo.create(block);
      }

      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      await logger.error('CreateBlockSheet._submit', e, stack);
      SnackbarHelper.showError(
        context,
        _isEditing
            ? ErrorMessages.updateBlockFailed
            : ErrorMessages.createBlockFailed,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categoriesAsync = ref.watch(taskCategoriesProvider);
    // Change this line at the top of build:
    final tasksAsync = ref.watch(allTasksForPickerProvider);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: SingleChildScrollView(
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const Gap(20),

            Text(
              _isEditing ? 'Edit Block' : 'New Block',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(24),

            // Label
            TextField(
              controller: _labelController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Label',
                hintText: 'e.g. Morning Focus',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Gap(16),

            // Time + Duration row
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    onTap: _pickStartTime,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.access_time,
                            size: 18,
                            color: AppTheme.textSecondary,
                          ),
                          const Gap(8),
                          Text(
                            _startTime.format(context),
                            style: const TextStyle(
                              color: AppTheme.textPrimary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                const Gap(12),
                Expanded(
                  child: DropdownButtonFormField<int>(
                    value: _durationMins,
                    dropdownColor: AppTheme.surfaceVariant,
                    decoration: const InputDecoration(
                      labelText: 'Duration',
                      prefixIcon: Icon(Icons.timer_outlined, size: 18),
                    ),
                    items: _durationOptions
                        .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(_formatDuration(d)),
                    ))
                        .toList(),
                    onChanged: (v) =>
                        setState(() => _durationMins = v ?? 60),
                  ),
                ),
              ],
            ),
            const Gap(16),

            // Block type toggle
            Text(
              'BLOCK TYPE',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Row(
              children: [
                _TypeChip(
                  label: 'Dynamic',
                  subtitle: 'Decide task later',
                  selected: _blockType == BlockType.dynamic,
                  onTap: () =>
                      setState(() => _blockType = BlockType.dynamic),
                ),
                const Gap(8),
                _TypeChip(
                  label: 'Static',
                  subtitle: 'Specific task now',
                  selected: _blockType == BlockType.static,
                  onTap: () =>
                      setState(() => _blockType = BlockType.static),
                ),
              ],
            ),
            const Gap(16),

            // Category picker
            categoriesAsync.when(
              data: (categories) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CATEGORY',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      letterSpacing: 1.2,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Gap(8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: categories.map((category) {
                      final isSelected =
                          _selectedCategoryId == category.id;
                      final accentColor = Theme.of(context).colorScheme.primary;
                      final color = parseColor(category.color, fallback: accentColor);
                      return GestureDetector(
                        onTap: () => setState(
                                () => _selectedCategoryId = category.id),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 150),
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? color.withOpacity(0.2)
                                : AppTheme.surfaceVariant,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: isSelected
                                  ? color
                                  : Colors.transparent,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            category.name,
                            style: TextStyle(
                              color: isSelected
                                  ? color
                                  : AppTheme.textSecondary,
                              fontSize: 13,
                              fontWeight: isSelected
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
              loading: () => const CircularProgressIndicator(),
              error: (_, __) => const SizedBox.shrink(),
            ),
            const Gap(16),

            // Task picker (only for static blocks)
// Task picker (only for static blocks)
            if (_blockType == BlockType.static)
              tasksAsync.when(
                data: (tasks) {
                  final available = tasks
                      .where((t) =>
                  !t.isArchived &&
                      (_selectedCategoryId == null ||
                          t.categoryId == _selectedCategoryId))
                      .toList();

                  if (available.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: AppTheme.surfaceVariant,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.info_outline,
                            size: 16,
                            color: AppTheme.textSecondary,
                          ),
                          const Gap(8),
                          Expanded(
                            child: Text(
                              'No tasks available for this category. '
                                  'Add tasks in the Tasks tab first.',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final taskExists =
                  available.any((t) => t.id == _selectedTaskId);
                  if (!taskExists && _selectedTaskId != null) {
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) setState(() => _selectedTaskId = null);
                    });
                  }
                  final safeTaskValue = taskExists ? _selectedTaskId : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ASSIGN TASK',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String>(
                        value: safeTaskValue,
                        dropdownColor: AppTheme.surfaceVariant,
                        decoration: const InputDecoration(
                          hintText: 'Select a task',
                        ),
                        // No "No task assigned" option for static blocks
                        items: {for (final t in available) t.id: t}
                            .values
                            .map(
                              (t) => DropdownMenuItem(
                            value: t.id,
                            child: Text(t.name),
                          ),
                        )
                            .toList(),
                        onChanged: (v) => setState(() => _selectedTaskId = v),
                      ),
                      const Gap(8),
                      // Hint when no task selected
                      if (safeTaskValue == null)
                        Row(
                          children: [
                            const Icon(
                              Icons.warning_amber_outlined,
                              size: 14,
                              color: AppTheme.categoryChores,
                            ),
                            const Gap(6),
                            Text(
                              'Static blocks require an assigned task.',
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                color: AppTheme.categoryChores,
                              ),
                            ),
                          ],
                        ),
                      const Gap(16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

            // Submit
            ElevatedButton(
              onPressed: _isValid && !_isLoading ? _submit : null,
              child: _isLoading
                  ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
                  : Text(_isEditing ? 'Save Changes' : 'Add Block'),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDuration(int mins) {
    if (mins < 60) return '${mins}m';
    if (mins == 60) return '1h';
    final h = mins ~/ 60;
    final m = mins % 60;
    return m == 0 ? '${h}h' : '${h}h ${m}m';
  }
}

class _TypeChip extends StatelessWidget {
  final String label;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  const _TypeChip({
    required this.label,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          padding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: selected
                ? Theme.of(context).colorScheme.primary.withOpacity(0.15)
                : AppTheme.surfaceVariant,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: selected ? Theme.of(context).colorScheme.primary : Colors.transparent,
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: selected
                      ? Theme.of(context).colorScheme.primary
                      : AppTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                subtitle,
                style: const TextStyle(
                  color: AppTheme.textSecondary,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}