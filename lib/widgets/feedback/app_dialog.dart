import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../buttons/app_button.dart';
import 'app_dialog_shell.dart';
import 'app_notice_type.dart';
import 'app_progress_handle.dart';

enum AppDialogTone { normal, destructive }

/// One option of AppDialog.choice. Options render as primary, secondary, then text button.
@immutable
class AppDialogChoice<T> {
  const AppDialogChoice({required this.label, required this.value});

  final String label;
  final T value;
}

/// Modal dialogs for results that need acknowledgement and for confirmations.
/// Back, Escape and the scrim close every dialog except progress.
class AppDialog {
  AppDialog._();

  static Future<void> success(
    BuildContext context, {
    required String title,
    String? message,
    String closeLabel = 'Selesai',
  }) => _acknowledge(context, AppNoticeType.success, title, message, closeLabel);

  static Future<void> info(
    BuildContext context, {
    required String title,
    String? message,
    String closeLabel = 'Mengerti',
  }) => _acknowledge(context, AppNoticeType.info, title, message, closeLabel);

  static Future<void> warning(
    BuildContext context, {
    required String title,
    String? message,
    String closeLabel = 'Mengerti',
  }) => _acknowledge(context, AppNoticeType.warning, title, message, closeLabel);

  /// With [onRetry] the dialog offers a retry button that runs the callback after the dialog closes.
  static Future<void> error(
    BuildContext context, {
    required String title,
    String? message,
    VoidCallback? onRetry,
    String retryLabel = 'Coba lagi',
    String closeLabel = 'Tutup',
  }) async {
    final retry = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialogShell(
        type: AppNoticeType.error,
        title: title,
        message: message,
        actions: [
          if (onRetry != null)
            AppDialogAction(
              label: retryLabel,
              onPressed: () => Navigator.of(ctx).pop(true),
              autofocus: true,
            ),
          AppDialogAction(
            label: closeLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: onRetry != null
                ? AppButtonVariant.text
                : AppButtonVariant.primary,
            autofocus: onRetry == null,
          ),
        ],
      ),
    );
    if (retry == true) onRetry?.call();
  }

  /// Resolves true only when the user taps [confirmLabel]. Back, Escape and the scrim resolve false.
  /// Destructive tone focuses the cancel button first so a stray Enter does not delete.
  static Future<bool> confirm(
    BuildContext context, {
    required String title,
    String? message,
    required String confirmLabel,
    String cancelLabel = 'Batal',
    AppDialogTone tone = AppDialogTone.normal,
  }) async {
    final destructive = tone == AppDialogTone.destructive;
    final result = await showDialog<bool>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialogShell(
        type: destructive ? AppNoticeType.warning : null,
        title: title,
        message: message,
        actions: [
          AppDialogAction(
            label: confirmLabel,
            onPressed: () => Navigator.of(ctx).pop(true),
            variant: destructive
                ? AppButtonVariant.destructive
                : AppButtonVariant.primary,
            autofocus: !destructive,
          ),
          AppDialogAction(
            label: cancelLabel,
            onPressed: () => Navigator.of(ctx).pop(false),
            variant: AppButtonVariant.text,
            autofocus: destructive,
          ),
        ],
      ),
    );
    return result ?? false;
  }

  /// Two or three options. Resolves null when dismissed without choosing.
  static Future<T?> choice<T>(
    BuildContext context, {
    required String title,
    String? message,
    required List<AppDialogChoice<T>> choices,
  }) {
    assert(
      choices.length >= 2 && choices.length <= 3,
      'choice supports two or three options',
    );
    const variants = [
      AppButtonVariant.primary,
      AppButtonVariant.secondary,
      AppButtonVariant.text,
    ];
    return showDialog<T>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialogShell(
        title: title,
        message: message,
        actions: [
          for (var i = 0; i < choices.length; i++)
            AppDialogAction(
              label: choices[i].label,
              onPressed: () => Navigator.of(ctx).pop(choices[i].value),
              variant: variants[i],
              autofocus: i == 0,
            ),
        ],
      ),
    );
  }

  /// Blocking progress. The caller must call [AppProgressHandle.close] when done.
  static AppProgressHandle progress(
    BuildContext context, {
    required String message,
    double? value,
  }) {
    final navigator = Navigator.of(context, rootNavigator: true);
    final state = ValueNotifier(AppProgressState(message: message, value: value));
    final route = DialogRoute<void>(
      context: navigator.context,
      barrierDismissible: false,
      builder: (_) => ValueListenableBuilder<AppProgressState>(
        valueListenable: state,
        builder: (context, s, _) => AppDialogShell(
          title: s.message,
          dismissible: false,
          content: _ProgressBody(value: s.value),
        ),
      ),
    );
    navigator.push(route);
    return AppProgressHandle.internal(
      navigator: navigator,
      route: route,
      state: state,
    );
  }

  static Future<void> _acknowledge(
    BuildContext context,
    AppNoticeType type,
    String title,
    String? message,
    String closeLabel,
  ) {
    return showDialog<void>(
      context: context,
      useRootNavigator: true,
      builder: (ctx) => AppDialogShell(
        type: type,
        title: title,
        message: message,
        actions: [
          AppDialogAction(
            label: closeLabel,
            onPressed: () => Navigator.of(ctx).pop(),
            autofocus: true,
          ),
        ],
      ),
    );
  }
}

class _ProgressBody extends StatelessWidget {
  const _ProgressBody({required this.value});

  final double? value;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final v = value?.clamp(0.0, 1.0);
    return Semantics(
      liveRegion: true,
      value: v == null ? null : '${(v * 100).round()} persen',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: v,
              minHeight: 6,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
            ),
          ),
          if (v != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(
              '${(v * 100).round()}%',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
