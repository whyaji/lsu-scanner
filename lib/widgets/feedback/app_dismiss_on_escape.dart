import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

/// Pops the enclosing route when Escape is pressed. Back is handled by the route itself.
class AppDismissOnEscape extends StatelessWidget {
  const AppDismissOnEscape({super.key, required this.child, this.enabled = true});

  final Widget child;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) return child;
    return CallbackShortcuts(
      bindings: {
        const SingleActivator(LogicalKeyboardKey.escape): () =>
            Navigator.maybePop(context),
      },
      child: Focus(autofocus: true, skipTraversal: true, child: child),
    );
  }
}
