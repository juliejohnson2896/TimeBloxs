import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timebloxs/core/services/settings_service.dart';

void main() {
  setUp(() {
    // Use mock shared preferences for tests
    SharedPreferences.setMockInitialValues({});
  });

  group('SettingsService', () {
    late SettingsService service;

    setUp(() {
      service = SettingsService();
    });

    group('day start time', () {
      test('returns default when not set', () async {
        final time = await service.getDayStartTime();
        expect(time, equals(SettingsService.defaultDayStart));
      });

      test('returns saved value after set', () async {
        await service.setDayStartTime('08:00');
        final time = await service.getDayStartTime();
        expect(time, equals('08:00'));
      });

      test('overwrites previous value', () async {
        await service.setDayStartTime('08:00');
        await service.setDayStartTime('07:30');
        final time = await service.getDayStartTime();
        expect(time, equals('07:30'));
      });
    });

    group('day end time', () {
      test('returns default when not set', () async {
        final time = await service.getDayEndTime();
        expect(time, equals(SettingsService.defaultDayEnd));
      });

      test('returns saved value after set', () async {
        await service.setDayEndTime('18:00');
        final time = await service.getDayEndTime();
        expect(time, equals('18:00'));
      });

      test('overwrites previous value', () async {
        await service.setDayEndTime('18:00');
        await service.setDayEndTime('20:00');
        final time = await service.getDayEndTime();
        expect(time, equals('20:00'));
      });
    });

    group('accent color', () {
      test('returns default when not set', () async {
        final color = await service.getAccentColor();
        expect(color, equals(SettingsService.defaultAccentColor));
      });

      test('returns saved value after set', () async {
        await service.setAccentColor(0xFF2196F3);
        final color = await service.getAccentColor();
        expect(color, equals(0xFF2196F3));
      });

      test('overwrites previous value', () async {
        await service.setAccentColor(0xFF2196F3);
        await service.setAccentColor(0xFF4CAF50);
        final color = await service.getAccentColor();
        expect(color, equals(0xFF4CAF50));
      });

      test('stores and retrieves all accent color options', () async {
        const testColors = [
          0xFF6C63FF,
          0xFF2196F3,
          0xFF00BCD4,
          0xFF4CAF50,
          0xFFFF9800,
        ];

        for (final colorValue in testColors) {
          await service.setAccentColor(colorValue);
          final retrieved = await service.getAccentColor();
          expect(retrieved, equals(colorValue),
              reason: 'Failed for color: $colorValue');
        }
      });
    });

    group('default values', () {
      test('defaultDayStart is 09:00', () {
        expect(SettingsService.defaultDayStart, equals('09:00'));
      });

      test('defaultDayEnd is 17:00', () {
        expect(SettingsService.defaultDayEnd, equals('17:00'));
      });

      test('defaultAccentColor matches app primary', () {
        expect(SettingsService.defaultAccentColor, equals(0xFF6C63FF));
      });
    });
  });
}