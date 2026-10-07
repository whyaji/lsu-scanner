import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import 'app_field_label.dart';
import 'app_form_value_field.dart';

@immutable
class AppCheckboxOption<T> {
  const AppCheckboxOption({required this.value, required this.label});

  final T value;
  final String label;
}

/// Multi choice list. Each row is at least 48dp high and the whole row toggles.
class AppCheckboxGroup<T> extends StatelessWidget {
  const AppCheckboxGroup({
    super.key,
    required this.label,
    required this.options,
    required this.values,
    required this.onChanged,
    this.helperText,
    this.errorText,
    this.validator,
    this.required = false,
    this.enabled = true,
    this.autovalidateMode,
  });

  final String label;
  final List<AppCheckboxOption<T>> options;
  final List<T> values;
  final ValueChanged<List<T>> onChanged;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<List<T>>? validator;
  final bool required;
  final bool enabled;
  final AutovalidateMode? autovalidateMode;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppFormValueField<List<T>>(
      value: values,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (state) {
        final error = errorText ?? state.errorText;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppFieldLabel(label: label, required: required),
            for (final o in options)
              CheckboxListTile(
                value: values.contains(o.value),
                enabled: enabled,
                onChanged: (checked) {
                  final next = [...values];
                  if (checked == true) {
                    if (!next.contains(o.value)) next.add(o.value);
                  } else {
                    next.remove(o.value);
                  }
                  state.didChange(next);
                  onChanged(next);
                },
                title: Text(o.label),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                minTileHeight: AppSizes.tapTarget,
                visualDensity: VisualDensity.standard,
                shape: RoundedRectangleBorder(
                  borderRadius: AppSizes.borderField,
                ),
              ),
            if (error != null || helperText != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.xs),
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
