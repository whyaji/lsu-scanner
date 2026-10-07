import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:sampletrack/core/theme/app_theme.dart';

/// App shell for widget tests: real theme, Indonesian locale, optional text scale and navigator key.
Widget testApp(
  Widget child, {
  ThemeData? theme,
  double textScale = 1,
  GlobalKey<NavigatorState>? navigatorKey,
  bool scaffold = true,
}) {
  return MaterialApp(
    navigatorKey: navigatorKey,
    theme: theme ?? AppTheme.light,
    locale: const Locale('id'),
    supportedLocales: const [Locale('id')],
    localizationsDelegates: const [
      GlobalMaterialLocalizations.delegate,
      GlobalWidgetsLocalizations.delegate,
      GlobalCupertinoLocalizations.delegate,
    ],
    builder: (context, app) => MediaQuery(
      data: MediaQuery.of(
        context,
      ).copyWith(textScaler: TextScaler.linear(textScale)),
      child: app!,
    ),
    home: scaffold ? Scaffold(body: child) : child,
  );
}
