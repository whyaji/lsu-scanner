import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../widgets/buttons/app_button.dart';
import '../../../../widgets/display/app_empty_state.dart';
import '../../../../widgets/feedback/app_banner.dart';
import '../../../../widgets/feedback/app_notice_type.dart';
import '../../../../widgets/forms/app_checkbox_group.dart';
import '../../../../widgets/forms/app_form_section.dart';
import '../../../../widgets/forms/app_repeater_card.dart';
import '../../../../widgets/forms/app_select_field.dart';
import '../../models/pupuk_lab_draft.dart';
import '../../models/pupuk_lab_master.dart';
import '../../providers/pupuk_lab_draft_notifier.dart';
import '../pupuk_lab_text_field.dart';

/// Step 4: which analyses run, how many times, and on which samples.
class PupukLabParametersStep extends ConsumerWidget {
  const PupukLabParametersStep({
    super.key,
    required this.master,
    required this.errors,
    required this.onGoToInfo,
  });

  final PupukLabMaster master;
  final Map<String, String> errors;

  /// Jumps to the step where the jenis komoditas is chosen.
  final VoidCallback onGoToInfo;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final draft = ref.watch(pupukLabDraftProvider);
    final notifier = ref.read(pupukLabDraftProvider.notifier);
    final jenisId = draft.jenisSampelId;

    if (jenisId == null) {
      return AppEmptyState(
        icon: Icons.science_outlined,
        title: 'Pilih jenis komoditas dulu',
        message: 'Daftar parameter bergantung pada jenis komoditas.',
        actionLabel: 'Buka langkah Informasi',
        onAction: onGoToInfo,
      );
    }

    final available = master.parametersFor(jenisId);
    final used = {for (final p in draft.parameters) ?p.parameterId};
    final canAdd =
        draft.samples.isNotEmpty && available.any((p) => !used.contains(p.id));
    final addReason = draft.samples.isEmpty
        ? 'Tambahkan sampel di langkah Sampel dulu.'
        : available.isEmpty
        ? 'Jenis komoditas ini belum punya parameter di SmartLab.'
        : !canAdd
        ? 'Semua parameter sudah dipilih.'
        : null;

    return AppFormSection(
      title: 'Parameter uji',
      description:
          'Tiap parameter hanya boleh dipilih sekali. Pilih sampel mana yang diuji.',
      children: [
        if (errors['parameters'] != null)
          AppBanner(type: AppNoticeType.error, message: errors['parameters']!),
        for (var i = 0; i < draft.parameters.length; i++)
          _ParameterCard(
            index: i,
            row: draft.parameters[i],
            available: available,
            usedByOthers: {
              for (final p in draft.parameters)
                if (p.key != draft.parameters[i].key) ?p.parameterId,
            },
            kodes: draft.kodes,
            errors: errors,
            onRemove: () => notifier.removeParameter(draft.parameters[i].key),
            notifier: notifier,
          ),
        AppButton(
          label: 'Tambah parameter',
          icon: Icons.add_rounded,
          variant: AppButtonVariant.secondary,
          fullWidth: true,
          onPressed: canAdd ? notifier.addParameter : null,
        ),
        if (addReason != null)
          Text(addReason, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }
}

class _ParameterCard extends StatelessWidget {
  const _ParameterCard({
    required this.index,
    required this.row,
    required this.available,
    required this.usedByOthers,
    required this.kodes,
    required this.errors,
    required this.onRemove,
    required this.notifier,
  });

  final int index;
  final PupukLabParameterDraft row;
  final List<PupukLabParameterMaster> available;
  final Set<int> usedByOthers;
  final List<String> kodes;
  final Map<String, String> errors;
  final VoidCallback onRemove;
  final PupukLabDraftNotifier notifier;

  String? _error(String field) => errors['parameters.$index.$field'];

  @override
  Widget build(BuildContext context) {
    return AppRepeaterCard(
      title: 'Parameter ${index + 1}',
      onRemove: onRemove,
      children: [
        AppSelectField<int>(
          label: 'Parameter',
          required: true,
          value: row.parameterId,
          errorText: _error('parameterId'),
          options: [
            for (final p in available)
              if (!usedByOthers.contains(p.id))
                AppSelectOption(
                  value: p.id,
                  label: p.namaParameter,
                  subtitle: [
                    if (p.namaUnsur != null && p.namaUnsur!.isNotEmpty)
                      p.namaUnsur!,
                    if (p.satuan != null && p.satuan!.isNotEmpty) p.satuan!,
                  ].join(' · '),
                ),
          ],
          onChanged: (id) => notifier.updateParameter(
            row.key,
            (r) => r.copyWith(parameterId: id),
          ),
        ),
        PupukLabTextField(
          label: 'Jumlah uji',
          value: '${row.totalSample}',
          required: true,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.done,
          errorText: _error('totalSample'),
          helperText: 'Biasanya sama dengan jumlah sampel yang diuji.',
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            LengthLimitingTextInputFormatter(4),
          ],
          onChanged: (v) => notifier.updateParameter(
            row.key,
            (r) => r.copyWith(totalSample: int.tryParse(v) ?? 0),
          ),
        ),
        AppCheckboxGroup<String>(
          label: 'Sampel yang diuji',
          required: true,
          errorText: _error('kodeSampel'),
          values: row.kodeSampel,
          options: [
            for (final k in kodes) AppCheckboxOption(value: k, label: k),
          ],
          onChanged: (selected) => notifier.updateParameter(
            row.key,
            // Keep the receipt's own order, whatever order the user ticked.
            (r) => r.copyWith(
              kodeSampel: [
                for (final k in kodes)
                  if (selected.contains(k)) k,
              ],
            ),
          ),
        ),
      ],
    );
  }
}
