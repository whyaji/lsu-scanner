import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/core/theme/app_theme.dart';
import 'package:sampletrack/widgets/display/app_journey_track.dart';
import 'package:sampletrack/widgets/display/app_list_item.dart';
import 'package:sampletrack/widgets/display/app_status_chip.dart';
import 'package:sampletrack/widgets/feedback/app_notice_type.dart';

import '../../helpers/test_app.dart';

Widget _item() => AppListItem(
  title: 'Pupuk NPK Mutiara 16-16-16 dari Gudang Estate Sungai Rungau',
  subtitle: 'PT Supplier Pupuk Nusantara Kalimantan, kode sampel NPK-2026-000123',
  trailing: const AppStatusChip(
    label: 'Menunggu unggah',
    type: AppNoticeType.warning,
  ),
  journey: AppJourneyTrack.sample(completed: 3),
  onTap: () {},
);

void main() {
  for (final entry in {'light': AppTheme.light, 'dark': AppTheme.dark}.entries) {
    testWidgets('AppListItem has no overflow at 1.3 text scale (${entry.key})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          SingleChildScrollView(child: _item()),
          theme: entry.value,
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
      expect(
        tester.getSize(find.byType(AppListItem)).height,
        greaterThanOrEqualTo(64),
      );
    });

    testWidgets('AppJourneyTrack has no overflow at 1.3 text scale (${entry.key})', (
      tester,
    ) async {
      tester.view.physicalSize = const Size(320, 640);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);

      await tester.pumpWidget(
        testApp(
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AppJourneyTrack.sample(completed: 2),
                const SizedBox(height: 24),
                AppJourneyTrack.sample(completed: 3, showLabels: true),
                const SizedBox(height: 24),
                AppJourneyTrack.sample(completed: 4, hasError: true, showLabels: true),
              ],
            ),
          ),
          theme: entry.value,
          textScale: 1.3,
        ),
      );
      expect(tester.takeException(), isNull);
    });
  }

  testWidgets('AppJourneyTrack describes every stage for screen readers', (
    tester,
  ) async {
    final handle = tester.ensureSemantics();
    await tester.pumpWidget(testApp(AppJourneyTrack.sample(completed: 2)));

    final label = tester.getSemantics(find.byType(AppJourneyTrack)).label;
    expect(label, contains('Kirim Lab (3 dari 6)'));
    expect(label, contains('Gudang Estate selesai'));
    expect(label, contains('Kirim Lab sedang berjalan'));
    expect(label, contains('Sertifikat belum'));
    handle.dispose();
  });

  testWidgets('error stage is reported as a problem', (tester) async {
    final track = AppJourneyTrack.sample(completed: 3, hasError: true);
    expect(track.summary, 'Terima Lab bermasalah');
    expect(track.semanticLabel, contains('Terima Lab bermasalah'));
  });
}
