import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_form_value_field.dart';
import 'app_picker_field.dart';

/// Date picker field using the Material picker in the app locale (id).
/// min and max default to 2000..2100 so the picker is never unbounded.
class AppDateField extends StatelessWidget {
  AppDateField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    DateTime? minDate,
    DateTime? maxDate,
    this.hint = 'Pilih tanggal',
    this.helperText,
    this.errorText,
    this.disabledReason,
    this.validator,
    this.required = false,
    this.autovalidateMode,
  }) : minDate = minDate ?? DateTime(2000),
       maxDate = maxDate ?? DateTime(2100);

  final String label;
  final DateTime? value;
  final ValueChanged<DateTime> onChanged;
  final DateTime minDate;
  final DateTime maxDate;
  final String hint;
  final String? helperText;
  final String? errorText;
  final String? disabledReason;
  final FormFieldValidator<DateTime>? validator;
  final bool required;
  final AutovalidateMode? autovalidateMode;

  Future<void> _pick(
    BuildContext context,
    FormFieldState<DateTime> state,
  ) async {
    final first = DateUtils.dateOnly(minDate);
    final last = DateUtils.dateOnly(maxDate);
    var initial = DateUtils.dateOnly(value ?? DateTime.now());
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label,
      cancelText: 'Batal',
      confirmText: 'Pilih',
    );
    if (picked == null || !context.mounted) return;
    state.didChange(picked);
    onChanged(picked);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context).toString();
    return AppFormValueField<DateTime>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (state) => AppPickerField(
        label: label,
        displayText: value == null
            ? null
            : DateFormat('d MMMM y', locale).format(value!),
        hint: hint,
        helperText: helperText,
        errorText: errorText ?? state.errorText,
        disabledReason: disabledReason,
        required: required,
        icon: Icons.calendar_today_outlined,
        onTap: () => _pick(context, state),
      ),
    );
  }
}
