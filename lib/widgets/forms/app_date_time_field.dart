import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'app_form_value_field.dart';
import 'app_picker_field.dart';

/// Date then time picker (24 hour). A picked time outside min or max is clamped to the nearest bound.
class AppDateTimeField extends StatelessWidget {
  AppDateTimeField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    DateTime? minDate,
    DateTime? maxDate,
    this.hint = 'Pilih tanggal dan jam',
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
    final base = value ?? DateTime.now();
    var initial = DateUtils.dateOnly(base);
    if (initial.isBefore(first)) initial = first;
    if (initial.isAfter(last)) initial = last;

    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: first,
      lastDate: last,
      helpText: label,
      cancelText: 'Batal',
      confirmText: 'Lanjut pilih jam',
    );
    if (date == null || !context.mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(base),
      helpText: 'Pilih jam',
      cancelText: 'Batal',
      confirmText: 'Pilih',
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(alwaysUse24HourFormat: true),
        child: child!,
      ),
    );
    if (time == null || !context.mounted) return;

    var picked = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );
    if (picked.isBefore(minDate)) picked = minDate;
    if (picked.isAfter(maxDate)) picked = maxDate;
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
            : DateFormat('d MMMM y, HH:mm', locale).format(value!),
        hint: hint,
        helperText: helperText,
        errorText: errorText ?? state.errorText,
        disabledReason: disabledReason,
        required: required,
        icon: Icons.event_outlined,
        onTap: () => _pick(context, state),
      ),
    );
  }
}
