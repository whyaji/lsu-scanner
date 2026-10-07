import 'dart:async';

import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import 'app_feedback_host.dart';
import 'app_notice_type.dart';

/// Lightweight confirmation card anchored at the top. One toast at a time: a new one replaces the current.
/// Auto dismisses (longer when it has an action) and can be swiped up. Never use it for errors that need a decision.
class AppToast {
  AppToast._();

  static OverlayEntry? _entry;

  static void show(
    BuildContext context,
    String message, {
    AppNoticeType type = AppNoticeType.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    _insert(
      Overlay.of(context, rootOverlay: true),
      message,
      type,
      actionLabel,
      onAction,
      duration,
    );
  }

  /// Shows without a BuildContext through the navigator registered in AppFeedbackHost.
  /// Returns false when no navigator is mounted yet, so callers can fall back.
  static bool showGlobal(
    String message, {
    AppNoticeType type = AppNoticeType.success,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  }) {
    final overlay = AppFeedbackHost.overlay;
    if (overlay == null) return false;
    _insert(overlay, message, type, actionLabel, onAction, duration);
    return true;
  }

  static void dismiss() => _removeCurrent();

  static void _insert(
    OverlayState overlay,
    String message,
    AppNoticeType type,
    String? actionLabel,
    VoidCallback? onAction,
    Duration? duration,
  ) {
    assert(
      (actionLabel == null) == (onAction == null),
      'actionLabel and onAction go together',
    );
    _removeCurrent();
    late final OverlayEntry entry;
    entry = OverlayEntry(
      builder: (_) => _ToastCard(
        message: message,
        type: type,
        actionLabel: actionLabel,
        onAction: onAction,
        duration:
            duration ??
            (actionLabel == null
                ? const Duration(seconds: 4)
                : const Duration(seconds: 7)),
        onClosed: () {
          if (identical(_entry, entry)) _removeCurrent();
        },
      ),
    );
    _entry = entry;
    overlay.insert(entry);
  }

  static void _removeCurrent() {
    final entry = _entry;
    if (entry == null) return;
    _entry = null;
    entry.remove();
    entry.dispose();
  }
}

class _ToastCard extends StatefulWidget {
  const _ToastCard({
    required this.message,
    required this.type,
    required this.actionLabel,
    required this.onAction,
    required this.duration,
    required this.onClosed,
  });

  final String message;
  final AppNoticeType type;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Duration duration;
  final VoidCallback onClosed;

  @override
  State<_ToastCard> createState() => _ToastCardState();
}

class _ToastCardState extends State<_ToastCard>
    with SingleTickerProviderStateMixin {
  static const _transition = Duration(milliseconds: 180);

  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: _transition,
  );
  Timer? _timer;
  bool _closing = false;

  @override
  void initState() {
    super.initState();
    _controller.forward();
    _timer = Timer(widget.duration, _close);
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  Future<void> _close() async {
    if (_closing || !mounted) return;
    _closing = true;
    _timer?.cancel();
    await _controller.reverse();
    widget.onClosed();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final style = widget.type.resolve(context);
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _controller.duration = reduceMotion ? Duration.zero : _transition;

    final card = Material(
      color: style.container,
      elevation: 6,
      shadowColor: theme.colorScheme.shadow,
      surfaceTintColor: Colors.transparent,
      borderRadius: AppSizes.borderCard,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
          child: Row(
            children: [
              ExcludeSemantics(
                child: Icon(
                  style.icon,
                  color: style.accent,
                  size: AppSizes.iconMd,
                ),
              ),
              const SizedBox(width: AppSpacing.sm + AppSpacing.xs),
              Expanded(
                child: Text(
                  widget.message,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: style.onContainer,
                  ),
                ),
              ),
              if (widget.actionLabel != null)
                TextButton(
                  onPressed: () {
                    widget.onAction?.call();
                    _close();
                  },
                  style: TextButton.styleFrom(
                    foregroundColor: style.onContainer,
                    minimumSize: const Size(
                      AppSizes.tapTarget,
                      AppSizes.tapTarget,
                    ),
                    textStyle: theme.textTheme.labelLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                  child: Text(widget.actionLabel!),
                ),
            ],
          ),
        ),
      ),
    );

    return Positioned(
      top: 0,
      left: 0,
      right: 0,
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.md),
          child: Align(
            alignment: Alignment.topCenter,
            child: ConstrainedBox(
              constraints: const BoxConstraints(
                maxWidth: AppSizes.toastMaxWidth,
              ),
              child: FadeTransition(
                opacity: _controller,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, -0.3),
                    end: Offset.zero,
                  ).animate(_controller),
                  child: Dismissible(
                    key: const ValueKey('app-toast-dismissible'),
                    direction: DismissDirection.up,
                    onDismissed: (_) => widget.onClosed(),
                    child: Semantics(
                      container: true,
                      liveRegion: true,
                      label: widget.type.spokenLabel,
                      child: card,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
