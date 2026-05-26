import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/utils/snackbar_helper.dart';

void main() {
  group('SnackbarHelper', () {
    testWidgets('showError displays a snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => SnackbarHelper.showError(
                  context,
                  'Test error message',
                ),
                child: const Text('Show Error'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Error'));
      await tester.pump();

      expect(find.text('Test error message'), findsOneWidget);
    });

    testWidgets('showSuccess displays a snackbar', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () => SnackbarHelper.showSuccess(
                  context,
                  'Test success message',
                ),
                child: const Text('Show Success'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Show Success'));
      await tester.pump();

      expect(find.text('Test success message'), findsOneWidget);
    });

    testWidgets('showError does not throw when context is not mounted',
            (tester) async {
          BuildContext? capturedContext;

          await tester.pumpWidget(
            MaterialApp(
              home: Builder(
                builder: (context) {
                  capturedContext = context;
                  return const Scaffold(body: SizedBox());
                },
              ),
            ),
          );

          // Navigate away to unmount the context
          await tester.pumpWidget(const MaterialApp(
            home: Scaffold(body: SizedBox()),
          ));

          // Should not throw even with potentially stale context
          expect(
                () => SnackbarHelper.showError(
              capturedContext!,
              'Should not crash',
            ),
            returnsNormally,
          );
        });
  });
}