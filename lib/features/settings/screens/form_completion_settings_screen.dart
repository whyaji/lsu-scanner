import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_providers.dart';
import '../../../core/database/models/form_completion_suggestion.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../features/pupuk_lab/models/pupuk_lab_contact.dart';
import '../../../features/pupuk_lab/models/pupuk_lab_validation.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/buttons/app_icon_button.dart';
import '../../../widgets/feedback/app_bottom_sheet.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../../widgets/feedback/app_notice_type.dart';
import '../../../widgets/feedback/app_toast.dart';
import '../../../widgets/forms/app_text_field.dart';

class FormCompletionSettingsScreen extends ConsumerWidget {
  const FormCompletionSettingsScreen({super.key});

  Future<void> _add(
    BuildContext context,
    WidgetRef ref,
    FormCompletionSuggestionType type,
  ) async {
    final suggestionsDao = ref.read(formCompletionSuggestionsDaoProvider);
    final value = await AppBottomSheet.show<String>(
      context,
      title: 'Tambah ${type.label.toLowerCase()}',
      builder: (_) => _AddSuggestionSheet(type: type),
    );
    if (value == null || !context.mounted) return;

    final existing = await suggestionsDao.getAll(type: type);
    final normalized = type == FormCompletionSuggestionType.email
        ? value.toLowerCase()
        : value;
    if (existing.any(
      (item) =>
          (type == FormCompletionSuggestionType.email
              ? item.value.toLowerCase()
              : item.value) ==
          normalized,
    )) {
      if (context.mounted) {
        AppToast.show(
          context,
          'Data tersebut sudah ada di daftar saran.',
          type: AppNoticeType.info,
        );
      }
      return;
    }

    await suggestionsDao.add(type, value);
    if (context.mounted) ref.invalidate(formCompletionSuggestionsProvider);
    if (context.mounted) {
      AppToast.show(context, 'Ditambahkan ke daftar saran.');
    }
  }

  Future<void> _delete(
    BuildContext context,
    WidgetRef ref,
    FormCompletionSuggestion suggestion,
  ) async {
    final suggestionsDao = ref.read(formCompletionSuggestionsDaoProvider);
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Hapus dari saran?',
      message: '${suggestion.value} tidak akan muncul lagi sebagai saran.',
      confirmLabel: 'Hapus',
      cancelLabel: 'Batal',
      tone: AppDialogTone.destructive,
    );
    if (!confirmed || !context.mounted) return;
    await suggestionsDao.delete(suggestion.id);
    if (context.mounted) ref.invalidate(formCompletionSuggestionsProvider);
    if (context.mounted) {
      AppToast.show(context, 'Data dihapus dari daftar saran.');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final suggestions = ref.watch(formCompletionSuggestionsProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Pelengkapan Formulir')),
      body: SafeArea(
        child: suggestions.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) =>
              Center(child: Text('Daftar saran tidak dapat dibuka.\n$error')),
          data: (items) {
            final emails = items
                .where(
                  (item) => item.type == FormCompletionSuggestionType.email,
                )
                .toList();
            final whatsapp = items
                .where(
                  (item) => item.type == FormCompletionSuggestionType.whatsapp,
                )
                .toList();
            return ListView(
              padding: AppSpacing.paddingScreenLg,
              children: [
                Text(
                  'Saran tersimpan',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Data yang pernah dipakai saat menyimpan penerimaan akan muncul '
                  'di kolom email dan WhatsApp. Hapus data yang tidak ingin '
                  'ditampilkan lagi.',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),
                _SuggestionSection(
                  type: FormCompletionSuggestionType.email,
                  items: emails,
                  onAdd: () =>
                      _add(context, ref, FormCompletionSuggestionType.email),
                  onDelete: (item) => _delete(context, ref, item),
                ),
                const SizedBox(height: AppSpacing.md),
                _SuggestionSection(
                  type: FormCompletionSuggestionType.whatsapp,
                  items: whatsapp,
                  onAdd: () =>
                      _add(context, ref, FormCompletionSuggestionType.whatsapp),
                  onDelete: (item) => _delete(context, ref, item),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Owns the input controller for the whole lifetime of the bottom-sheet
/// subtree. The caller must not dispose a controller while the sheet route is
/// still completing its closing animation.
class _AddSuggestionSheet extends StatefulWidget {
  const _AddSuggestionSheet({required this.type});

  final FormCompletionSuggestionType type;

  @override
  State<_AddSuggestionSheet> createState() => _AddSuggestionSheetState();
}

class _AddSuggestionSheetState extends State<_AddSuggestionSheet> {
  final _controller = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String? _normalize(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return null;
    if (widget.type == FormCompletionSuggestionType.email) {
      return isValidPupukLabEmail(value) ? value : null;
    }
    return normalizeWaPhone(value);
  }

  String _errorFor(String raw) {
    if (raw.trim().isEmpty) return 'Isi nilai terlebih dahulu.';
    return widget.type == FormCompletionSuggestionType.email
        ? 'Masukkan alamat email yang valid.'
        : 'Contoh nomor yang valid: 081234567890.';
  }

  void _submit() {
    final normalized = _normalize(_controller.text);
    if (normalized == null) {
      setState(() => _error = _errorFor(_controller.text));
      return;
    }
    Navigator.of(context).pop(normalized);
  }

  @override
  Widget build(BuildContext context) {
    final isEmail = widget.type == FormCompletionSuggestionType.email;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppTextField(
          label: isEmail ? 'Alamat email' : 'Nomor WhatsApp',
          controller: _controller,
          autofocus: true,
          keyboardType: isEmail
              ? TextInputType.emailAddress
              : TextInputType.phone,
          hint: isEmail ? 'nama@perusahaan.com' : '0812xxxxxxxx',
          errorText: _error,
          textInputAction: TextInputAction.done,
          onChanged: (_) {
            if (_error != null) setState(() => _error = null);
          },
          onSubmitted: (_) => _submit(),
        ),
        const SizedBox(height: AppSpacing.md),
        AppButton(
          label: 'Simpan ke saran',
          fullWidth: true,
          onPressed: _submit,
        ),
      ],
    );
  }
}

class _SuggestionSection extends StatelessWidget {
  const _SuggestionSection({
    required this.type,
    required this.items,
    required this.onAdd,
    required this.onDelete,
  });

  final FormCompletionSuggestionType type;
  final List<FormCompletionSuggestion> items;
  final VoidCallback onAdd;
  final ValueChanged<FormCompletionSuggestion> onDelete;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      margin: EdgeInsets.zero,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(
                  type == FormCompletionSuggestionType.email
                      ? Icons.email_outlined
                      : Icons.phone_outlined,
                  color: scheme.primary,
                ),
                AppSpacing.gapSm,
                Expanded(
                  child: Text(
                    type.label,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
                AppIconButton(
                  icon: Icons.add_rounded,
                  tooltip: 'Tambah ${type.label.toLowerCase()}',
                  onPressed: onAdd,
                ),
              ],
            ),
            if (items.isEmpty)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  'Belum ada ${type.label.toLowerCase()} tersimpan.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              )
            else ...[
              const Divider(height: AppSpacing.lg),
              for (final item in items)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  title: Text(item.value),
                  trailing: AppIconButton(
                    icon: Icons.delete_outline_rounded,
                    tooltip: 'Hapus ${item.value}',
                    color: scheme.error,
                    onPressed: () => onDelete(item),
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
