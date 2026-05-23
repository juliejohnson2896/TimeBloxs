import 'package:drift/native.dart';
import 'package:timebloxs/core/database/app_database.dart';

/// Creates an in-memory database for testing.
/// Each test gets a fresh database with seeded system data.
AppDatabase createTestDatabase() {
  return AppDatabase.forTesting(NativeDatabase.memory());
}