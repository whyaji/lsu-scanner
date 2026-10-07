import 'package:flutter/material.dart';

import '../../core/theme/app_sizes.dart';
import '../../core/theme/app_spacing.dart';
import '../feedback/app_bottom_sheet.dart';
import 'app_form_value_field.dart';
import 'app_picker_field.dart';
import 'app_text_field.dart';

@immutable
class AppSelectOption<T> {
  const AppSelectOption({
    required this.value,
    required this.label,
    this.subtitle,
  });

  final T value;
  final String label;
  final String? subtitle;
}

/// Opens a bottom sheet with the options. More than [searchThreshold] options adds a search box.
/// Set disabledReason to disable the field and tell the user why.
class AppSelectField<T> extends StatelessWidget {
  const AppSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.value,
    required this.onChanged,
    this.hint = 'Pilih salah satu',
    this.helperText,
    this.errorText,
    this.disabledReason,
    this.validator,
    this.required = false,
    this.searchThreshold = 7,
    this.autovalidateMode,
  });

  final String label;
  final List<AppSelectOption<T>> options;
  final T? value;
  final ValueChanged<T> onChanged;
  final String hint;
  final String? helperText;
  final String? errorText;
  final String? disabledReason;
  final FormFieldValidator<T>? validator;
  final bool required;
  final int searchThreshold;
  final AutovalidateMode? autovalidateMode;

  AppSelectOption<T>? get _selected {
    for (final o in options) {
      if (o.value == value) return o;
    }
    return null;
  }

  Future<void> _open(BuildContext context, FormFieldState<T> state) async {
    final picked = await AppBottomSheet.show<AppSelectOption<T>>(
      context,
      title: label,
      scrollable: false,
      builder: (_) => _SelectSheet<T>(
        options: options,
        selected: value,
        searchable: options.length > searchThreshold,
      ),
    );
    if (picked == null || !context.mounted) return;
    state.didChange(picked.value);
    onChanged(picked.value);
  }

  @override
  Widget build(BuildContext context) {
    return AppFormValueField<T>(
      value: value,
      validator: validator,
      autovalidateMode: autovalidateMode,
      builder: (state) => AppPickerField(
        label: label,
        displayText: _selected?.label,
        hint: hint,
        helperText: helperText,
        errorText: errorText ?? state.errorText,
        disabledReason: disabledReason,
        required: required,
        onTap: () => _open(context, state),
      ),
    );
  }
}

class _SelectSheet<T> extends StatefulWidget {
  const _SelectSheet({
    required this.options,
    required this.selected,
    required this.searchable,
  });

  final List<AppSelectOption<T>> options;
  final T? selected;
  final bool searchable;

  @override
  State<_SelectSheet<T>> createState() => _SelectSheetState<T>();
}

class _SelectSheetState<T> extends State<_SelectSheet<T>> {
  String _query = '';

  List<AppSelectOption<T>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return widget.options;
    return widget.options
        .where(
          (o) =>
              o.label.toLowerCase().contains(q) ||
              (o.subtitle?.toLowerCase().contains(q) ?? false),
        )
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    final items = _filtered;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.searchable)
          Padding(
            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
            child: AppTextField(
              label: 'Cari',
              hint: 'Ketik untuk menyaring pilihan',
              prefixIcon: Icons.search_rounded,
              clearable: true,
              textInputAction: TextInputAction.search,
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
        Flexible(
          child: items.isEmpty
              ? Padding(
                  padding: const EdgeInsets.symmetric(vertical: AppSpacing.lg),
                  child: Semantics(
                    liveRegion: true,
                    child: Text(
                      'Tidak ada pilihan yang cocok dengan "${_query.trim()}".',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                )
              : ListView.builder(
                  shrinkWrap: true,
                  padding: EdgeInsets.zero,
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final o = items[i];
                    final isSelected = o.value == widget.selected;
                    return Semantics(
                      selected: isSelected,
                      button: true,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Material(
                            color: isSelected
                                ? scheme.primaryContainer
                                : Colors.transparent,
                            child: InkWell(
                              onTap: () => Navigator.of(context).pop(o),
                              child: ConstrainedBox(
                                constraints: const BoxConstraints(
                                  minHeight: AppSizes.tapTarget,
                                ),
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppSpacing.md,
                                    vertical: AppSpacing.sm,
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: Column(
                                          mainAxisSize: MainAxisSize.min,
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              o.label,
                                              style: theme.textTheme.bodyLarge
                                                  ?.copyWith(
                                                    color: scheme.onSurface,
                                                  ),
                                            ),
                                            if (o.subtitle != null) ...[
                                              const SizedBox(
                                                height: AppSpacing.xs,
                                              ),
                                              Text(
                                                o.subtitle!,
                                                style: theme.textTheme.bodySmall
                                                    ?.copyWith(
                                                      color: scheme
                                                          .onSurfaceVariant,
                                                    ),
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                      if (isSelected)
                                        Icon(
                                          Icons.check_rounded,
                                          color: scheme.primary,
                                        ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          ),
                          if (i < items.length - 1)
                            Divider(
                              height: 1,
                              indent: AppSpacing.md,
                              endIndent: AppSpacing.md,
                              color: scheme.outlineVariant,
                            ),
                        ],
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
