import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../buttons/app_icon_button.dart';
import 'app_field_decoration.dart';
import 'app_field_label.dart';

/// Text input with the label above, helper or error below, optional clear and password toggle.
/// Works inside a Form (validator) and standalone (errorText).
class AppTextField extends StatefulWidget {
  const AppTextField({
    super.key,
    required this.label,
    this.controller,
    this.focusNode,
    this.hint,
    this.helperText,
    this.errorText,
    this.validator,
    this.onChanged,
    this.onSubmitted,
    this.keyboardType,
    this.textInputAction,
    this.inputFormatters,
    this.autofillHints,
    this.prefixIcon,
    this.suffix,
    this.obscureText = false,
    this.clearable = false,
    this.required = false,
    this.enabled = true,
    this.readOnly = false,
    this.autofocus = false,
    this.minLines,
    this.maxLines = 1,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.autovalidateMode,
  });

  final String label;
  final TextEditingController? controller;
  final FocusNode? focusNode;
  final String? hint;
  final String? helperText;
  final String? errorText;
  final FormFieldValidator<String>? validator;
  final ValueChanged<String>? onChanged;
  final ValueChanged<String>? onSubmitted;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final List<TextInputFormatter>? inputFormatters;
  final Iterable<String>? autofillHints;
  final IconData? prefixIcon;
  final Widget? suffix;
  final bool obscureText;
  final bool clearable;
  final bool required;
  final bool enabled;
  final bool readOnly;
  final bool autofocus;
  final int? minLines;
  final int? maxLines;
  final int? maxLength;
  final TextCapitalization textCapitalization;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  TextEditingController? _ownController;
  late bool _obscured = widget.obscureText;

  TextEditingController get _controller =>
      widget.controller ?? (_ownController ??= TextEditingController());

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void didUpdateWidget(AppTextField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      (oldWidget.controller ?? _ownController)?.removeListener(_onTextChanged);
      _controller.addListener(_onTextChanged);
    }
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _ownController?.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    if (widget.clearable) setState(() {});
  }

  Widget? _buildSuffix() {
    final items = <Widget>[
      if (widget.clearable &&
          _controller.text.isNotEmpty &&
          widget.enabled &&
          !widget.readOnly)
        AppIconButton(
          icon: Icons.close_rounded,
          tooltip: 'Hapus isi ${widget.label}',
          onPressed: () {
            _controller.clear();
            widget.onChanged?.call('');
          },
        ),
      if (widget.obscureText)
        AppIconButton(
          icon: _obscured
              ? Icons.visibility_outlined
              : Icons.visibility_off_outlined,
          tooltip: _obscured
              ? 'Tampilkan ${widget.label}'
              : 'Sembunyikan ${widget.label}',
          onPressed: () => setState(() => _obscured = !_obscured),
        ),
      if (widget.suffix != null) widget.suffix!,
    ];
    if (items.isEmpty) return null;
    if (items.length == 1) return items.first;
    return Row(mainAxisSize: MainAxisSize.min, children: items);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFieldLabel(label: widget.label, required: widget.required),
        TextFormField(
          controller: _controller,
          focusNode: widget.focusNode,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          autofocus: widget.autofocus,
          obscureText: _obscured,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          inputFormatters: widget.inputFormatters,
          autofillHints: widget.autofillHints,
          textCapitalization: widget.textCapitalization,
          minLines: widget.obscureText ? 1 : widget.minLines,
          maxLines: widget.obscureText ? 1 : widget.maxLines,
          maxLength: widget.maxLength,
          validator: widget.validator,
          autovalidateMode: widget.autovalidateMode,
          onChanged: widget.onChanged,
          onFieldSubmitted: widget.onSubmitted,
          decoration: AppFieldDecoration.build(
            context,
            hint: widget.hint,
            helperText: widget.helperText,
            errorText: widget.errorText,
            enabled: widget.enabled,
            prefixIcon: widget.prefixIcon == null
                ? null
                : Icon(widget.prefixIcon),
            suffixIcon: _buildSuffix(),
          ),
        ),
      ],
    );
  }
}
