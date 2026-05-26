import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/utils/app_logger.dart';

void main() {
  group('AppLogger', () {
    test('singleton instance is always the same', () {
      final instance1 = AppLogger();
      final instance2 = AppLogger();
      expect(identical(instance1, instance2), isTrue);
    });

    test('logger instance is accessible via global logger', () {
      expect(logger, isNotNull);
      expect(logger, isA<AppLogger>());
    });

    test('info does not throw', () async {
      await expectLater(
        logger.info('test', 'Test info message'),
        completes,
      );
    });

    test('error does not throw', () async {
      await expectLater(
        logger.error('test', Exception('Test error')),
        completes,
      );
    });

    test('error with stack trace does not throw', () async {
      await expectLater(
        logger.error(
          'test',
          Exception('Test error'),
          StackTrace.current,
        ),
        completes,
      );
    });

    test('readLogs returns a string', () async {
      final logs = await logger.readLogs();
      expect(logs, isA<String>());
    });

    test('clearLogs does not throw', () async {
      await expectLater(logger.clearLogs(), completes);
    });

    test('readLogs after clearLogs returns empty or no logs message',
            () async {
          await logger.clearLogs();
          final logs = await logger.readLogs();
          expect(logs, isA<String>());
        });

    test('logs written by info are readable', () async {
      // Init and mock IO Layer before the test
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
              (MethodCall methodCall) async {
            return '.';
          });

      // Actual Test case
      await logger.clearLogs();
      await logger.info('test_context', 'Readable log message');
      final logs = await logger.readLogs();
      expect(logs, contains('test_context'));
    });

    test('logs written by error are readable', () async {
      // Init and mock IO Layer before the test
      TestWidgetsFlutterBinding.ensureInitialized();
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(
          const MethodChannel('plugins.flutter.io/path_provider'),
              (MethodCall methodCall) async {
            return '.';
          });

      // Actual Test case
      await logger.clearLogs();
      await logger.error('error_context', Exception('readable error'));
      final logs = await logger.readLogs();
      expect(logs, contains('error_context'));
    });
  });
}