enum ProjectStatus {
  active,
  onHold,
  completed,
  archived;

  static ProjectStatus fromString(String value) {
    switch (value) {
      case 'on_hold':
        return ProjectStatus.onHold;
      case 'completed':
        return ProjectStatus.completed;
      case 'archived':
        return ProjectStatus.archived;
      default:
        return ProjectStatus.active;
    }
  }

  String toJson() {
    switch (this) {
      case ProjectStatus.onHold:
        return 'on_hold';
      case ProjectStatus.completed:
        return 'completed';
      case ProjectStatus.archived:
        return 'archived';
      default:
        return 'active';
    }
  }

  String get label {
    switch (this) {
      case ProjectStatus.active:
        return 'Active';
      case ProjectStatus.onHold:
        return 'On Hold';
      case ProjectStatus.completed:
        return 'Completed';
      case ProjectStatus.archived:
        return 'Archived';
    }
  }
}

class Project {
  final String id;
  final String name;
  final String? description;
  final String? color;
  final String? icon;
  final ProjectStatus status;
  final DateTime created;
  final DateTime updated;

  const Project({
    required this.id,
    required this.name,
    this.description,
    this.color,
    this.icon,
    required this.status,
    required this.created,
    required this.updated,
  });

  factory Project.fromRecord(Map<String, dynamic> record) {
    return Project(
      id: record['id'] as String,
      name: record['name'] as String,
      description: record['description'] as String?,
      color: record['color'] as String?,
      icon: record['icon'] as String?,
      status: ProjectStatus.fromString(
        record['status'] as String? ?? 'active',
      ),
      created: DateTime.parse(record['created'] as String),
      updated: DateTime.parse(record['updated'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'description': description,
      'color': color,
      'icon': icon,
      'status': status.toJson(),
    };
  }

  Project copyWith({
    String? name,
    String? description,
    String? color,
    String? icon,
    ProjectStatus? status,
  }) {
    return Project(
      id: id,
      name: name ?? this.name,
      description: description ?? this.description,
      color: color ?? this.color,
      icon: icon ?? this.icon,
      status: status ?? this.status,
      created: created,
      updated: updated,
    );
  }
}