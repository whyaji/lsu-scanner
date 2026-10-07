import 'package:flutter/material.dart';

/// 8pt grid spacing system for consistent layout.
/// Use multiples of 8 for padding, margins, and gaps.
class AppSpacing {
  AppSpacing._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;
  static const double xxl = 48;

  static const EdgeInsets paddingXs = EdgeInsets.all(xs);
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);
  static const EdgeInsets paddingXl = EdgeInsets.all(xl);

  static const EdgeInsets paddingHorizontalMd = EdgeInsets.symmetric(
    horizontal: md,
  );
  static const EdgeInsets paddingHorizontalLg = EdgeInsets.symmetric(
    horizontal: lg,
  );
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(
    vertical: md,
  );
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(
    vertical: lg,
  );

  static const EdgeInsets paddingScreen = EdgeInsets.all(md);
  static const EdgeInsets paddingScreenLg = EdgeInsets.all(lg);

  static const SizedBox gapXs = SizedBox(width: xs, height: xs);
  static const SizedBox gapSm = SizedBox(width: sm, height: sm);
  static const SizedBox gapMd = SizedBox(width: md, height: md);
  static const SizedBox gapLg = SizedBox(width: lg, height: lg);
  static const SizedBox gapXl = SizedBox(width: xl, height: xl);

  static const double sliverGapSm = sm;
  static const double sliverGapMd = md;
  static const double sliverGapLg = lg;

  /// Gap between titled groups on a screen.
  static const double sectionGap = lg;

  /// Gap between consecutive form fields.
  static const double fieldGap = md;

  /// Gap between a field label and its control.
  static const double labelGap = 6;

  /// Width at which screens switch from phone to tablet insets.
  static const double tabletBreakpoint = 600;

  /// Horizontal and vertical screen inset: 16 on phones, 24 from [tabletBreakpoint].
  static double screenInset(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= tabletBreakpoint ? lg : md;

  static EdgeInsets screenPaddingOf(BuildContext context) =>
      EdgeInsets.all(screenInset(context));
}
