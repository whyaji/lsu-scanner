import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../layout/app_card.dart';

/// On/off setting row. A non-null disabledReason replaces the subtitle and disables the switch.
class AppSwitchTile extends StatelessWidget {
  const AppSwitchTile({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.subtitle,
    this.disabledReason,
  });

  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;
  final String? disabledReason;

  @override
  Widget build(BuildContext context) {
    final text = disabledReason ?? subtitle;
    return AppCard(
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        value: value,
        onChanged: disabledReason == null ? onChanged : null,
        title: Text(title),
        subtitle: text == null ? null : Text(text),
        minTileHeight: AppSizes.listItemMinHeight,
        shape: RoundedRectangleBorder(borderRadius: AppSizes.borderCard),
      ),
    );
  }
}
