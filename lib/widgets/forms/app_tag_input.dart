import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import '../buttons/app_icon_button.dart';
import 'app_form_value_field.dart';
import 'app_text_field.dart';

/// Multi value input for emails or phone numbers. Enter, comma, semicolon or leaving the field commits the text.
/// itemValidator returns an error message or null; invalid text stays in the field and nothing is added.
class AppTagInput extends StatefulWidget {
  const AppTagInput({
    super.key,
    required this.label,
    required this.values,
    required this.onChanged,
    this.itemValidator,
    this.hint,
    this.helperText,
    this.suggestions = const [],
    this.validator,
    this.keyboardType,
    this.required = false,
    this.enabled = true,
    this.addTooltip = 'Tambahkan',
    this.autovalidateMode,
  });

  final String label;
  final List<String> values;
  final ValueChanged<List<String>> onChanged;
  final String? Function(String value)? itemValidator;
  final String? hint;
  final String? helperText;
  final List<String> suggestions;
  final FormFieldValidator<List<String>>? validator;
  final TextInputType? keyboardType;
  final bool required;
  final bool enabled;
  final String addTooltip;
  final AutovalidateMode? autovalidateMode;

  @override
  State<AppTagInput> createState() => _AppTagInputState();
}

class _AppTagInputState extends State<AppTagInput> {
  final _controller = TextEditingController();
  final _focus = FocusNode();
  String? _error;

  @override
  void initState() {
    super.initState();
    _focus.addListener(() {
      if (!_focus.hasFocus && _controller.text.trim().isNotEmpty) _commit();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    _focus.dispose();
    super.dispose();
  }

  bool _commit([FormFieldState<List<String>>? state]) {
    final text = _controller.text.trim();
    if (text.isEmpty) return false;

    final invalid = widget.itemValidator?.call(text);
    if (invalid != null) {
      setState(() => _error = invalid);
      return false;
    }
    final exists = widget.values.any(
      (v) => v.toLowerCase() == text.toLowerCase(),
    );
    if (exists) {
      setState(() => _error = '"$text" sudah ditambahkan.');
      return false;
    }
    final next = [...widget.values, text];
    _controller.clear();
    setState(() => _error = null);
    state?.didChange(next);
    widget.onChanged(next);
    return true;
  }

  void _remove(String value, FormFieldState<List<String>> state) {
    final next = widget.values.where((v) => v != value).toList();
    state.didChange(next);
    widget.onChanged(next);
  }

  void _onTextChanged(String text, FormFieldState<List<String>> state) {
    if (_error != null) setState(() => _error = null);
    if (text.endsWith(',') || text.endsWith(';')) {
      _controller.text = text.substring(0, text.length - 1);
      _controller.selection = TextSelection.collapsed(
        offset: _controller.text.length,
      );
      _commit(state);
    }
  }

  void _selectSuggestion(String value, FormFieldState<List<String>> state) {
    final exists = widget.values.any(
      (item) => item.toLowerCase() == value.toLowerCase(),
    );
    if (exists) {
      setState(() => _error = '"$value" sudah ditambahkan.');
      return;
    }
    final next = [...widget.values, value];
    _controller.clear();
    state.didChange(next);
    widget.onChanged(next);
    _focus.unfocus();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;

    return AppFormValueField<List<String>>(
      value: widget.values,
      validator: widget.validator,
      autovalidateMode: widget.autovalidateMode,
      builder: (state) => Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RawAutocomplete<String>(
            textEditingController: _controller,
            focusNode: _focus,
            displayStringForOption: (value) => value,
            optionsBuilder: (textEditingValue) {
              final query = textEditingValue.text.trim().toLowerCase();
              return widget.suggestions
                  .where(
                    (value) =>
                        !widget.values.any(
                          (item) => item.toLowerCase() == value.toLowerCase(),
                        ) &&
                        (query.isEmpty || value.toLowerCase().contains(query)),
                  )
                  .take(6);
            },
            onSelected: (value) => _selectSuggestion(value, state),
            optionsViewBuilder: (context, onSelected, options) {
              final scheme = Theme.of(context).colorScheme;
              return Align(
                alignment: Alignment.topLeft,
                child: Material(
                  elevation: 4,
                  color: scheme.surface,
                  borderRadius: BorderRadius.circular(12),
                  clipBehavior: Clip.antiAlias,
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxHeight: 280),
                    child: ListView(
                      padding: EdgeInsets.zero,
                      shrinkWrap: true,
                      children: [
                        for (var i = 0; i < options.length; i++) ...[
                          Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: () => onSelected(options.elementAt(i)),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: AppSizes.tapTarget,
                                ),
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: AppSpacing.md,
                                      vertical: AppSpacing.sm,
                                    ),
                                    child: Text(
                                      options.elementAt(i),
                                      style: theme.textTheme.bodyLarge,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (i < options.length - 1)
                            Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                              color: scheme.outlineVariant,
                            ),
                        ],
                      ],
                    ),
                  ),
                ),
              );
            },
            fieldViewBuilder: (context, controller, focusNode, onSubmitted) =>
                AppTextField(
                  label: widget.label,
                  controller: controller,
                  focusNode: focusNode,
                  hint: widget.hint,
                  helperText: widget.helperText,
                  errorText: _error ?? state.errorText,
                  required: widget.required,
                  enabled: widget.enabled,
                  keyboardType: widget.keyboardType,
                  textInputAction: TextInputAction.done,
                  onChanged: (t) => _onTextChanged(t, state),
                  onSubmitted: (_) {
                    _commit(state);
                    onSubmitted();
                  },
                  suffix: AppIconButton(
                    icon: Icons.add_rounded,
                    tooltip: '${widget.addTooltip} ${widget.label}',
                    onPressed: widget.enabled ? () => _commit(state) : null,
                  ),
                ),
          ),
          if (widget.values.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(top: AppSpacing.sm),
              child: Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  for (final v in widget.values)
                    InputChip(
                      label: Text(v),
                      onDeleted: widget.enabled
                          ? () => _remove(v, state)
                          : null,
                      deleteButtonTooltipMessage: 'Hapus $v',
                      materialTapTargetSize: MaterialTapTargetSize.padded,
                      backgroundColor: scheme.surfaceContainerHighest,
                      side: BorderSide(color: scheme.outlineVariant),
                      shape: RoundedRectangleBorder(
                        borderRadius: AppSizes.borderChip,
                      ),
                      labelStyle: theme.textTheme.labelLarge?.copyWith(
                        color: scheme.onSurface,
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
