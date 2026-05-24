import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import '../../../core/providers/invalidation_service.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/models/project.dart';
import '../../../core/repositories/repository_providers.dart';
import '../../../core/utils/app_logger.dart';
import '../../../core/utils/error_messages.dart';
import '../../../core/utils/snackbar_helper.dart';

class CreateProjectSheet extends ConsumerStatefulWidget {
  final Project? existingProject;

  const CreateProjectSheet({super.key, this.existingProject});

  @override
  ConsumerState<CreateProjectSheet> createState() =>
      _CreateProjectSheetState();
}

class _CreateProjectSheetState extends ConsumerState<CreateProjectSheet> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  String _selectedColor = '#6C63FF';
  bool _isLoading = false;

  bool get _isEditing => widget.existingProject != null;

  final List<String> _colorOptions = [
    '#6C63FF',
    '#2196F3',
    '#4CAF50',
    '#FF9800',
    '#F44336',
    '#9C27B0',
    '#00BCD4',
    '#607D8B',
    '#E91E63',
    '#FF5722',
  ];

  @override
  void initState() {
    super.initState();
    final project = widget.existingProject;
    if (project != null) {
      _nameController.text = project.name;
      _descriptionController.text = project.description ?? '';
      _selectedColor = project.color ?? '#6C63FF';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  bool get _isValid => _nameController.text.trim().isNotEmpty;

  Future<void> _submit() async {
    final invalidation = ref.read(invalidationServiceProvider);

    if (!_isValid) return;
    setState(() => _isLoading = true);

    try {
      final repo = ref.read(projectRepositoryProvider);

      if (_isEditing) {
        final updated = widget.existingProject!.copyWith(
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          color: _selectedColor,
        );
        await repo.update(updated);
      } else {
        final project = Project(
          id: '',
          name: _nameController.text.trim(),
          description: _descriptionController.text.trim().isEmpty
              ? null
              : _descriptionController.text.trim(),
          color: _selectedColor,
          status: ProjectStatus.active,
          created: DateTime.now(),
          updated: DateTime.now(),
        );
        await repo.create(project);
      }

      invalidation.onProjectChanged();
      if (mounted) Navigator.pop(context);
    } catch (e, stack) {
      await logger.error('CreateProjectSheet._submit', e, stack);
      if(!mounted) return;
      SnackbarHelper.showError(
        context,
        _isEditing
            ? ErrorMessages.updateProjectFailed
            : ErrorMessages.createProjectFailed,
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              _isEditing ? 'Edit Project' : 'New Project',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const Gap(24),

            // Name field
            TextField(
              controller: _nameController,
              autofocus: !_isEditing,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Project name',
                hintText: 'e.g. TitanServer',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const Gap(16),

            // Description field
            TextField(
              controller: _descriptionController,
              maxLines: 2,
              textCapitalization: TextCapitalization.sentences,
              decoration: const InputDecoration(
                labelText: 'Description (optional)',
                hintText: 'What is this project about?',
              ),
            ),
            const Gap(16),

            // Color picker
            Text(
              'COLOUR',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                letterSpacing: 1.2,
                fontWeight: FontWeight.w600,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _colorOptions.map((hex) {
                final color =
                Color(int.parse(hex.replaceFirst('#', '0xFF')));
                final isSelected = _selectedColor == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColor = hex),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isSelected
                            ? Colors.white
                            : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow: isSelected
                          ? [
                        BoxShadow(
                          color: color.withValues(alpha: 0.5),
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
                      size: 18,
                    )
                        : null,
                  ),
                );
              }).toList(),
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
                  : Text(_isEditing ? 'Save Changes' : 'Create Project'),
            ),
          ],
        ),
      ),
    );
  }
}