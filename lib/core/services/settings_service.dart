import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timebloxs/core/theme/app_theme.dart';

class SettingsService {
  static const String _dayStartKey = 'day_start_time';
  static const String _dayEndKey = 'day_end_time';
  static const String _accentColorKey = 'accent_color';

  // Defaults
  static const String defaultDayStart = '09:00';
  static const String defaultDayEnd = '17:00';
  static const int defaultAccentColor = 0xFF6C63FF; // AppTheme.primary

  Future<String> getDayStartTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dayStartKey) ?? defaultDayStart;
  }

  Future<void> setDayStartTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayStartKey, time);
  }

  Future<String> getDayEndTime() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_dayEndKey) ?? defaultDayEnd;
  }

  Future<void> setDayEndTime(String time) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dayEndKey, time);
  }

  Future<int> getAccentColor() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_accentColorKey) ?? defaultAccentColor;
  }

  Future<void> setAccentColor(int colorValue) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, colorValue);
  }
}