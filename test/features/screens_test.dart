import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/database/app_database.dart';
import 'package:timebloxs/core/theme/app_theme.dart';
import 'package:timebloxs/features/projects/screens/projects_screen.dart';
import 'package:timebloxs/features/schedule/screens/schedule_screen.dart';
import 'package:timebloxs/features/tasks/screens/tasks_screen.dart';
import 'package:timebloxs/main.dart';

import '../helpers/test_database.dart';

// Builds a fully self contained test app for a given screen
// Each call creates a fresh router and provider scope
Widget buildTestApp({
  required Widget screen,
  required AppDatabase db,
}) {
  return ProviderScope(
    overrides: [
      appDatabaseProvider.overrideWithValue(db),
    ],
    child: MaterialApp(
      theme: AppTheme.darkTheme,
      home: screen,
    ),
  );
}

void main() {
  late AppDatabase db;

  setUp(() {
    db = createTestDatabase();
  });

  tearDown(() async {
    await Future.delayed(Duration.zero);
    await db.close();
  });

  Future<void> cleanupWidgetTest(WidgetTester tester) async {
    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pumpAndSettle();
  }

  group('TasksScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const TasksScreen(), db: db),
      );
      await tester.pump();
      expect(find.byType(TasksScreen), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Task Pool app bar title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const TasksScreen(), db: db),
      );
      await tester.pump();
      expect(find.text('Task Pool'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows add button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const TasksScreen(), db: db),
      );
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows search field after data loads', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const TasksScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(TextField), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Mindful Breaks after loading', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const TasksScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Mindful Breaks'), findsNWidgets(7));
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Break Time system task', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const TasksScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Break Time'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });
  });

  group('ProjectsScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ProjectsScreen(), db: db),
      );
      await tester.pump();
      expect(find.byType(ProjectsScreen), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Projects app bar title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ProjectsScreen(), db: db),
      );
      await tester.pump();
      expect(find.text('Projects'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows add button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ProjectsScreen(), db: db),
      );
      await tester.pump();
      expect(find.byIcon(Icons.add), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows empty state when no projects', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ProjectsScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('No projects yet'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows All filter chip', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ProjectsScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('All'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Active filter chip', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ProjectsScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.text('Active'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });
  });

  group('ScheduleScreen', () {
    testWidgets('renders without error', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ScheduleScreen(), db: db),
      );
      await tester.pump();
      expect(find.byType(ScheduleScreen), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Schedule app bar title', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ScheduleScreen(), db: db),
      );
      await tester.pump();
      expect(find.text('Schedule'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows Today button', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ScheduleScreen(), db: db),
      );
      await tester.pump();
      expect(find.text('Today'), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows FAB', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ScheduleScreen(), db: db),
      );
      await tester.pump();
      expect(find.byType(FloatingActionButton), findsOneWidget);
      await cleanupWidgetTest(tester);
    });

    testWidgets('shows date navigation arrows', (tester) async {
      await tester.pumpWidget(
        buildTestApp(screen: const ScheduleScreen(), db: db),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byIcon(Icons.chevron_left), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);
      await cleanupWidgetTest(tester);
    });
  });
}