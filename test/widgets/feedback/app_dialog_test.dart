import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/widgets/feedback/app_dialog.dart';
import 'package:sampletrack/widgets/feedback/app_progress_handle.dart';

import '../../helpers/test_app.dart';

Widget _opener(Future<void> Function(BuildContext) open) {
  return Builder(
    builder: (context) =>
        TextButton(onPressed: () => open(context), child: const Text('buka')),
  );
}

Future<void> _open(WidgetTester tester) async {
  await tester.tap(find.text('buka'));
  await tester.pumpAndSettle();
}

void main() {
  group('AppDialog.confirm', () {
    testWidgets('returns true when the confirm button is tapped', (tester) async {
      bool? result;
      await tester.pumpWidget(
        testApp(
          _opener((c) async {
            result = await AppDialog.confirm(
              c,
              title: 'Simpan penerimaan?',
              confirmLabel: 'Simpan penerimaan',
            );
          }),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Simpan penerimaan'));
      await tester.pumpAndSettle();

      expect(result, isTrue);
      expect(find.text('Simpan penerimaan?'), findsNothing);
    });

    testWidgets('returns false on cancel, Back and Escape', (tester) async {
      final results = <bool>[];
      await tester.pumpWidget(
        testApp(
          _opener((c) async {
            results.add(
              await AppDialog.confirm(
                c,
                title: 'Hapus data?',
                confirmLabel: 'Hapus',
                tone: AppDialogTone.destructive,
              ),
            );
          }),
        ),
      );

      await _open(tester);
      await tester.tap(find.text('Batal'));
      await tester.pumpAndSettle();

      await _open(tester);
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      await _open(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.escape);
      await tester.pumpAndSettle();

      expect(results, [false, false, false]);
      expect(find.text('Hapus data?'), findsNothing);
    });

    testWidgets('stacks buttons with the primary on top on narrow screens', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          _opener((c) async {
            await AppDialog.confirm(
              c,
              title: 'Unggah 3 data?',
              confirmLabel: 'Unggah 3 data',
            );
          }),
        ),
      );
      await _open(tester);

      final primary = tester.getTopLeft(find.text('Unggah 3 data'));
      final cancel = tester.getTopLeft(find.text('Batal'));
      expect(primary.dy, lessThan(cancel.dy));
      expect(
        tester.getSize(find.widgetWithText(FilledButton, 'Unggah 3 data')).height,
        greaterThanOrEqualTo(48),
      );
    });
  });

  group('AppDialog.error', () {
    testWidgets('runs onRetry after closing when Coba lagi is tapped', (
      tester,
    ) async {
      var retries = 0;
      await tester.pumpWidget(
        testApp(
          _opener((c) async {
            await AppDialog.error(
              c,
              title: 'Unggah gagal',
              message: 'Jaringan terputus.',
              onRetry: () => retries++,
            );
          }),
        ),
      );
      await _open(tester);
      expect(find.text('Jaringan terputus.'), findsOneWidget);

      await tester.tap(find.text('Coba lagi'));
      await tester.pumpAndSettle();

      expect(retries, 1);
      expect(find.text('Unggah gagal'), findsNothing);
    });

    testWidgets('has no retry button without onRetry and Tutup does not retry', (
      tester,
    ) async {
      await tester.pumpWidget(
        testApp(
          _opener((c) async {
            await AppDialog.error(c, title: 'Data ditolak');
          }),
        ),
      );
      await _open(tester);
      expect(find.text('Coba lagi'), findsNothing);

      await tester.tap(find.text('Tutup'));
      await tester.pumpAndSettle();
      expect(find.text('Data ditolak'), findsNothing);
    });
  });

  group('AppDialog.choice', () {
    testWidgets('returns the value of the tapped option', (tester) async {
      String? result;
      await tester.pumpWidget(
        testApp(
          _opener((c) async {
            result = await AppDialog.choice<String>(
              c,
              title: 'Foto',
              choices: const [
                AppDialogChoice(label: 'Ambil foto', value: 'camera'),
                AppDialogChoice(label: 'Pilih dari galeri', value: 'gallery'),
                AppDialogChoice(label: 'Lewati', value: 'skip'),
              ],
            );
          }),
        ),
      );
      await _open(tester);
      await tester.tap(find.text('Pilih dari galeri'));
      await tester.pumpAndSettle();
      expect(result, 'gallery');
    });
  });

  group('AppDialog.progress', () {
    testWidgets('blocks Back, updates and closes through the handle', (
      tester,
    ) async {
      late AppProgressHandle handle;
      await tester.pumpWidget(
        testApp(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => handle = AppDialog.progress(
                context,
                message: 'Mengunggah 3 data',
              ),
              child: const Text('buka'),
            ),
          ),
        ),
      );
      await tester.tap(find.text('buka'));
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Mengunggah 3 data'), findsOneWidget);
      expect(find.byType(LinearProgressIndicator), findsOneWidget);

      await tester.binding.handlePopRoute();
      await tester.pump(const Duration(milliseconds: 400));
      expect(find.text('Mengunggah 3 data'), findsOneWidget);

      handle.update(message: 'Mengunggah foto', value: 0.5);
      await tester.pump();
      expect(find.text('Mengunggah foto'), findsOneWidget);
      expect(find.text('50%'), findsOneWidget);

      handle.close();
      await tester.pumpAndSettle();
      expect(find.text('Mengunggah foto'), findsNothing);
    });
  });
}


