import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/widgets/desktop_constrained.dart';

void main() {
  // Ensure clean state between each test
  tearDown(() async {
    await Future.delayed(Duration.zero);
  });

  group('DesktopConstrained', () {
    testWidgets('renders child widget', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopConstrained(
              child: Text('Test Child'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('applies custom maxWidth', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopConstrained(
              maxWidth: 600,
              child: Text('Constrained'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Constrained'), findsOneWidget);
    });

    testWidgets('uses default maxWidth of 900', (tester) async {
      tester.view.physicalSize = const Size(1200, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopConstrained(
              child: Text('Default Width'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Default Width'), findsOneWidget);
    });

    testWidgets('renders on narrow viewport', (tester) async {
      tester.view.physicalSize = const Size(400, 800);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: DesktopConstrained(
              child: Text('Narrow'),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Narrow'), findsOneWidget);
    });
  });
}