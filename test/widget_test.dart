import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/theme/app_semantic_colors.dart';
import 'package:sampletrack/core/theme/app_theme.dart';

void main() {
  test('both themes register the semantic color extension', () {
    expect(AppTheme.light.extension<AppSemanticColors>(), same(AppSemanticColors.light));
    expect(AppTheme.dark.extension<AppSemanticColors>(), same(AppSemanticColors.dark));
  });

  testWidgets('AppSemanticColors.of follows the active theme', (tester) async {
    late AppSemanticColors seen;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.dark,
        home: Builder(
          builder: (context) {
            seen = AppSemanticColors.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    expect(seen, same(AppSemanticColors.dark));
  });
}
