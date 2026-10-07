import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/display/app_key_value_list.dart';
import '../../../../widgets/display/app_photo_thumb.dart';
import '../../../../widgets/feedback/app_banner.dart';
import '../../../../widgets/feedback/app_dialog.dart';
import '../../../../widgets/feedback/app_notice_type.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../models/pupuk_lab_draft.dart';
import '../../models/pupuk_lab_master.dart';
import '../../models/pupuk_lab_validation.dart';
import '../../providers/pupuk_lab_draft_notifier.dart';
import '../../screens/pupuk_lab_photo_screen.dart';
import '../pupuk_lab_text_field.dart';

/// Step 5: read it over, add photos and a note, then save.
class PupukLabReviewStep extends ConsumerWidget {
  const PupukLabReviewStep({
    super.key,
    required this.master,
    required this.errors,
    required this.problemSteps,
    required this.onGoToStep,
  });

  final PupukLabMaster master;

  /// Errors of this step only (photos, note).
  final Map<String, String> errors;

  /// Earlier steps that still have errors, in order.
  final List<PupukLabStep> problemSteps;
  final ValueChanged<PupukLabStep> onGoToStep;

  Future<void> _addPhoto(
    BuildContext context,
    PupukLabDraftNotifier notifier,
  ) async {
    final path = await Navigator.of(context).push<String>(
      MaterialPageRoute<String>(builder: (_) => const PupukLabPhotoScreen()),
    );
    if (path != null) notifier.addPhoto(path);
  }

  Future<void> _removePhoto(
    BuildContext context,
    PupukLabDraftNotifier notifier,
    String path,
  ) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Hapus foto ini?',
      confirmLabel: 'Hapus foto',
      tone: AppDialogTone.destructive,
    );
    if (ok) notifier.removePhoto(path);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pupukLabDraftProvider);
    final notifier = ref.read(pupukLabDraftProvider.notifier);
    final date = DateFormat('d MMMM y', 'id');
    final jenis = draft.jenisSampelId == null
        ? null
        : master.jenisById(draft.jenisSampelId!);
    final status = master
        .progressOptionsFor(draft.jenisSampelId ?? -1)
        .where((p) => p.id == draft.statusPengerjaan)
        .firstOrNull;
    final manual = draft.samples.where((s) => s.isManual).length;
    final atLimit = draft.fotoPaths.length >= PupukLabLimits.maxFotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (problemSteps.isNotEmpty) ...[
          AppBanner(
            type: AppNoticeType.error,
            title: 'Masih ada isian yang belum lengkap',
            message:
                'Lengkapi langkah ${problemSteps.map((s) => s.label).join(', ')} sebelum menyimpan.',
            actionLabel: 'Perbaiki',
            onAction: () => onGoToStep(problemSteps.first),
          ),
          const SizedBox(height: AppSpacing.sectionGap),
        ],
        AppFormSection(
          title: 'Ringkasan',
          children: [
            AppKeyValueList(
              items: [
                AppKeyValue(label: 'No. surat', value: draft.noSurat),
                AppKeyValue(
                  label: 'Sampel',
                  value: manual == 0
                      ? '${draft.samples.length} sampel'
                      : '${draft.samples.length} sampel ($manual manual)',
                ),
                AppKeyValue(
                  label: 'Jenis komoditas',
                  value: jenis?.nama ?? '-',
                ),
                AppKeyValue(label: 'Jenis pupuk', value: draft.jenisPupuk),
                AppKeyValue(
                  label: 'Status pengerjaan',
                  value: status?.nama ?? '-',
                ),
                AppKeyValue(label: 'Asal sampel', value: draft.asalSampel),
                AppKeyValue(
                  label: 'Tanggal terima',
                  value: date.format(draft.tanggalTerima),
                ),
                AppKeyValue(
                  label: 'Estimasi KUPA',
                  value: draft.estimasiKupa == null
                      ? '-'
                      : date.format(draft.estimasiKupa!),
                ),
                AppKeyValue(
                  label: 'Kondisi sampel',
                  value: draft.kondisiSampel,
                ),
                AppKeyValue(label: 'Pengirim', value: draft.namaPengirim),
                AppKeyValue(label: 'Departemen', value: draft.departemen),
                AppKeyValue(
                  label: 'Email tujuan',
                  value: draft.emailTo.join(', '),
                ),
                AppKeyValue(
                  label: 'Parameter uji',
                  value: '${draft.parameters.length} parameter',
                ),
              ],
            ),
            const AppBanner(
              type: AppNoticeType.info,
              message:
                  'Nomor kupa dan nomor lab ditetapkan SmartLab saat data diunggah.',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Foto sampel',
          description:
              'Wajib 1 foto, maksimal ${PupukLabLimits.maxFotos}. Foto ikut dikirim ke SmartLab.',
          children: [
            if (draft.fotoPaths.isNotEmpty)
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.md,
                children: [
                  for (var i = 0; i < draft.fotoPaths.length; i++)
                    AppPhotoThumb(
                      image: FileImage(File(draft.fotoPaths[i])),
                      semanticLabel: 'Foto ${i + 1}',
                      onRemove: () =>
                          _removePhoto(context, notifier, draft.fotoPaths[i]),
                    ),
                ],
              ),
            AppButton(
              label: 'Ambil foto',
              icon: Icons.photo_camera_outlined,
              variant: AppButtonVariant.secondary,
              fullWidth: true,
              onPressed: atLimit ? null : () => _addPhoto(context, notifier),
            ),
            if (atLimit)
              Text(
                'Batas ${PupukLabLimits.maxFotos} foto tercapai. Hapus satu untuk mengganti.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            if (errors['fotoPaths'] != null)
              AppBanner(
                type: AppNoticeType.error,
                message: errors['fotoPaths']!,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: 'Catatan',
          children: [
            PupukLabTextField(
              label: 'Catatan untuk lab (opsional)',
              value: draft.catatan,
              minLines: 3,
              maxLines: 6,
              textInputAction: TextInputAction.newline,
              keyboardType: TextInputType.multiline,
              onChanged: (v) => notifier.patch((d) => d.copyWith(catatan: v)),
            ),
          ],
        ),
      ],
    );
  }
}
