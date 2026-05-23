import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Parses a hex color string to a Color.
/// Accepts formats: '#RRGGBB' or 'RRGGBB'
/// Falls back to the app's primary color if parsing fails.
Color parseColor(String? hex, {Color? fallback}) {
  if (hex == null || hex.isEmpty) {
    return fallback ?? AppTheme.primary;
  }
  try {
    return Color(int.parse(hex.replaceFirst('#', '0xFF')));
  } catch (_) {
    return fallback ?? AppTheme.primary;
  }
}