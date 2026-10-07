import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/buttons/app_icon_button.dart';
import '../../../../widgets/display/app_empty_state.dart';
import '../../../../widgets/display/app_status_chip.dart';
import '../../../../widgets/feedback/app_banner.dart';
import '../../../../widgets/feedback/app_dialog.dart';
import '../../../../widgets/feedback/app_notice_type.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../../../widgets/layout/app_card.dart';
import '../../models/pupuk_lab_draft.dart';
import '../../providers/pupuk_lab_draft_notifier.dart';
import '../../screens/pupuk_lab_scan_screen.dart';
import '../pupuk_lab_manual_sheet.dart';
import '../pupuk_lab_text_field.dart';

/// Step 1: which samples and which no. surat this receipt covers.
class PupukLabSamplesStep extends ConsumerWidget {
  const PupukLabSamplesStep({super.key, required this.errors});

  final Map<String, String> errors;

  Future<void> _scan(BuildContext context) => Navigator.of(
    context,
  ).push(MaterialPageRoute<void>(builder: (_) => const PupukLabScanScreen()));

  Future<void> _remove(
    BuildContext context,
    PupukLabDraftNotifier notifier,
    PupukLabDraftSample sample,
  ) async {
    final ok = await AppDialog.confirm(
      context,
      title: 'Hapus ${sample.kode}?',
      message: 'Sampel ini keluar dari penerimaan dan dari parameter uji.',
      confirmLabel: 'Hapus sampel',
      tone: AppDialogTone.destructive,
    );
    if (ok) notifier.removeSample(sample.kode);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pupukLabDraftProvider);
    final notifier = ref.read(pupukLabDraftProvider.notifier);
    final samples = draft.samples;
    final manualCount = samples.where((s) => s.isManual).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AppFormSection(
          title: 'No. surat',
          description:
              'Satu penerimaan memakai satu no. surat. Terisi dari sampel pertama yang dipindai.',
          children: [
            PupukLabTextField(
              label: 'No. surat',
              value: draft.noSurat,
              required: true,
              errorText: errors['noSurat'],
              textCapitalization: TextCapitalization.characters,
              onChanged: (v) => notifier.patch((d) => d.copyWith(noSurat: v)),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sectionGap),
        AppFormSection(
          title: samples.isEmpty ? 'Sampel' : 'Sampel (${samples.length})',
          children: [
            Row(
              children: [
                Expanded(
                  child: AppButton(
                    label: 'Pindai label',
                    icon: Icons.qr_code_scanner_rounded,
                    variant: AppButtonVariant.tonal,
                    fullWidth: true,
                    onPressed: () => _scan(context),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: AppButton(
                    label: 'Ketik kode',
                    icon: Icons.keyboard_alt_outlined,
                    variant: AppButtonVariant.secondary,
                    fullWidth: true,
                    onPressed: () => showPupukLabManualSheet(
                      context,
                      submit: notifier.addManual,
                    ),
                  ),
                ),
              ],
            ),
            if (errors['samples'] != null)
              AppBanner(type: AppNoticeType.error, message: errors['samples']!),
            if (samples.isEmpty)
              const AppEmptyState(
                icon: Icons.qr_code_2_rounded,
                title: 'Belum ada sampel',
                message:
                    'Pindai label QR tiap sampel. Sampel yang belum ada di SampleTrack bisa diketik manual.',
              )
            else ...[
              for (final sample in samples)
                _SampleTile(
                  sample: sample,
                  onRemove: () => _remove(context, notifier, sample),
                ),
              if (manualCount > 0)
                Text(
                  '$manualCount kode manual ikut dikirim ke SmartLab, tetapi tidak mengubah data SampleTrack.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _SampleTile extends StatelessWidget {
  const _SampleTile({required this.sample, required this.onRemove});

  final PupukLabDraftSample sample;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final details = [
      if (sample.supplier != null) sample.supplier!,
      if (sample.jenisPupuk != null) sample.jenisPupuk!,
      if (sample.qtyKg != null) '${sample.qtyKg} kg',
    ].join(' · ');
    return AppCard(
      padding: const EdgeInsets.fromLTRB(
        AppSpacing.md,
        AppSpacing.sm,
        AppSpacing.sm,
        AppSpacing.sm,
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  sample.kode,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (details.isNotEmpty)
                  Text(details, style: theme.textTheme.bodySmall),
                if (sample.isManual) ...[
                  const SizedBox(height: AppSpacing.xs),
                  const AppStatusChip(
                    label: 'Manual',
                    type: AppNoticeType.info,
                    icon: Icons.edit_note_rounded,
                  ),
                ],
              ],
            ),
          ),
          AppIconButton(
            icon: Icons.delete_outline_rounded,
            tooltip: 'Hapus sampel ${sample.kode}',
            onPressed: onRemove,
          ),
        ],
      ),
    );
  }
}
