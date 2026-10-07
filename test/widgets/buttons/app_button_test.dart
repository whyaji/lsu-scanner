import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/widgets/buttons/app_button.dart';
import 'package:sampletrack/widgets/buttons/app_icon_button.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('loading keeps the resting size and blocks taps', (tester) async {
    var taps = 0;
    Widget build({required bool loading}) => testApp(
      Center(
        child: AppButton(
          label: 'Simpan penerimaan',
          icon: Icons.save_outlined,
          loading: loading,
          onPressed: () => taps++,
        ),
      ),
    );

    await tester.pumpWidget(build(loading: false));
    final resting = tester.getSize(find.byType(AppButton));
    await tester.tap(find.byType(AppButton));
    expect(taps, 1);

    await tester.pumpWidget(build(loading: true));
    expect(tester.getSize(find.byType(AppButton)), resting);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.tap(find.byType(AppButton), warnIfMissed: false);
    expect(taps, 1);
  });

  testWidgets('loading announces itself to screen readers', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        AppButton(label: 'Unggah 3 data', loading: true, onPressed: () {}),
      ),
    );
    expect(
      find.bySemanticsLabel('Unggah 3 data, sedang diproses'),
      findsOneWidget,
    );
    handle.dispose();
  });

  testWidgets('every variant is at least 48dp high in both sizes', (tester) async {
    for (final size in AppButtonSize.values) {
      for (final variant in AppButtonVariant.values) {
        await tester.pumpWidget(
          testApp(
            Center(
              child: AppButton(
                label: 'Aksi',
                variant: variant,
                size: size,
                onPressed: () {},
              ),
            ),
          ),
        );
        expect(
          tester.getSize(find.byType(AppButton)).height,
          greaterThanOrEqualTo(48),
          reason: '$variant $size',
        );
      }
    }
  });

  testWidgets('fullWidth fills the parent width', (tester) async {
    await tester.pumpWidget(
      testApp(
        Column(
          children: [
            AppButton(label: 'Lanjut', fullWidth: true, onPressed: () {}),
          ],
        ),
      ),
    );
    expect(
      tester.getSize(find.byType(AppButton)).width,
      tester.getSize(find.byType(Scaffold)).width,
    );
  });

  testWidgets('icon button has a 48dp target and its tooltip', (tester) async {
    await tester.pumpWidget(
      testApp(
        Center(
          child: AppIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Hapus foto',
            onPressed: () {},
          ),
        ),
      ),
    );
    final size = tester.getSize(find.byType(IconButton));
    expect(size.width, greaterThanOrEqualTo(48));
    expect(size.height, greaterThanOrEqualTo(48));
    expect(find.byTooltip('Hapus foto'), findsOneWidget);
  });
}
