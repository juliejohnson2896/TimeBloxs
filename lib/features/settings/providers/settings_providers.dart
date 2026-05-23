import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/services/settings_service.dart';

final settingsServiceProvider = Provider<SettingsService>((ref) {
  return SettingsService();
});

// Accent colour provider
final accentColorProvider =
StateNotifierProvider<AccentColorNotifier, Color>((ref) {
  return AccentColorNotifier(ref.watch(settingsServiceProvider));
});

class AccentColorNotifier extends StateNotifier<Color> {
  final SettingsService _service;

  AccentColorNotifier(this._service)
      : super(const Color(SettingsService.defaultAccentColor)) {
    _load();
  }

  Future<void> _load() async {
    final value = await _service.getAccentColor();
    state = Color(value);
  }

  Future<void> setColor(Color color) async {
    state = color;
    await _service.setAccentColor(color.value);
  }
}

// Day window providers
final dayStartTimeProvider =
StateNotifierProvider<DayTimeNotifier, String>((ref) {
  return DayTimeNotifier(
    ref.watch(settingsServiceProvider),
    isStart: true,
  );
});

final dayEndTimeProvider =
StateNotifierProvider<DayTimeNotifier, String>((ref) {
  return DayTimeNotifier(
    ref.watch(settingsServiceProvider),
    isStart: false,
  );
});

class DayTimeNotifier extends StateNotifier<String> {
  final SettingsService _service;
  final bool isStart;

  DayTimeNotifier(this._service, {required this.isStart})
      : super(isStart
      ? SettingsService.defaultDayStart
      : SettingsService.defaultDayEnd) {
    _load();
  }

  Future<void> _load() async {
    state = isStart
        ? await _service.getDayStartTime()
        : await _service.getDayEndTime();
  }

  Future<void> setTime(String time) async {
    state = time;
    if (isStart) {
      await _service.setDayStartTime(time);
    } else {
      await _service.setDayEndTime(time);
    }
  }
}

// Available accent colours
const List<Color> accentColorOptions = [
  Color(0xFF6C63FF), // Purple (default)
  Color(0xFF2196F3), // Blue
  Color(0xFF00BCD4), // Cyan
  Color(0xFF4CAF50), // Green
  Color(0xFFFF9800), // Orange
  Color(0xFFF44336), // Red
  Color(0xFFE91E63), // Pink
  Color(0xFF9C27B0), // Deep Purple
  Color(0xFF607D8B), // Blue Grey
  Color(0xFFFFEB3B), // Yellow
];