import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';

/// Screen scaffold: app bar, content capped at 640 wide, optional sticky bottom bar that rides above the keyboard.
/// scroll: true wraps body in a scroll view with screen padding. scroll: false hands layout to the body (own ListView); then onRefresh needs that body to be scrollable.
class AppPage extends StatelessWidget {
  const AppPage({
    super.key,
    required this.title,
    required this.body,
    this.actions,
    this.leading,
    this.bottomBar,
    this.onRefresh,
    this.scroll = true,
    this.floatingActionButton,
    this.bottom,
  });

  final String title;
  final Widget body;
  final List<Widget>? actions;
  final Widget? leading;
  final Widget? bottomBar;
  final Future<void> Function()? onRefresh;
  final bool scroll;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? bottom;

  @override
  Widget build(BuildContext context) {
    final effectiveLeading =
        leading ?? (Navigator.of(context).canPop() ? const BackButton() : null);
    Widget content = body;
    if (scroll) {
      content = SingleChildScrollView(
        physics: onRefresh != null
            ? const AlwaysScrollableScrollPhysics()
            : null,
        keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
        padding: AppSpacing.screenPaddingOf(context),
        child: body,
      );
    }
    if (onRefresh != null) {
      content = RefreshIndicator(onRefresh: onRefresh!, child: content);
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(title),
        leading: effectiveLeading,
        actions: actions,
        bottom: bottom,
      ),
      floatingActionButton: floatingActionButton,
      body: SafeArea(
        bottom: bottomBar == null,
        child: Column(
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.topCenter,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: content,
                ),
              ),
            ),
            if (bottomBar != null)
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: AppSizes.contentMaxWidth,
                  ),
                  child: bottomBar,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
