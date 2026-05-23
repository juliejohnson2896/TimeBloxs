import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import 'dart:io';
import 'core/theme/app_theme.dart';
import 'core/services/pocketbase_service.dart';
import 'core/services/auth_notifier.dart';
import 'core/router/app_router.dart';
import 'core/database/app_database.dart';
import 'features/settings/providers/settings_providers.dart';

// ignore: depend_on_referenced_packages
import 'package:window_manager/window_manager.dart';

final pocketBaseServiceProvider = Provider<PocketBaseService>((ref) {
  return PocketBaseService();
});

final authChangeNotifierProvider = Provider<AuthChangeNotifier>((ref) {
  final pbService = ref.watch(pocketBaseServiceProvider);
  return AuthChangeNotifier(pbService);
});

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(() => db.close());
  return db;
});

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Desktop window setup
  if (!kIsWeb && (Platform.isWindows || Platform.isMacOS || Platform.isLinux)) {
    await windowManager.ensureInitialized();
    WindowOptions windowOptions = const WindowOptions(
      minimumSize: Size(400, 600),
      size: Size(420, 800),
      center: true,
      title: 'Timebloxs',
    );
    await windowManager.waitUntilReadyToShow(windowOptions, () async {
      await windowManager.show();
      await windowManager.focus();
    });
  }

  runApp(const ProviderScope(child: TimebloxsApp()));
}

class TimebloxsApp extends ConsumerWidget {
  const TimebloxsApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);
    final accentColor = ref.watch(accentColorProvider);

    return MaterialApp.router(
      title: 'Timebloxs',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.buildTheme(accentColor),
      routerConfig: router,
    );
  }
}