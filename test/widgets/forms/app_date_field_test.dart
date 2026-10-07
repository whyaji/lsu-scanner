import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:sampletrack/widgets/forms/app_date_field.dart';
import 'package:sampletrack/widgets/forms/app_date_time_field.dart';

import '../../helpers/test_app.dart';

void main() {
  setUpAll(() => initializeDateFormatting('id'));

  testWidgets('formats the value in Indonesian', (tester) async {
    await tester.pumpWidget(
      testApp(
        AppDateField(
          label: 'Tanggal Terima',
          value: DateTime(2026, 10, 6),
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('6 Oktober 2026'), findsOneWidget);
  });

  testWidgets('picking confirms the clamped initial date', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      testApp(
        AppDateField(
          label: 'Estimasi KUPA',
          value: DateTime(2026, 10, 6),
          minDate: DateTime(2026, 10, 10),
          maxDate: DateTime(2026, 10, 20),
          onChanged: (d) => picked = d,
        ),
      ),
    );
    await tester.tap(find.text('6 Oktober 2026'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 10, 10));
    expect(find.text('Batal'), findsNothing);
  });

  testWidgets('disabled date field shows the reason and does not open', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        AppDateField(
          label: 'Estimasi KUPA',
          value: null,
          disabledReason: 'Isi Tanggal Terima dulu.',
          onChanged: (_) {},
        ),
      ),
    );
    expect(find.text('Isi Tanggal Terima dulu.'), findsOneWidget);
    await tester.tap(find.text('Pilih tanggal'));
    await tester.pumpAndSettle();
    expect(find.text('Pilih'), findsNothing);
  });

  testWidgets('date time field picks a date then a time', (tester) async {
    DateTime? picked;
    await tester.pumpWidget(
      testApp(
        AppDateTimeField(
          label: 'Tanggal Memo',
          value: DateTime(2026, 10, 6, 13, 30),
          onChanged: (d) => picked = d,
        ),
      ),
    );
    expect(find.text('6 Oktober 2026, 13:30'), findsOneWidget);

    await tester.tap(find.text('6 Oktober 2026, 13:30'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Lanjut pilih jam'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Pilih'));
    await tester.pumpAndSettle();

    expect(picked, DateTime(2026, 10, 6, 13, 30));
  });
}
