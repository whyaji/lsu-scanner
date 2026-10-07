import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import 'app_field_label.dart';
import 'app_form_value_field.dart';

@immutable
class AppChoiceOption<T> {
  const AppChoiceOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Single choice from a short list (up to about 6). The selected chip shows a check mark, not only a color.
class AppChoiceChips<T> extends StatelessWidget {
  const AppChoiceChips({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.helperText,
    this.errorText,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.autovalidateMode,
  });

  final String label;
  final List<AppChoiceOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<T>? validator;
  final bool required;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppFormValueField<T>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (state) {
        final error = errorText ?? state.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFieldLabel(label: label, required: required),
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final o in options)
                  ChoiceChip(
                    label: Text(o.label),
                    selected: o.value == value,
                    showCheckmark: true,
                    onSelected: enabled
                        ? (_) {
                            state.didChange(o.value);
                            onChanged(o.value);
                          }
                        : null,
                    materialTapTargetSize: MaterialTapTargetSize.padded,
                    labelPadding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.xs,
                      vertical: AppSpacing.sm,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: AppSizes.borderChip,
                    ),
                    side: BorderSide(
                      color: o.value == value ? scheme.primary : scheme.outline,
                    ),
                    backgroundColor: scheme.surface,
                    selectedColor: scheme.primaryContainer,
                    checkmarkColor: scheme.onPrimaryContainer,
                    labelStyle: theme.textTheme.labelLarge?.copyWith(
                      color: o.value == value
                          ? scheme.onPrimaryContainer
                          : scheme.onSurface,
                    ),
                  ),
              ],
            ),
            if (error != null || helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs + 2),
                child: Text(
                  error ?? helperText!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: error != null
                        ? scheme.error
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
