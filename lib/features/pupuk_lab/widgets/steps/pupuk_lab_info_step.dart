import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/forms/app_checkbox_group.dart';
import '../../../../widgets/forms/app_choice_chips.dart';
import '../../../../widgets/forms/app_date_field.dart';
import '../../../../widgets/forms/app_date_time_field.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../../../widgets/forms/app_select_field.dart';
import '../../models/pupuk_lab_master.dart';
import '../../providers/pupuk_lab_draft_notifier.dart';
import '../pupuk_lab_text_field.dart';

/// Step 2: what the sample is and when it is due.
class PupukLabInfoStep extends ConsumerWidget {
  const PupukLabInfoStep({
    super.key,
    required this.master,
    required this.errors,
  });

  final PupukLabMaster master;
  final Map<String, String> errors;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pupukLabDraftProvider);
    final notifier = ref.read(pupukLabDraftProvider.notifier);
    final options = master.options;
    final jenisId = draft.jenisSampelId;
    final statuses = jenisId == null
        ? const <PupukLabProgress>[]
        : master.progressOptionsFor(jenisId);

    List<AppChoiceOption<String>> choices(List<String> values) => [
      for (final v in values) AppChoiceOption(value: v, label: v),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormSection(
          title: 'Komoditas',
          children: [
            AppSelectField<int>(
              label: 'Jenis komoditas',
              required: true,
              value: jenisId,
              errorText: errors['jenisSampelId'],
              options: [
                for (final j in master.jenisSampel)
                  AppSelectOption(value: j.id, label: j.nama),
              ],
              onChanged: (id) => notifier.setJenis(master, id),
            ),
            PupukLabTextField(
              label: 'Jenis pupuk',
              value: draft.jenisPupuk,
              required: true,
              hint: 'Contoh: NPK 15-15-15',
              helperText: 'Terisi dari sampel yang dipindai. Ubah bila perlu.',
              errorText: errors['jenisPupuk'],
              maxLength: 100,
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(jenisPupuk: v)),
            ),
            AppSelectField<int>(
              label: 'Status pengerjaan',
              required: true,
              value: draft.statusPengerjaan,
              errorText: errors['statusPengerjaan'],
              disabledReason: jenisId == null
                  ? 'Pilih jenis komoditas dulu.'
                  : null,
              options: [
                for (final s in statuses)
                  AppSelectOption(value: s.id, label: s.nama),
              ],
              onChanged: (id) =>
                  notifier.patch((d) => d.copyWith(statusPengerjaan: id)),
            ),
            AppChoiceChips<String>(
              label: 'Asal sampel',
              required: true,
              value: draft.asalSampel.isEmpty ? null : draft.asalSampel,
              errorText: errors['asalSampel'],
              options: choices(options.asalSampel),
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(asalSampel: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Tanggal',
          children: [
            AppDateTimeField(
              label: 'Tanggal memo',
              required: true,
              value: draft.tanggalMemo,
              errorText: errors['tanggalMemo'],
              onChanged: notifier.setMemo,
            ),
            AppDateField(
              label: 'Tanggal terima',
              required: true,
              value: draft.tanggalTerima,
              helperText:
                  'Mengikuti tanggal memo. Memo dari jam 12.00 dihitung besok.',
              errorText: errors['tanggalTerima'],
              onChanged: notifier.setTanggalTerima,
            ),
            AppDateField(
              label: 'Estimasi KUPA',
              required: true,
              value: draft.estimasiKupa,
              minDate: draft.tanggalTerima,
              errorText: errors['estimasiKupa'],
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(estimasiKupa: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Kondisi sampel',
          children: [
            PupukLabTextField(
              label: 'Kemasan sampel',
              value: draft.kemasanSampel,
              required: true,
              hint: 'Contoh: Plastik klip',
              errorText: errors['kemasanSampel'],
              maxLength: 20,
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(kemasanSampel: v)),
            ),
            AppChoiceChips<String>(
              label: 'Kondisi sampel',
              required: true,
              value: draft.kondisiSampel.isEmpty ? null : draft.kondisiSampel,
              errorText: errors['kondisiSampel'],
              options: choices(options.kondisiSampel),
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(kondisiSampel: v)),
            ),
            PupukLabTextField(
              label: 'Tujuan',
              value: draft.tujuan,
              required: true,
              hint: 'Contoh: Analisis kadar hara',
              errorText: errors['tujuan'],
              maxLength: 100,
              onChanged: (v) => notifier.patch((d) => d.copyWith(tujuan: v)),
            ),
            AppChoiceChips<String>(
              label: 'Skala prioritas',
              required: true,
              value: draft.skalaPrioritas.isEmpty ? null : draft.skalaPrioritas,
              errorText: errors['skalaPrioritas'],
              options: choices(options.skalaPrioritas),
              onChanged: (v) =>
                  notifier.patch((d) => d.copyWith(skalaPrioritas: v)),
            ),
            AppCheckboxGroup<String>(
              label: 'Peralatan',
              errorText: errors['peralatan'],
              values: draft.peralatan,
              options: [
                for (final v in options.peralatan)
                  AppCheckboxOption(value: v, label: v),
              ],
              onChanged: (v) => notifier.patch((d) => d.copyWith(peralatan: v)),
            ),
          ],
        ),
      ],
    );
  }
}
