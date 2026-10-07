import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/theme/app_theme.dart';
import 'package:sampletrack/widgets/feedback/app_banner.dart';
import 'package:sampletrack/widgets/feedback/app_notice_type.dart';

import '../../helpers/test_app.dart';

void main() {
  testWidgets('is a live region that reads its type and message', (tester) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(
      testApp(
        const AppBanner(
          type: AppNoticeType.warning,
          title: 'Data belum lengkap',
          message: 'Lengkapi Jenis Pupuk sebelum lanjut.',
        ),
      ),
    );

    final node = tester.getSemantics(find.byType(AppBanner));
    expect(node.flagsCollection.isLiveRegion, isTrue);
    expect(node.label, contains('Peringatan'));
    expect(node.label, contains('Data belum lengkap'));
    expect(node.label, contains('Lengkapi Jenis Pupuk sebelum lanjut.'));
    handle.dispose();
  });

  testWidgets('dismiss and action callbacks fire', (tester) async {
    var dismissed = 0;
    var acted = 0;
    await tester.pumpWidget(
      testApp(
        AppBanner(
          type: AppNoticeType.error,
          message: 'Sinkronisasi gagal.',
          actionLabel: 'Coba sinkron lagi',
          onAction: () => acted++,
          onDismiss: () => dismissed++,
        ),
      ),
    );

    await tester.tap(find.text('Coba sinkron lagi'));
    await tester.tap(find.byTooltip('Tutup pemberitahuan'));
    expect(acted, 1);
    expect(dismissed, 1);
  });

  testWidgets('has no dismiss button without onDismiss', (tester) async {
    await tester.pumpWidget(
      testApp(
        const AppBanner(type: AppNoticeType.info, message: 'Mode offline.'),
      ),
    );
    expect(find.byTooltip('Tutup pemberitahuan'), findsNothing);
  });

  testWidgets('fits a 320 wide screen at 1.3 text scale in the dark theme', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);

    await tester.pumpWidget(
      testApp(
        AppBanner(
          type: AppNoticeType.success,
          title: 'Penerimaan tersimpan',
          message:
              'Data disimpan di perangkat dan akan diunggah saat sinyal tersedia.',
          actionLabel: 'Lihat daftar',
          onAction: () {},
          onDismiss: () {},
        ),
        theme: AppTheme.dark,
        textScale: 1.3,
      ),
    );
    expect(tester.takeException(), isNull);
  });
}
