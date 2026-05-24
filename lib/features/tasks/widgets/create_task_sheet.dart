import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/providers/invalidation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/task_template.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/snackbar_helper.dart';
import '../providers/task_providers.dart';

class CreateTaskSheet extends ConsumerStatefulWidget {
  final TaskTemplate? existingTask;
  final TaskTemplate? parentTask; // set when creating a sub-task

  const CreateTaskSheet({
    super.key,
    this.existingTask,
    this.parentTask,
  });

  @override
  ConsumerState<CreateTaskSheet> createState() => _CreateTaskSheetState();
}

class _CreateTaskSheetState extends ConsumerState<CreateTaskSheet> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedCategoryId;
  String? _selectedProjectId;
  bool _isReusable = false;
  bool _isLoading = false;

  bool get _isEditing => widget.existingTask != null;
  bool get _isSubTask =>
      widget.parentTask != null ||
          (widget.existingTask != null && widget.existingTask!.isSubTask);

  @override
  void initState() {
    super.initState();
    final task = widget.existingTask;
    final parent = widget.parentTask;

    if (task != null) {
      // Editing existing task
      _nameController.text = task.name;
      _notesController.text = task.notes ?? '';
      _selectedCategoryId = task.categoryId;
      _selectedProjectId = task.projectId;
      _isReusable = task.isReusable;
    } else if (parent != null) {
      // Creating sub-task — inherit from parent
      _selectedCategoryId = parent.categoryId;
      _selectedProjectId = parent.projectId;
      _isReusable = false; // sub-tasks are always one-off
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _isValid =>
      _nameController.text.trim().isNotEmpty && _selectedCategoryId != null;

  Future<void> _submit() async {
    if (!_isValid) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(taskTemplateRepositoryProvider);
      final invalidation = ref.read(invalidationServiceProvider);

      if (_isEditing) {
        final updated = widget.existingTask!.copyWith(
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId,
          projectId: _selectedProjectId,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isReusable: _isReusable,
        );
        await repo.update(updated);
      } else {
        final task = TaskTemplate(
          id: '',
          name: _nameController.text.trim(),
          categoryId: _selectedCategoryId!,
          projectId: _isSubTask
              ? widget.parentTask!.projectId  // inherit from parent
              : _selectedProjectId,
          parentTaskId: _isSubTask
              ? widget.parentTask!.id         // link to parent
              : null,
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
          isSystem: false,
          isReusable: _isSubTask ? false : _isReusable,
          isArchived: false,
          created: DateTime.now(),
          updated: DateTime.now(),
        );
        await repo.create(task);
      }

      // In _submit after create or update:
      if (_isSubTask) {
        invalidation.onSubTaskChanged(
          widget.parentTask?.id ?? widget.existingTask!.parentTaskId!,
        );
      } else {
        invalidation.onTaskChanged();
      }

      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      await logger.error('CreateTaskSheet._submit', e, stack);
      if(!mounted) return;
      SnackbarHelper.showError(
        context,
        _isEditing
            ? ErrorMessages.updateTaskFailed
            : ErrorMessages.createTaskFailed,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final accentColor = Theme.of(context).colorScheme.primary;
    final categoriesAsync = ref.watch(taskCategoriesProvider);
    final projectsAsync = ref.watch(projectsProvider);

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
              _isEditing
                  ? 'Edit Task'
                  : _isSubTask
                  ? 'New Sub-task'
                  : 'New Task',
              style: Theme.of(context).textTheme.headlineSmall,
            ),

            // Add this right after the title, before the name field
            if (_isSubTask) ...[
              const Gap(4),
              Row(
                children: [
                  const Icon(
                    Icons.subdirectory_arrow_right,
                    size: 14,
                    color: AppTheme.textSecondary,
                  ),
                  const Gap(4),
                  Text(
                    widget.parentTask != null
                        ? 'Sub-task of ${widget.parentTask!.name}'
                        : 'Sub-task',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
              const Gap(16),
            ] else
              const Gap(24),

            // Name field
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Task name',
                hintText: 'e.g. Do the dishes',
              ),
              onChanged: (_) => setState(() {}),
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
                      final color = Color(int.parse(
                          category.color.replaceFirst('#', '0xFF')));
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
                                ? color.withValues(alpha: 0.2)
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

            // Project picker
            if (!_isSubTask)
              projectsAsync.when(
                data: (projects) {
                  if (projects.isEmpty) return const SizedBox.shrink();

                  // If the selected project no longer exists, clear it
                  final projectExists =
                  projects.any((p) => p.id == _selectedProjectId);
                  if (!projectExists && _selectedProjectId != null) {
                    // Schedule the state update for after build completes
                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (mounted) {
                        setState(() => _selectedProjectId = null);
                      }
                    });
                  }

                  // Use null if project doesn't exist to avoid dropdown error
                  final safeValue = projectExists ? _selectedProjectId : null;

                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'PROJECT (OPTIONAL)',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          letterSpacing: 1.2,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String>(
                        initialValue: safeValue,    // use safeValue not _selectedProjectId
                        dropdownColor: AppTheme.surfaceVariant,
                        decoration: const InputDecoration(
                          hintText: 'No project',
                        ),
                        items: [
                          const DropdownMenuItem(
                            value: null,
                            child: Text('No project'),
                          ),
                          ...projects.map(
                                (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(p.name),
                            ),
                          ),
                        ],
                        onChanged: (value) =>
                            setState(() => _selectedProjectId = value),
                      ),
                      const Gap(16),
                    ],
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (_, __) => const SizedBox.shrink(),
              ),

            // Notes field
            TextField(
              controller: _notesController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Notes (optional)',
                hintText: 'Any extra details...',
              ),
            ),
            const Gap(16),

            // Reusable toggle — hidden for sub-tasks
            if (!_isSubTask)
              Container(
                padding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: AppTheme.surfaceVariant,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Reusable task',
                            style: TextStyle(fontWeight: FontWeight.w500),
                          ),
                          Text(
                            'Stays in your pool permanently',
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isReusable,
                      onChanged: (value) =>
                          setState(() => _isReusable = value),
                      activeThumbColor: accentColor,
                    ),
                  ],
                ),
              ),

            const Gap(24),

            // Submit button
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Task'),
            ),
          ],
        ),
      ),
    );
  }
}