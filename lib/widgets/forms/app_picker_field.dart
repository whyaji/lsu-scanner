import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import 'app_field_decoration.dart';
import 'app_field_label.dart';

/// Read-only looking field that opens a picker on tap. Base for select and date fields.
/// A non-null disabledReason disables the field and shows the reason as helper text.
class AppPickerField extends StatelessWidget {
  const AppPickerField({
    super.key,
    required this.label,
    required this.onTap,
    this.displayText,
    this.hint,
    this.helperText,
    this.errorText,
    this.disabledReason,
    this.required = false,
    this.icon = Icons.arrow_drop_down_rounded,
  });

  final String label;
  final VoidCallback onTap;
  final String? displayText;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final String? disabledReason;
  final bool required;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final enabled = disabledReason == null;
    final hasValue = displayText != null && displayText!.isNotEmpty;
    final decoration = AppFieldDecoration.build(
      context,
      helperText: disabledReason ?? helperText,
      errorText: errorText,
      enabled: enabled,
      suffixIcon: Icon(icon, size: AppSizes.iconMd),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: label, required: required),
        Semantics(
          button: true,
          enabled: enabled,
          label: label,
          value: hasValue ? displayText : (hint ?? 'Belum dipilih'),
          hint: errorText ?? disabledReason,
          excludeSemantics: true,
          onTap: enabled ? onTap : null,
          child: InkWell(
            onTap: enabled ? onTap : null,
            borderRadius: AppSizes.borderField,
            child: ConstrainedBox(
              constraints: const BoxConstraints(minHeight: AppSizes.tapTarget),
              child: InputDecorator(
                decoration: decoration,
                isEmpty: !hasValue,
                isFocused: false,
                child: Text(
                  hasValue ? displayText! : (hint ?? ''),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: !enabled
                        ? scheme.onSurface.withValues(alpha: 0.38)
                        : hasValue
                        ? scheme.onSurface
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
