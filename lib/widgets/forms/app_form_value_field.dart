import 'package:flutter/material.dart';

/// FormField whose value is owned by the parent. Keeps Form.validate working for custom inputs.
class AppFormValueField<T> extends FormField<T> {
  const AppFormValueField({
    super.key,
    required T? value,
    required super.builder,
    super.validator,
    super.enabled,
    super.autovalidateMode,
  }) : super(initialValue: value);

  @override
  FormFieldState<T> createState() => _AppFormValueFieldState<T>();
}

class _AppFormValueFieldState<T> extends FormFieldState<T> {
  @override
  void didUpdateWidget(AppFormValueField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != value) setValue(widget.initialValue);
  }
}
