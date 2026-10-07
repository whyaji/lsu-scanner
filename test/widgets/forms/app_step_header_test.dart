import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/widgets/forms/app_step_header.dart';

import '../../helpers/test_app.dart';

const _labels = [
  'Sampel',
  'Informasi Sampel',
  'Pengirim dan Kontak',
  'Parameter Uji',
  'Ringkasan dan Foto',
];

void main() {
  testWidgets('shows the current label and not a step counter', (tester) async {
    await tester.pumpWidget(
      testApp(const AppStepHeader(currentStep: 2, stepLabels: _labels)),
    );
    expect(find.text('Langkah 2 dari 5'), findsNothing);
    expect(find.text('Informasi Sampel'), findsOneWidget);
  });

  testWidgets('only finished steps are tappable and report their number', (
    tester,
  ) async {
    final taps = <int>[];
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        AppStepHeader(currentStep: 3, stepLabels: _labels, onStepTap: taps.add),
      ),
    );

    expect(
      find.bySemanticsLabel('Kembali ke langkah 1: Sampel'),
      findsOneWidget,
    );
    expect(
      find.bySemanticsLabel('Kembali ke langkah 2: Informasi Sampel'),
      findsOneWidget,
    );
    expect(find.bySemanticsLabel(RegExp('Kembali ke langkah 3')), findsNothing);
    expect(find.bySemanticsLabel(RegExp('Kembali ke langkah 4')), findsNothing);

    await tester.tap(
      find.bySemanticsLabel('Kembali ke langkah 2: Informasi Sampel'),
    );
    await tester.pump();
    expect(taps, [2]);
    handle.dispose();
  });

  testWidgets('segments are 48dp tall tap targets', (tester) async {
    await tester.pumpWidget(
      testApp(
        AppStepHeader(currentStep: 2, stepLabels: _labels, onStepTap: (_) {}),
      ),
    );
    final inkWell = find.byType(InkWell);
    expect(inkWell, findsOneWidget);
    expect(tester.getSize(inkWell).height, greaterThanOrEqualTo(48));
  });
}
