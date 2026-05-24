class TaskTemplate {
  final String id;
  final String name;
  final String categoryId;
  final String? projectId;
  final String? parentTaskId;
  final String? notes;
  final bool isSystem;
  final bool isReusable;
  final bool isArchived;
  final DateTime created;
  final DateTime updated;

  // Optionally expanded relations
  final String? categoryName;
  final String? categoryColor;
  final String? projectName;
  final String? projectColor;

  const TaskTemplate({
    required this.id,
    required this.name,
    required this.categoryId,
    this.projectId,
    this.parentTaskId,
    this.notes,
    required this.isSystem,
    required this.isReusable,
    required this.isArchived,
    required this.created,
    required this.updated,
    this.categoryName,
    this.categoryColor,
    this.projectName,
    this.projectColor,
  });

  factory TaskTemplate.fromRecord(Map<String, dynamic> record) {
    // Handle expanded relations if present
    String? categoryName;
    String? categoryColor;
    String? projectName;
    String? projectColor;

    final expand = record['expand'] as Map<String, dynamic>?;
    if (expand != null) {
      final category = expand['category'] as Map<String, dynamic>?;
      if (category != null) {
        categoryName = category['name'] as String?;
        categoryColor = category['color'] as String?;
      }
      final project = expand['project'] as Map<String, dynamic>?;
      if (project != null) {
        projectName = project['name'] as String?;
        projectColor = project['color'] as String?;
      }
    }

    return TaskTemplate(
      id: record['id'] as String,
      name: record['name'] as String,
      categoryId: record['category'] as String,
      projectId: record['project'] as String?,
      parentTaskId: record['parent_task'] as String?,
      notes: record['notes'] as String?,
      isSystem: record['is_system'] as bool? ?? false,
      isReusable: record['is_reusable'] as bool? ?? false,
      isArchived: record['is_archived'] as bool? ?? false,
      created: DateTime.parse(record['created'] as String),
      updated: DateTime.parse(record['updated'] as String),
      categoryName: categoryName,
      categoryColor: categoryColor,
      projectName: projectName,
      projectColor: projectColor,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'category': categoryId,
      if (projectId != null) 'project': projectId,
      if (parentTaskId != null) 'parent_task': parentTaskId,
      if (notes != null) 'notes': notes,
      'is_system': isSystem,
      'is_reusable': isReusable,
      'is_archived': isArchived,
    };
  }

  TaskTemplate copyWith({
    String? name,
    String? categoryId,
    String? projectId,
    String? parentTaskId,
    String? notes,
    bool? isSystem,
    bool? isReusable,
    bool? isArchived,
  }) {
    return TaskTemplate(
      id: id,
      name: name ?? this.name,
      categoryId: categoryId ?? this.categoryId,
      projectId: projectId ?? this.projectId,
      parentTaskId: parentTaskId ?? this.parentTaskId,
      notes: notes ?? this.notes,
      isSystem: isSystem ?? this.isSystem,
      isReusable: isReusable ?? this.isReusable,
      isArchived: isArchived ?? this.isArchived,
      created: created,
      updated: updated,
      categoryName: categoryName,
      categoryColor: categoryColor,
      projectName: projectName,
      projectColor: projectName
    );
  }

  bool get hasProject => projectId != null && projectId!.isNotEmpty;
  bool get isSubTask => parentTaskId != null && parentTaskId!.isNotEmpty;
}