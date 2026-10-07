import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/widgets/forms/app_tag_input.dart';

import '../../helpers/test_app.dart';

String? _email(String v) => RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(v)
    ? null
    : '"$v" bukan email yang valid.';

class _Host extends StatefulWidget {
  const _Host({this.initial = const [], this.suggestions = const []});

  final List<String> initial;
  final List<String> suggestions;

  @override
  State<_Host> createState() => _HostState();
}

class _HostState extends State<_Host> {
  late List<String> values = widget.initial;

  @override
  Widget build(BuildContext context) => Column(
    children: [
      AppTagInput(
        label: 'Email penerima',
        values: values,
        suggestions: widget.suggestions,
        itemValidator: _email,
        onChanged: (v) => setState(() => values = v),
      ),
      Text('jumlah: ${values.length}'),
    ],
  );
}

Future<void> _type(WidgetTester tester, String text) async {
  await tester.enterText(find.byType(TextField), text);
  await tester.testTextInput.receiveAction(TextInputAction.done);
  await tester.pump();
}

void main() {
  testWidgets('adds a valid value as a chip on submit and clears the field', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const _Host()));
    await _type(tester, 'ani@lab.co.id');

    expect(find.widgetWithText(InputChip, 'ani@lab.co.id'), findsOneWidget);
    expect(find.text('jumlah: 1'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      '',
    );
  });

  testWidgets('comma commits the text', (tester) async {
    await tester.pumpWidget(testApp(const _Host()));
    await tester.enterText(find.byType(TextField), 'budi@lab.co.id,');
    await tester.pump();

    expect(find.widgetWithText(InputChip, 'budi@lab.co.id'), findsOneWidget);
  });

  testWidgets('rejects an invalid value, keeps the text and shows the error', (
    tester,
  ) async {
    await tester.pumpWidget(testApp(const _Host()));
    await _type(tester, 'bukan-email');

    expect(find.byType(InputChip), findsNothing);
    expect(find.text('"bukan-email" bukan email yang valid.'), findsOneWidget);
    expect(
      tester.widget<TextField>(find.byType(TextField)).controller!.text,
      'bukan-email',
    );

    await tester.enterText(find.byType(TextField), 'bukan-email2');
    await tester.pump();
    expect(find.textContaining('bukan email yang valid'), findsNothing);
  });

  testWidgets('rejects a duplicate ignoring case', (tester) async {
    await tester.pumpWidget(testApp(const _Host(initial: ['ani@lab.co.id'])));
    await _type(tester, 'ANI@lab.co.id');

    expect(find.byType(InputChip), findsOneWidget);
    expect(find.textContaining('sudah ditambahkan'), findsOneWidget);
  });

  testWidgets('removes a chip with its delete button', (tester) async {
    await tester.pumpWidget(
      testApp(const _Host(initial: ['ani@lab.co.id', 'budi@lab.co.id'])),
    );
    expect(find.text('jumlah: 2'), findsOneWidget);

    await tester.tap(find.byTooltip('Hapus ani@lab.co.id'));
    await tester.pump();

    expect(find.text('ani@lab.co.id'), findsNothing);
    expect(find.text('budi@lab.co.id'), findsOneWidget);
    expect(find.text('jumlah: 1'), findsOneWidget);
  });

  testWidgets('the add button commits pending text', (tester) async {
    await tester.pumpWidget(testApp(const _Host()));
    await tester.enterText(find.byType(TextField), 'cici@lab.co.id');
    await tester.tap(find.byTooltip('Tambahkan Email penerima'));
    await tester.pump();

    expect(find.widgetWithText(InputChip, 'cici@lab.co.id'), findsOneWidget);
  });

  testWidgets('shows saved suggestions and adds one without typing it', (
    tester,
  ) async {
    await tester.pumpWidget(
      testApp(const _Host(suggestions: ['saved@lab.co.id', 'other@lab.co.id'])),
    );
    await tester.tap(find.byType(TextField));
    await tester.pump();

    expect(find.text('saved@lab.co.id'), findsOneWidget);
    await tester.tap(find.text('saved@lab.co.id'));
    await tester.pump();

    expect(find.widgetWithText(InputChip, 'saved@lab.co.id'), findsOneWidget);
    expect(find.text('jumlah: 1'), findsOneWidget);
  });

  testWidgets('Form validator can require at least one value', (tester) async {
    final formKey = GlobalKey<FormState>();
    await tester.pumpWidget(
      testApp(
        Form(
          key: formKey,
          child: AppTagInput(
            label: 'Email penerima',
            values: const [],
            onChanged: (_) {},
            validator: (v) =>
                (v == null || v.isEmpty) ? 'Isi minimal satu email.' : null,
          ),
        ),
      ),
    );
    expect(formKey.currentState!.validate(), isFalse);
    await tester.pump();
    expect(find.text('Isi minimal satu email.'), findsOneWidget);
  });
}
