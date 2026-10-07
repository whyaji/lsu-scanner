import 'package:flutter/material.dart';

/// Fixed dimensions shared by the design system widgets.
class AppSizes {
  AppSizes._();

  static const double tapTarget = 48;
  static const double buttonHeight = 52;
  static const double buttonHeightCompact = 48;
  static const double listItemMinHeight = 64;

  static const double radiusCard = 12;
  static const double radiusField = 10;
  static const double radiusButton = 12;
  static const double radiusChip = 8;
  static const double radiusDialog = 16;
  static const double radiusSheet = 16;

  static const double contentMaxWidth = 640;
  static const double dialogMaxWidth = 400;
  static const double toastMaxWidth = 560;
  static const double dialogStackBreakpoint = 340;

  static const double iconSm = 20;
  static const double iconMd = 24;

  static BorderRadius get borderCard => BorderRadius.circular(radiusCard);
  static BorderRadius get borderField => BorderRadius.circular(radiusField);
  static BorderRadius get borderButton => BorderRadius.circular(radiusButton);
  static BorderRadius get borderChip => BorderRadius.circular(radiusChip);
  static BorderRadius get borderDialog => BorderRadius.circular(radiusDialog);
  static BorderRadius get borderSheet => const BorderRadius.vertical(
    top: Radius.circular(radiusSheet),
  );
}
