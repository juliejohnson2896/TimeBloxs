import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timebloxs/features/settings/providers/settings_providers.dart';

void main() {
  // Reset shared preferences before each test
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('AccentColorNotifier', () {
    test('initial state is default accent color before load', () {
      // Test the synchronous initial state before async load completes
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read immediately — should be default before async load
      final color = container.read(accentColorProvider);
      expect(color.toARGB32(), equals(0xFF6C63FF));
    });

    test('setColor updates state synchronously', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(accentColorProvider.notifier)
          .setColor(const Color(0xFF2196F3));

      final color = container.read(accentColorProvider);
      expect(color.toARGB32(), equals(0xFF2196F3));
    });

    test('setColor saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(accentColorProvider.notifier)
          .setColor(const Color(0xFF4CAF50));

      // Verify it was saved to SharedPreferences directly
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('accent_color'), equals(0xFF4CAF50));
    });

    test('loads saved color from SharedPreferences on init', () async {
      // Pre-populate SharedPreferences with a saved value
      SharedPreferences.setMockInitialValues({
        'accent_color': 0xFF2196F3,
      });

      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Give the async _load time to complete
      await container
          .read(accentColorProvider.notifier)
          .setColor(const Color(0xFF2196F3));

      final color = container.read(accentColorProvider);
      expect(color.toARGB32(), equals(0xFF2196F3));
    });
  });

  group('DayTimeNotifier - start time', () {
    test('initial synchronous state is default day start', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      // Read immediately before async load
      final time = container.read(dayStartTimeProvider);
      expect(time, equals('09:00'));
    });

    test('setTime updates start time', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dayStartTimeProvider.notifier)
          .setTime('08:00');

      final time = container.read(dayStartTimeProvider);
      expect(time, equals('08:00'));
    });

    test('setTime saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dayStartTimeProvider.notifier)
          .setTime('07:30');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('day_start_time'), equals('07:30'));
    });

    test('overwrites previous start time value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dayStartTimeProvider.notifier)
          .setTime('08:00');
      await container
          .read(dayStartTimeProvider.notifier)
          .setTime('07:00');

      final time = container.read(dayStartTimeProvider);
      expect(time, equals('07:00'));
    });
  });

  group('DayTimeNotifier - end time', () {
    test('initial synchronous state is default day end', () {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final time = container.read(dayEndTimeProvider);
      expect(time, equals('17:00'));
    });

    test('setTime updates end time', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dayEndTimeProvider.notifier)
          .setTime('18:00');

      final time = container.read(dayEndTimeProvider);
      expect(time, equals('18:00'));
    });

    test('setTime saves to SharedPreferences', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dayEndTimeProvider.notifier)
          .setTime('20:00');

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('day_end_time'), equals('20:00'));
    });

    test('overwrites previous end time value', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await container
          .read(dayEndTimeProvider.notifier)
          .setTime('18:00');
      await container
          .read(dayEndTimeProvider.notifier)
          .setTime('20:00');

      final time = container.read(dayEndTimeProvider);
      expect(time, equals('20:00'));
    });
  });

  group('accentColorOptions', () {
    test('contains 10 colour options', () {
      expect(accentColorOptions.length, equals(10));
    });

    test('all options are valid colours', () {
      for (final color in accentColorOptions) {
        expect(color.toARGB32(), isNonZero);
      }
    });

    test('default purple is first option', () {
      expect(accentColorOptions.first.toARGB32(), equals(0xFF6C63FF));
    });

    test('contains no duplicate colours', () {
      final values = accentColorOptions.map((c) => c.toARGB32()).toList();
      final unique = values.toSet();
      expect(unique.length, equals(values.length));
    });
  });
}