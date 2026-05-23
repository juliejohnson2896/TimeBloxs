import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import 'tables/task_categories_table.dart';
import 'tables/projects_table.dart';
import 'tables/task_templates_table.dart';
import 'tables/scheduled_blocks_table.dart';
import 'daos/task_categories_dao.dart';
import 'daos/projects_dao.dart';
import 'daos/task_templates_dao.dart';
import 'daos/scheduled_blocks_dao.dart';

part 'app_database.g.dart';

@DriftDatabase(
  tables: [
    TaskCategoriesTable,
    ProjectsTable,
    TaskTemplatesTable,
    ScheduledBlocksTable,
  ],
  daos: [
    TaskCategoriesDao,
    ProjectsDao,
    TaskTemplatesDao,
    ScheduledBlocksDao,
  ],
)
class AppDatabase extends _$AppDatabase {
  // Default constructor
  AppDatabase() : super(_openConnection());

  // Testing constructor — uses provided query executor (in-memory)
  AppDatabase.forTesting(super.executor);

  @override
  int get schemaVersion => 2;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) async {
      await m.createAll();
      await _seedSystemData();
    },
    onUpgrade: (m, from, to) async {
      // v2 — removed userId from projects and task_templates
      // userId is only needed at sync time, not stored locally
      if (from < 2) {
        // Safely remove user column from projects
        // Step 1: rename old table
        await customStatement(
            'ALTER TABLE projects RENAME TO projects_old'
        );
        // Step 2: create new table without user column
        await m.createTable(projectsTable);
        // Step 3: copy data across, excluding user column
        await customStatement('''
      INSERT INTO projects (id, name, description, color, icon, 
        status, created_at, updated_at, sync_id, is_dirty)
      SELECT id, name, description, color, icon,
        status, created_at, updated_at, sync_id, is_dirty
      FROM projects_old
    ''');
        // Step 4: drop old table
        await customStatement('DROP TABLE projects_old');

        // Same for task_templates
        await customStatement(
            'ALTER TABLE task_templates RENAME TO task_templates_old'
        );
        await m.createTable(taskTemplatesTable);
        await customStatement('''
      INSERT INTO task_templates (id, name, category_id, project_id,
        parent_task_id, notes, is_system, is_reusable, is_archived,
        created_at, updated_at, sync_id, is_dirty)
      SELECT id, name, category_id, project_id,
        parent_task_id, notes, is_system, is_reusable, is_archived,
        created_at, updated_at, sync_id, is_dirty
      FROM task_templates_old
    ''');
        await customStatement('DROP TABLE task_templates_old');
      }
    },
  );

  /// Seeds the system categories and mindful break tasks on first launch
  Future<void> _seedSystemData() async {
    final now = DateTime.now();

    // System category
    await into(taskCategoriesTable).insert(
      TaskCategoriesTableCompanion.insert(
        id: 'sys_cat_mindful',
        name: 'Mindful Breaks',
        color: '#4CAF50',
        icon: const Value('self_care'),
        isSystem: const Value(true),
        isDefault: const Value(true),
        createdAt: now,
        updatedAt: now,
      ),
    );

    // Default categories
    final defaultCategories = [
      ('sys_cat_focus', 'Focus', '#2196F3'),
      ('sys_cat_selfcare', 'Self Care', '#9C27B0'),
      ('sys_cat_chores', 'Chores', '#FF9800'),
      ('sys_cat_project', 'Project Work', '#F44336'),
      ('sys_cat_admin', 'Admin', '#607D8B'),
    ];

    for (final (id, name, color) in defaultCategories) {
      await into(taskCategoriesTable).insert(
        TaskCategoriesTableCompanion.insert(
          id: id,
          name: name,
          color: color,
          isDefault: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }

    // System mindful break tasks
    final systemTasks = [
      ('sys_task_break', 'Break Time'),
      ('sys_task_stretch', '10 Second Stretch'),
      ('sys_task_walk', 'Get Up and Walk Around'),
      ('sys_task_breathe', 'Deep Breathing'),
      ('sys_task_outside', 'Step Outside'),
    ];

    for (final (id, name) in systemTasks) {
      await into(taskTemplatesTable).insert(
        TaskTemplatesTableCompanion.insert(
          id: id,
          name: name,
          categoryId: 'sys_cat_mindful',
          isSystem: const Value(true),
          isReusable: const Value(true),
          createdAt: now,
          updatedAt: now,
        ),
      );
    }
  }
}

LazyDatabase _openConnection() {
  return LazyDatabase(() async {
    final dbFolder = await getApplicationDocumentsDirectory();
    final file = File(p.join(dbFolder.path, 'timebloxs.db'));
    return NativeDatabase.createInBackground(file);
  });
}