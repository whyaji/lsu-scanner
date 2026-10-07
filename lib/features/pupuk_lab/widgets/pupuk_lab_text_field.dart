import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../widgets/forms/app_text_field.dart';

/// [AppTextField] bound to a value held elsewhere (the draft). Typing reports
/// through [onChanged]; a value that changes from outside (a jenis prefill,
/// a scan) replaces the text without moving the cursor while the user types.
class PupukLabTextField extends StatefulWidget {
  const PupukLabTextField({
    super.key,
    required this.label,
    required this.value,
    required this.onChanged,
    this.errorText,
    this.helperText,
    this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.sentences,
    this.textInputAction = TextInputAction.next,
    this.inputFormatters,
    this.maxLength,
    this.minLines,
    this.maxLines = 1,
    this.required = false,
  });

  final String label;
  final String value;
  final ValueChanged<String> onChanged;
  final String? errorText;
  final String? helperText;
  final String? hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final TextInputAction textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final int? minLines;
  final int? maxLines;
  final bool required;

  @override
  State<PupukLabTextField> createState() => _PupukLabTextFieldState();
}

class _PupukLabTextFieldState extends State<PupukLabTextField> {
  late final TextEditingController _controller = TextEditingController(
    text: widget.value,
  );

  @override
  void didUpdateWidget(PupukLabTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.value != _controller.text) {
      _controller.value = TextEditingValue(
        text: widget.value,
        selection: TextSelection.collapsed(offset: widget.value.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppTextField(
      label: widget.label,
      controller: _controller,
      onChanged: widget.onChanged,
      errorText: widget.errorText,
      helperText: widget.helperText,
      hint: widget.hint,
      keyboardType: widget.keyboardType,
      textCapitalization: widget.textCapitalization,
      textInputAction: widget.textInputAction,
      inputFormatters: widget.inputFormatters,
      maxLength: widget.maxLength,
      minLines: widget.minLines,
      maxLines: widget.maxLines,
      required: widget.required,
    );
  }
}
