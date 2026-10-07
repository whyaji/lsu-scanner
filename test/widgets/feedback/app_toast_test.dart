import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sampletrack/widgets/feedback/app_feedback_host.dart';
import 'package:sampletrack/widgets/feedback/app_notice_type.dart';
import 'package:sampletrack/widgets/feedback/app_toast.dart';

import '../../helpers/test_app.dart';

void main() {
  final navigatorKey = GlobalKey<NavigatorState>();

  Future<void> pumpApp(WidgetTester tester) async {
    AppFeedbackHost.register(navigatorKey);
    await tester.pumpWidget(
      testApp(const SizedBox.expand(), navigatorKey: navigatorKey),
    );
  }

  Future<void> cleanUp(WidgetTester tester) async {
    AppToast.dismiss();
    await tester.pump();
  }

  testWidgets('showGlobal shows without a BuildContext and auto dismisses', (
    tester,
  ) async {
    await pumpApp(tester);

    expect(AppToast.showGlobal('Penerimaan tersimpan'), isTrue);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.text('Penerimaan tersimpan'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    expect(find.text('Penerimaan tersimpan'), findsOneWidget);

    await tester.pump(const Duration(seconds: 2));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Penerimaan tersimpan'), findsNothing);
    await cleanUp(tester);
  });

  testWidgets('a new toast replaces the current one', (tester) async {
    await pumpApp(tester);

    AppToast.showGlobal('Pertama');
    await tester.pump();
    AppToast.showGlobal('Kedua', type: AppNoticeType.info);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    expect(find.text('Pertama'), findsNothing);
    expect(find.text('Kedua'), findsOneWidget);
    await cleanUp(tester);
  });

  testWidgets('show with context works and the action runs then closes', (
    tester,
  ) async {
    var undone = 0;
    AppFeedbackHost.register(navigatorKey);
    await tester.pumpWidget(
      testApp(
        Builder(
          builder: (context) => TextButton(
            onPressed: () => AppToast.show(
              context,
              'Foto dihapus',
              type: AppNoticeType.info,
              actionLabel: 'Urungkan',
              onAction: () => undone++,
            ),
            child: const Text('buka'),
          ),
        ),
        navigatorKey: navigatorKey,
      ),
    );
    await tester.tap(find.text('buka'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.tap(find.text('Urungkan'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(undone, 1);
    expect(find.text('Foto dihapus'), findsNothing);
    await cleanUp(tester);
  });

  testWidgets('swiping up dismisses the toast', (tester) async {
    await pumpApp(tester);

    AppToast.showGlobal('Disalin');
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));

    await tester.fling(find.text('Disalin'), const Offset(0, -200), 1500);
    await tester.pumpAndSettle();

    expect(find.text('Disalin'), findsNothing);
    await cleanUp(tester);
  });

  testWidgets('a toast with an action stays longer than a plain one', (
    tester,
  ) async {
    await pumpApp(tester);

    AppToast.showGlobal(
      'Dihapus',
      actionLabel: 'Urungkan',
      onAction: () {},
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 5));
    expect(find.text('Dihapus'), findsOneWidget);

    await tester.pump(const Duration(seconds: 3));
    await tester.pump(const Duration(milliseconds: 300));
    expect(find.text('Dihapus'), findsNothing);
    await cleanUp(tester);
  });
}
