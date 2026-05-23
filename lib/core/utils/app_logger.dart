import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class AppLogger {
  static final AppLogger _instance = AppLogger._internal();
  factory AppLogger() => _instance;
  AppLogger._internal();

  File? _logFile;

  Future<void> _init() async {
    if (_logFile != null) return;
    final dir = await getApplicationDocumentsDirectory();
    _logFile = File(p.join(dir.path, 'timebloxs.log'));
  }

  Future<void> error(String context, Object error, [StackTrace? stack]) async {
    final message =
        '[${DateTime.now().toIso8601String()}] ERROR [$context]: $error\n'
        '${stack != null ? '$stack\n' : ''}';

    // Always print in debug mode
    if (kDebugMode) print(message);

    // Write to log file
    try {
      await _init();
      await _logFile!.writeAsString(message, mode: FileMode.append);
    } catch (_) {
      // Logging should never crash the app
    }
  }

  Future<void> info(String context, String message) async {
    final entry =
        '[${DateTime.now().toIso8601String()}] INFO [$context]: $message\n';

    if (kDebugMode) print(entry);

    try {
      await _init();
      await _logFile!.writeAsString(entry, mode: FileMode.append);
    } catch (_) {}
  }

  Future<void> debug(String context, String message) async {
    final entry =
        '[${DateTime.now().toIso8601String()}] DEBUG [$context]: $message\n';

    if (kDebugMode) print(entry);

    try {
      await _init();
      await _logFile!.writeAsString(entry, mode: FileMode.append);
    } catch (_) {}
  }

  Future<String> readLogs() async {
    try {
      await _init();
      if (await _logFile!.exists()) {
        return await _logFile!.readAsString();
      }
    } catch (_) {}
    return 'No logs found';
  }

  Future<void> clearLogs() async {
    try {
      await _init();
      if (await _logFile!.exists()) {
        await _logFile!.writeAsString('');
      }
    } catch (_) {}
  }
}

final logger = AppLogger();