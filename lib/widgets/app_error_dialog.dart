import 'package:flutter/material.dart';

/// Reusable error/alert dialog with optional "Coba Lagi" (retry) action.
/// Use for QR scan errors, validation errors, etc.
class AppErrorDialog {
  /// Shows a modal dialog with [title], [message], and a primary button.
  /// If [onRetry] is non-null, the button label is "Coba Lagi" and the callback
  /// is invoked when pressed before closing. Otherwise the button is "OK".
  static Future<void> show(
    BuildContext context, {
    required String title,
    required String message,
    VoidCallback? onRetry,
  }) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        icon: Icon(Icons.error_outline, size: 48, color: colorScheme.error),
        title: Text(title),
        content: Text(message),
        actions: [
          if (onRetry != null)
            FilledButton.icon(
              onPressed: () {
                Navigator.of(ctx).pop();
                onRetry();
              },
              icon: const Icon(Icons.refresh, size: 20),
              label: const Text('Coba Lagi'),
            )
          else
            FilledButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
        ],
      ),
    );
  }
}
