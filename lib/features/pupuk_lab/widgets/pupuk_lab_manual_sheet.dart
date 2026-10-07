import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/buttons/app_button.dart';
import '../../../widgets/feedback/app_bottom_sheet.dart';
import '../../../widgets/forms/app_text_field.dart';
import '../providers/pupuk_lab_draft_notifier.dart';

/// Messages for a manual code the draft refused.
String pupukLabManualMessage(PupukLabManualResult result) => switch (result) {
  PupukLabManualResult.added => '',
  PupukLabManualResult.empty => 'Isi kode sampel.',
  PupukLabManualResult.tooShort =>
    'Kode sampel minimal $kPupukLabKodeMin karakter.',
  PupukLabManualResult.tooLong =>
    'Kode sampel maksimal $kPupukLabKodeMax karakter.',
  PupukLabManualResult.duplicate => 'Kode ini sudah ada di penerimaan.',
  PupukLabManualResult.isSystemSample =>
    'Kode ini sudah terdaftar di SampleTrack. Pindai labelnya agar tidak tercatat dua kali.',
};

/// Asks for one code. [submit] returns the draft's verdict; the sheet closes
/// on [PupukLabManualResult.added] and otherwise shows the reason in the field.
Future<void> showPupukLabManualSheet(
  BuildContext context, {
  required Future<PupukLabManualResult> Function(String code) submit,
}) {
  return AppBottomSheet.show<void>(
    context,
    title: 'Tambah kode sampel manual',
    builder: (_) => _ManualForm(submit: submit),
  );
}

class _ManualForm extends StatefulWidget {
  const _ManualForm({required this.submit});

  final Future<PupukLabManualResult> Function(String code) submit;

  @override
  State<_ManualForm> createState() => _ManualFormState();
}

class _ManualFormState extends State<_ManualForm> {
  final _controller = TextEditingController();
  String? _error;
  bool _busy = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _add() async {
    if (_busy) return;
    setState(() => _busy = true);
    final result = await widget.submit(_controller.text);
    if (!mounted) return;
    if (result == PupukLabManualResult.added) {
      Navigator.of(context).pop();
      return;
    }
    setState(() {
      _busy = false;
      _error = pupukLabManualMessage(result);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.md,
        0,
        AppSpacing.md,
        AppSpacing.md + MediaQuery.viewInsetsOf(context).bottom,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Untuk sampel yang belum ada di SampleTrack tetapi tetap perlu masuk SmartLab.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: AppSpacing.md),
          AppTextField(
            label: 'Kode sampel',
            controller: _controller,
            autofocus: true,
            required: true,
            errorText: _error,
            textCapitalization: TextCapitalization.characters,
            textInputAction: TextInputAction.done,
            inputFormatters: [
              LengthLimitingTextInputFormatter(kPupukLabKodeMax + 20),
            ],
            onChanged: (_) {
              if (_error != null) setState(() => _error = null);
            },
            onSubmitted: (_) => _add(),
          ),
          const SizedBox(height: AppSpacing.md),
          AppButton(
            label: 'Tambahkan sampel',
            onPressed: _add,
            loading: _busy,
            fullWidth: true,
          ),
        ],
      ),
    );
  }
}
