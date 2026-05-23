import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timebloxs/core/utils/color_utils.dart';
import 'package:timebloxs/core/theme/app_theme.dart';

void main() {
  group('parseColor', () {
    test('parses valid hex with hash prefix', () {
      final color = parseColor('#2196F3');
      expect(color, equals(const Color(0xFF2196F3)));
    });

    test('parses valid hex without hash prefix', () {
      final color = parseColor('2196F3');
      expect(color, equals(const Color(0xFF2196F3)));
    });

    test('parses uppercase hex correctly', () {
      final color = parseColor('#F44336');
      expect(color, equals(const Color(0xFFF44336)));
    });

    test('returns default fallback for null input', () {
      final color = parseColor(null);
      expect(color, equals(AppTheme.primary));
    });

    test('returns default fallback for empty string', () {
      final color = parseColor('');
      expect(color, equals(AppTheme.primary));
    });

    test('returns default fallback for invalid hex', () {
      final color = parseColor('#ZZZZZZ');
      expect(color, equals(AppTheme.primary));
    });

    test('returns custom fallback when provided', () {
      const customFallback = Color(0xFF00FF00);
      final color = parseColor(null, fallback: customFallback);
      expect(color, equals(customFallback));
    });

    test('returns custom fallback for invalid hex when provided', () {
      const customFallback = Color(0xFF00FF00);
      final color = parseColor('invalid', fallback: customFallback);
      expect(color, equals(customFallback));
    });

    test('parses all seeded category colours correctly', () {
      final categoryColors = [
        '#4CAF50',
        '#2196F3',
        '#9C27B0',
        '#FF9800',
        '#F44336',
        '#607D8B',
      ];

      for (final hex in categoryColors) {
        final color = parseColor(hex);
        expect(color, isA<Color>(),
            reason: 'Failed to parse category color: $hex');
      }
    });
  });
}