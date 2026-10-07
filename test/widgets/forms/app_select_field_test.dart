import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/widgets/forms/app_select_field.dart';

import '../../helpers/test_app.dart';

const _many = [
  AppSelectOption(value: 1, label: 'Pupuk NPK'),
  AppSelectOption(value: 2, label: 'Pupuk Urea'),
  AppSelectOption(value: 3, label: 'Pupuk TSP'),
  AppSelectOption(value: 4, label: 'Pupuk KCl'),
  AppSelectOption(value: 5, label: 'Dolomit'),
  AppSelectOption(value: 6, label: 'Kieserit'),
  AppSelectOption(value: 7, label: 'Borax'),
  AppSelectOption(value: 8, label: 'Rock Phosphate'),
];

class _Host extends StatefulWidget {
  const _Host({required this.options, this.disabledReason});

  final List<AppSelectOption<int>> options;
  final String? disabledReason;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  int? value;

  @override
  Widget build(BuildContext context) => AppSelectField<int>(
    label: 'Jenis Pupuk',
    options: widget.options,
    value: value,
    disabledReason: widget.disabledReason,
    onChanged: (v) => setState(() => value = v),
  );
}

void main() {
  testWidgets('shows a search box above 7 options and filters by text', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const _Host(options: _many)));
    await tester.tap(find.text('Pilih salah satu'));
    await tester.pumpAndSettle();

    expect(find.text('Cari'), findsOneWidget);
    expect(find.text('Kieserit'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'pupuk u');
    await tester.pump();
    expect(find.text('Pupuk Urea'), findsOneWidget);
    expect(find.text('Kieserit'), findsNothing);

    await tester.enterText(find.byType(TextField), 'zzz');
    await tester.pump();
    expect(find.textContaining('Tidak ada pilihan'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'dolo');
    await tester.pump();
    await tester.tap(find.text('Dolomit'));
    await tester.pumpAndSettle();

    expect(find.text('Dolomit'), findsOneWidget);
    expect(find.text('Cari'), findsNothing);
  });

  testWidgets('has no search box at 7 options or fewer', (tester) async {
    await tester.pumpWidget(testApp(_Host(options: _many.take(7).toList())));
    await tester.tap(find.text('Pilih salah satu'));
    await tester.pumpAndSettle();

    expect(find.text('Cari'), findsNothing);
    expect(find.text('Borax'), findsOneWidget);
  });

  testWidgets('disabled field shows its reason and does not open', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(
        const _Host(
          options: _many,
          disabledReason: 'Pilih Jenis Komoditas dulu.',
        ),
      ),
    );
    expect(find.text('Pilih Jenis Komoditas dulu.'), findsOneWidget);

    await tester.tap(find.text('Pilih salah satu'));
    await tester.pumpAndSettle();
    expect(find.text('Pupuk NPK'), findsNothing);
  });

  testWidgets('validator error shows under the field', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      testApp(
        Form(
          key: formKey,
          child: AppSelectField<int>(
            label: 'Status Pengerjaan',
            options: _many,
            value: null,
            onChanged: (_) {},
            validator: (v) => v == null ? 'Pilih status pengerjaan.' : null,
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Pilih status pengerjaan.'), findsOneWidget);
  });
}
