import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/theme/app_semantic_colors.dart';
import 'package:sampletrack/core/theme/app_theme.dart';

double _channel(double c) =>
    c <= 0.03928 ? c / 12.92 : math.pow((c + 0.055) / 1.055, 2.4).toDouble();

double _luminance(Color c) =>
    0.2126 * _channel(c.r) + 0.7152 * _channel(c.g) + 0.0722 * _channel(c.b);

double _ratio(Color a, Color b) {
  final la = _luminance(a);
  final lb = _luminance(b);
  return (math.max(la, lb) + 0.05) / (math.min(la, lb) + 0.05);
}

void main() {
  for (final entry in {
    'light': AppTheme.light,
    'dark': AppTheme.dark,
  }.entries) {
    group('semantic colors (${entry.key})', () {
      final theme = entry.value;
      final scheme = theme.colorScheme;
      final colors = theme.extension<AppSemanticColors>()!;
      final all = {
        'success': colors.success,
        'info': colors.info,
        'warning': colors.warning,
        'error': colors.error,
      };

      for (final e in all.entries) {
        test('${e.key}: onContainer text on container is at least 4.5:1', () {
          expect(
            _ratio(e.value.onContainer, e.value.container),
            greaterThanOrEqualTo(4.5),
          );
        });
        test('${e.key}: icon accent on container is at least 3:1', () {
          expect(
            _ratio(e.value.accent, e.value.container),
            greaterThanOrEqualTo(3),
          );
        });
        test('${e.key}: accent text on the page surface is at least 4.5:1', () {
          expect(
            _ratio(e.value.accent, scheme.surface),
            greaterThanOrEqualTo(4.5),
          );
          expect(
            _ratio(e.value.accent, theme.scaffoldBackgroundColor),
            greaterThanOrEqualTo(4.5),
          );
        });
      }

      test('primary button label is at least 4.5:1', () {
        expect(
          _ratio(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
      });
      test('field outline against surface is at least 3:1', () {
        expect(_ratio(scheme.outline, scheme.surface), greaterThanOrEqualTo(3));
      });
      test('tonal button label is at least 4.5:1', () {
        expect(
          _ratio(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      });
    });
  }
}
