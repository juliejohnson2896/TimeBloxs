import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/utils/error_messages.dart';

void main() {
  group('ErrorMessages', () {
    group('schedule messages', () {
      test('createBlockFailed is not empty', () {
        expect(ErrorMessages.createBlockFailed, isNotEmpty);
      });

      test('updateBlockFailed is not empty', () {
        expect(ErrorMessages.updateBlockFailed, isNotEmpty);
      });

      test('deleteBlockFailed is not empty', () {
        expect(ErrorMessages.deleteBlockFailed, isNotEmpty);
      });

      test('assignTaskFailed is not empty', () {
        expect(ErrorMessages.assignTaskFailed, isNotEmpty);
      });
    });

    group('task messages', () {
      test('createTaskFailed is not empty', () {
        expect(ErrorMessages.createTaskFailed, isNotEmpty);
      });

      test('updateTaskFailed is not empty', () {
        expect(ErrorMessages.updateTaskFailed, isNotEmpty);
      });

      test('deleteTaskFailed is not empty', () {
        expect(ErrorMessages.deleteTaskFailed, isNotEmpty);
      });

      test('archiveTaskFailed is not empty', () {
        expect(ErrorMessages.archiveTaskFailed, isNotEmpty);
      });

      test('loadTasksFailed is not empty', () {
        expect(ErrorMessages.loadTasksFailed, isNotEmpty);
      });
    });

    group('project messages', () {
      test('createProjectFailed is not empty', () {
        expect(ErrorMessages.createProjectFailed, isNotEmpty);
      });

      test('updateProjectFailed is not empty', () {
        expect(ErrorMessages.updateProjectFailed, isNotEmpty);
      });

      test('deleteProjectFailed is not empty', () {
        expect(ErrorMessages.deleteProjectFailed, isNotEmpty);
      });
    });

    group('general messages', () {
      test('genericFailed is not empty', () {
        expect(ErrorMessages.genericFailed, isNotEmpty);
      });

      test('loadFailed is not empty', () {
        expect(ErrorMessages.loadFailed, isNotEmpty);
      });
    });

    group('message content', () {
      test('all messages are user friendly strings without stack traces',
              () {
            final messages = [
              ErrorMessages.createBlockFailed,
              ErrorMessages.updateBlockFailed,
              ErrorMessages.deleteBlockFailed,
              ErrorMessages.assignTaskFailed,
              ErrorMessages.createTaskFailed,
              ErrorMessages.updateTaskFailed,
              ErrorMessages.deleteTaskFailed,
              ErrorMessages.archiveTaskFailed,
              ErrorMessages.createProjectFailed,
              ErrorMessages.updateProjectFailed,
              ErrorMessages.deleteProjectFailed,
              ErrorMessages.genericFailed,
              ErrorMessages.loadFailed,
            ];

            for (final message in messages) {
              expect(message, isNotEmpty,
                  reason: 'Message should not be empty');
              expect(message, isNot(contains('Exception')),
                  reason: 'Message should not expose exception details');
              expect(message, isNot(contains('Stack')),
                  reason: 'Message should not expose stack traces');
            }
          });

      test('messages end with a period', () {
        final messages = [
          ErrorMessages.createBlockFailed,
          ErrorMessages.updateBlockFailed,
          ErrorMessages.deleteBlockFailed,
          ErrorMessages.createTaskFailed,
          ErrorMessages.createProjectFailed,
          ErrorMessages.genericFailed,
        ];

        for (final message in messages) {
          expect(message.endsWith('.'), isTrue,
              reason: '"$message" should end with a period');
        }
      });
    });
  });
}