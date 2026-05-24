enum BlockType {
  static,
  dynamic;

  static BlockType fromString(String value) {
    switch (value) {
      case 'dynamic':
        return BlockType.dynamic;
      default:
        return BlockType.static;
    }
  }

  String toJson() => name;
}

enum BlockStatus {
  planned,
  active,
  completed,
  skipped;

  static BlockStatus fromString(String value) {
    switch (value) {
      case 'active':
        return BlockStatus.active;
      case 'completed':
        return BlockStatus.completed;
      case 'skipped':
        return BlockStatus.skipped;
      default:
        return BlockStatus.planned;
    }
  }

  String toJson() => name;

  String get label {
    switch (this) {
      case BlockStatus.planned:
        return 'Planned';
      case BlockStatus.active:
        return 'Active';
      case BlockStatus.completed:
        return 'Completed';
      case BlockStatus.skipped:
        return 'Skipped';
    }
  }
}

class ScheduledBlock {
  final String id;
  final DateTime date;
  final String startTime;
  final int durationMins;
  final String label;
  final BlockType blockType;
  final String? taskTemplateId;
  final String categoryId;
  final BlockStatus status;
  final String? notes;
  final DateTime created;
  final DateTime updated;

  // Optionally expanded relations
  final String? taskTemplateName;
  final String? categoryName;
  final String? categoryColor;
  final String? projectColor;
  final String? taskCategoryColor;

  const ScheduledBlock({
    required this.id,
    required this.date,
    required this.startTime,
    required this.durationMins,
    required this.label,
    required this.blockType,
    this.taskTemplateId,
    required this.categoryId,
    required this.status,
    this.notes,
    required this.created,
    required this.updated,
    this.taskTemplateName,
    this.categoryName,
    this.categoryColor,
    this.projectColor,
    this.taskCategoryColor,
  });

  factory ScheduledBlock.fromRecord(Map<String, dynamic> record) {
    String? taskTemplateName;
    String? categoryName;
    String? categoryColor;
    String? taskCategoryColor;

    final expand = record['expand'] as Map<String, dynamic>?;
    if (expand != null) {
      final task = expand['task_template'] as Map<String, dynamic>?;
      if (task != null) {
        taskTemplateName = task['name'] as String?;
        taskCategoryColor = task['category_color'] as String?;
      }
      final category = expand['category'] as Map<String, dynamic>?;
      if (category != null) {
        categoryName = category['name'] as String?;
        categoryColor = category['color'] as String?;
      }
    }

    return ScheduledBlock(
      id: record['id'] as String,
      date: DateTime.parse(record['date'] as String),
      startTime: record['start_time'] as String,
      durationMins: record['duration_mins'] as int,
      label: record['label'] as String,
      blockType: BlockType.fromString(record['block_type'] as String),
      taskTemplateId: record['task_template'] as String?,
      categoryId: record['category'] as String,
      status: BlockStatus.fromString(record['status'] as String),
      notes: record['notes'] as String?,
      created: DateTime.parse(record['created'] as String),
      updated: DateTime.parse(record['updated'] as String),
      taskTemplateName: taskTemplateName,
      taskCategoryColor: taskCategoryColor,
      categoryName: categoryName,
      categoryColor: categoryColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'date': date.toIso8601String().split('T').first,
      'start_time': startTime,
      'duration_mins': durationMins,
      'label': label,
      'block_type': blockType.toJson(),
      if (taskTemplateId != null) 'task_template': taskTemplateId,
      'category': categoryId,
      'status': status.toJson(),
      if (notes != null) 'notes': notes,
    };
  }

  ScheduledBlock copyWith({
    String? label,
    String? startTime,
    int? durationMins,
    BlockType? blockType,
    Object? taskTemplateId = _sentinel,  // use sentinel
    String? categoryId,
    BlockStatus? status,
    Object? notes = _sentinel,           // same for notes
    String? projectColor,
    Object? taskCategoryColor = _sentinel,
  }) {
    return ScheduledBlock(
      id: id,
      date: date,
      startTime: startTime ?? this.startTime,
      durationMins: durationMins ?? this.durationMins,
      label: label ?? this.label,
      blockType: blockType ?? this.blockType,
      taskTemplateId: taskTemplateId == _sentinel
          ? this.taskTemplateId
          : taskTemplateId as String?,
      categoryId: categoryId ?? this.categoryId,
      status: status ?? this.status,
      notes: notes == _sentinel ? this.notes : notes as String?,
      created: created,
      updated: updated,
      taskTemplateName: taskTemplateName,
      categoryName: categoryName,
      categoryColor: categoryColor ?? categoryColor,
      projectColor: projectColor == _sentinel
          ? this.projectColor
          : projectColor,
      taskCategoryColor: taskCategoryColor == _sentinel
          ? this.taskCategoryColor
          : taskCategoryColor as String?,
    );
  }

  // Private sentinel object — unique instance used to detect "not provided"
  static const Object _sentinel = Object();

  /// Returns end time as a string e.g. "10:45"
  String get endTime {
    final parts = startTime.split(':');
    final startMinutes =
        int.parse(parts[0]) * 60 + int.parse(parts[1]);
    final endMinutes = startMinutes + durationMins;
    final hours = (endMinutes ~/ 60) % 24;
    final minutes = endMinutes % 60;
    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}';
  }

  bool get isDynamic => blockType == BlockType.dynamic;
  bool get isAssigned => taskTemplateId != null && taskTemplateId!.isNotEmpty;
}