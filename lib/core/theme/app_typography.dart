import 'package:flutter/material.dart';

/// Typography helpers using theme text styles.
/// Prefer Theme.of(context).textTheme in widgets; use this for one-off overrides.
class AppTypography {
  AppTypography._();

  static TextStyle? titleLarge(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold);

  static TextStyle? titleMedium(BuildContext context) => Theme.of(
    context,
  ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600);

  static TextStyle? bodyLarge(BuildContext context) =>
      Theme.of(context).textTheme.bodyLarge;

  static TextStyle? bodyMedium(BuildContext context) =>
      Theme.of(context).textTheme.bodyMedium;

  static TextStyle? bodySmall(BuildContext context) =>
      Theme.of(context).textTheme.bodySmall;

  static TextStyle? labelMedium(BuildContext context) => Theme.of(
    context,
  ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w500);
}
