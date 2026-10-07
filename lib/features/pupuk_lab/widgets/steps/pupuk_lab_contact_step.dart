import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/database/database_providers.dart';
import '../../../../core/database/models/form_completion_suggestion.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/feedback/app_bottom_sheet.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../../../widgets/forms/app_select_field.dart';
import '../../../../widgets/forms/app_switch_tile.dart';
import '../../../../widgets/forms/app_tag_input.dart';
import '../../../../widgets/forms/app_text_field.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../models/pupuk_lab_contact.dart';
import '../../models/pupuk_lab_master.dart';
import '../../models/pupuk_lab_validation.dart';
import '../../providers/pupuk_lab_draft_notifier.dart';
import '../pupuk_lab_text_field.dart';

/// Value of the "add a new department" entry of the department picker.
const String _newDepartemen = '\u0000new';

/// Step 3: who sent the sample, who receives it, and where SmartLab writes back.
class PupukLabContactStep extends ConsumerWidget {
  const PupukLabContactStep({
    super.key,
    required this.master,
    required this.errors,
  });

  final PupukLabMaster master;
  final Map<String, String> errors;

  Future<void> _addDepartemen(
    BuildContext context,
    PupukLabDraftNotifier notifier,
  ) async {
    final controller = TextEditingController();
    final name = await AppBottomSheet.show<String>(
      context,
      title: 'Tambah departemen baru',
      builder: (sheetContext) => Padding(
        padding: EdgeInsets.fromLTRB(
          AppSpacing.md,
          0,
          AppSpacing.md,
          AppSpacing.md + MediaQuery.viewInsetsOf(sheetContext).bottom,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AppTextField(
              label: 'Nama departemen',
              controller: controller,
              autofocus: true,
              required: true,
              maxLength: PupukLabLimits.departemenMax,
              textInputAction: TextInputAction.done,
              onSubmitted: (v) => Navigator.of(sheetContext).pop(v),
            ),
            const SizedBox(height: AppSpacing.md),
            AppButton(
              label: 'Pakai departemen ini',
              fullWidth: true,
              onPressed: () => Navigator.of(sheetContext).pop(controller.text),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
    final trimmed = name?.trim() ?? '';
    if (trimmed.isNotEmpty) {
      notifier.patch((d) => d.copyWith(departemen: trimmed));
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pupukLabDraftProvider);
    final notifier = ref.read(pupukLabDraftProvider.notifier);
    final suggestions = ref
        .watch(formCompletionSuggestionsProvider)
        .maybeWhen(
          data: (items) => items,
          orElse: () => const <FormCompletionSuggestion>[],
        );
    final emailSuggestions = [
      for (final suggestion in suggestions)
        if (suggestion.type == FormCompletionSuggestionType.email)
          suggestion.value,
    ];
    final whatsappSuggestions = [
      for (final suggestion in suggestions)
        if (suggestion.type == FormCompletionSuggestionType.whatsapp)
          suggestion.value,
    ];

    final known = master.departemen;
    final departemenOptions = <AppSelectOption<String>>[
      for (final name in known) AppSelectOption(value: name, label: name),
      if (draft.departemen.isNotEmpty && !known.contains(draft.departemen))
        AppSelectOption(
          value: draft.departemen,
          label: draft.departemen,
          subtitle: 'Baru, dibuat di SmartLab saat unggah',
        ),
      const AppSelectOption(
        value: _newDepartemen,
        label: 'Tambah departemen baru',
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormSection(
          title: 'Pengirim',
          children: [
            PupukLabTextField(
              label: 'Nama pengirim',
              value: draft.namaPengirim,
              required: true,
              errorText: errors['namaPengirim'],
              maxLength: PupukLabLimits.namaPengirimMax,
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(namaPengirim: v)),
            ),
            AppSelectField<String>(
              label: 'Departemen',
              required: true,
              value: draft.departemen.isEmpty ? null : draft.departemen,
              errorText: errors['departemen'],
              options: departemenOptions,
              onChanged: (v) {
                if (v == _newDepartemen) {
                  _addDepartemen(context, notifier);
                } else {
                  notifier.patch((d) => d.copyWith(departemen: v));
                }
              },
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Petugas lab',
          children: [
            PupukLabTextField(
              label: 'Penerima sampel',
              value: draft.penerimaSampel,
              required: true,
              errorText: errors['penerimaSampel'],
              maxLength: PupukLabLimits.penerimaSampelMax,
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(penerimaSampel: v)),
            ),
            PupukLabTextField(
              label: 'Petugas preparasi',
              value: draft.petugasPreperasi,
              helperText: 'Terisi dari jenis komoditas.',
              errorText: errors['petugasPreperasi'],
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(petugasPreperasi: v)),
            ),
            PupukLabTextField(
              label: 'Penyelia',
              value: draft.penyelia,
              helperText: 'Terisi dari jenis komoditas.',
              errorText: errors['penyelia'],
              maxLength: PupukLabLimits.penyeliaMax,
              onChanged: (v) => notifier.patch((d) => d.copyWith(penyelia: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Kontak pelanggan',
          description:
              'SmartLab mengirim email konfirmasi ke alamat ini bila asal sampel Internal.',
          children: [
            AppTagInput(
              label: 'Email tujuan',
              required: true,
              values: draft.emailTo,
              suggestions: emailSuggestions,
              keyboardType: TextInputType.emailAddress,
              hint: 'nama@perusahaan.com',
              helperText: 'Ketuk tambah atau tekan koma setelah tiap alamat.',
              itemValidator: (v) =>
                  isValidPupukLabEmail(v) ? null : 'Alamat email tidak valid.',
              validator: (_) => errors['emailTo'],
              autovalidateMode: errors['emailTo'] == null
                  ? null
                  : AutovalidateMode.always,
              onChanged: (v) => notifier.patch((d) => d.copyWith(emailTo: v)),
            ),
            AppTagInput(
              label: 'Email tembusan (CC)',
              values: draft.emailCc,
              suggestions: emailSuggestions,
              keyboardType: TextInputType.emailAddress,
              itemValidator: (v) =>
                  isValidPupukLabEmail(v) ? null : 'Alamat email tidak valid.',
              validator: (_) => errors['emailCc'],
              autovalidateMode: errors['emailCc'] == null
                  ? null
                  : AutovalidateMode.always,
              onChanged: (v) => notifier.patch((d) => d.copyWith(emailCc: v)),
            ),
            AppTagInput(
              label: 'Nomor WhatsApp',
              values: draft.noHp,
              suggestions: whatsappSuggestions,
              keyboardType: TextInputType.phone,
              hint: '0812xxxxxxxx',
              helperText: 'Awalan 08 diubah otomatis ke 628.',
              itemValidator: (v) => normalizeWaPhone(v) == null
                  ? 'Nomor tidak valid. Contoh: 081234567890.'
                  : null,
              onChanged: (v) => notifier.patch(
                (d) => d.copyWith(
                  noHp: {for (final n in v) normalizeWaPhone(n) ?? n}.toList(),
                ),
              ),
            ),
            PupukLabTextField(
              label: 'Diskon (%)',
              value: draft.diskon,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              helperText: 'Kosongkan bila tidak ada. Maksimal 99.',
              errorText: errors['diskon'],
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(2),
              ],
              onChanged: (v) => notifier.patch((d) => d.copyWith(diskon: v)),
            ),
            AppSwitchTile(
              title: 'Konfirmasi ke pelanggan',
              subtitle: 'Langsung, telepon, atau email.',
              value: draft.konfirmasi,
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(konfirmasi: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        _DocumentSection(errors: errors),
      ],
    );
  }
}

/// Document numbers SmartLab prints on the KUPA. Prefilled, rarely edited, so
/// they stay folded.
class _DocumentSection extends ConsumerWidget {
  const _DocumentSection({required this.errors});

  final Map<String, String> errors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pupukLabDraftProvider);
    final notifier = ref.read(pupukLabDraftProvider.notifier);
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: EdgeInsets.zero,
        title: Text(
          'Dokumen KUPA (opsional)',
          style: Theme.of(context).textTheme.titleMedium,
        ),
        subtitle: const Text('Terisi dari jenis komoditas.'),
        children: [
          Column(
            spacing: AppSpacing.fieldGap,
            children: [
              PupukLabTextField(
                label: 'No. dokumen KUPA',
                value: draft.noDocument,
                errorText: errors['noDocument'],
                onChanged: (v) =>
                    notifier.patch((d) => d.copyWith(noDocument: v)),
              ),
              PupukLabTextField(
                label: 'No. dokumen identitas',
                value: draft.noDocumentIdentitas,
                errorText: errors['noDocumentIdentitas'],
                onChanged: (v) =>
                    notifier.patch((d) => d.copyWith(noDocumentIdentitas: v)),
              ),
              PupukLabTextField(
                label: 'Nama formulir',
                value: draft.namaFormulir,
                errorText: errors['namaFormulir'],
                onChanged: (v) =>
                    notifier.patch((d) => d.copyWith(namaFormulir: v)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
