import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';

/// Icon-only button with a 48dp hit target. The tooltip doubles as the screen reader label.
class AppIconButton extends StatelessWidget {
  const AppIconButton({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    this.color,
    this.selected,
    this.selectedIcon,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback? onPressed;
  final Color? color;
  final bool? selected;
  final IconData? selectedIcon;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onPressed,
      tooltip: tooltip,
      color: color,
      isSelected: selected,
      icon: Icon(icon),
      selectedIcon: selectedIcon == null ? null : Icon(selectedIcon),
      iconSize: AppSizes.iconMd,
      constraints: const BoxConstraints(
        minWidth: AppSizes.tapTarget,
        minHeight: AppSizes.tapTarget,
      ),
    );
  }
}
