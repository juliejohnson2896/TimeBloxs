class TaskCategory {
  final String id;
  final String name;
  final String color;
  final String? icon;
  final bool isSystem;
  final bool isDefault;
  final DateTime created;
  final DateTime updated;

  const TaskCategory({
    required this.id,
    required this.name,
    required this.color,
    this.icon,
    required this.isSystem,
    required this.isDefault,
    required this.created,
    required this.updated,
  });

  factory TaskCategory.fromRecord(Map<String, dynamic> record) {
    return TaskCategory(
      id: record['id'] as String,
      name: record['name'] as String,
      color: record['color'] as String,
      icon: record['icon'] as String?,
      isSystem: record['is_system'] as bool? ?? false,
      isDefault: record['is_default'] as bool? ?? false,
      created: DateTime.parse(record['created'] as String),
      updated: DateTime.parse(record['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'color': color,
      'icon': icon,
      'is_system': isSystem,
      'is_default': isDefault,
    };
  }

  TaskCategory copyWith({
    String? name,
    String? color,
    String? icon,
    bool? isSystem,
    bool? isDefault,
  }) {
    return TaskCategory(
      id: id,
      name: name ?? this.name,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      isSystem: isSystem ?? this.isSystem,
      isDefault: isDefault ?? this.isDefault,
      created: created,
      updated: updated,
    );
  }
}