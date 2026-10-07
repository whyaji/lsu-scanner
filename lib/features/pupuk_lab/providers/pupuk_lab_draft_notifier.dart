import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../core/database/database_providers.dart';
import '../../home/providers/home_counts_refresh_provider.dart';
import '../data/pupuk_lab_scan_resolver.dart';
import '../models/pupuk_lab.dart';
import '../models/pupuk_lab_draft.dart';
import '../models/pupuk_lab_form.dart';
import '../models/pupuk_lab_master.dart';
import '../models/pupuk_lab_sample.dart';
import '../models/pupuk_lab_validation.dart';
import 'pupuk_lab_providers.dart';

enum PupukLabManualResult {
  added,
  empty,
  tooShort,
  tooLong,
  duplicate,
  isSystemSample,
}

/// Raised by [PupukLabDraftNotifier.save] when the draft breaks a rule. The
/// screen validates every step first, so this means a bug, not a user error.
class PupukLabInvalidException implements Exception {
  PupukLabInvalidException(this.validation);

  final PupukLabValidation validation;

  @override
  String toString() => 'PupukLabInvalidException(${validation.errors})';
}

const int kPupukLabKodeMin = 2;
const int kPupukLabKodeMax = 100;

final pupukLabScanResolverProvider = Provider<PupukLabScanResolver>(
  (ref) => PupukLabScanResolver(ref.watch(dataSampelPupukDaoProvider)),
);

/// State of the receipt being filled in. Lives while the Terima Lab screens are
/// open; the screen calls [PupukLabDraftNotifier.start] once its inputs loaded.
final pupukLabDraftProvider =
    NotifierProvider.autoDispose<PupukLabDraftNotifier, PupukLabDraft>(
      PupukLabDraftNotifier.new,
    );

class PupukLabDraftNotifier extends Notifier<PupukLabDraft> {
  @override
  PupukLabDraft build() => PupukLabDraft.empty();

  void start(PupukLabDraft initial) => state = initial;

  /// Applies a plain field change. `copyWith` marks the draft dirty.
  void patch(PupukLabDraft Function(PupukLabDraft draft) change) {
    state = change(state);
  }

  // Samples

  /// Adds a scanned sample. The first sample with a no. surat sets the
  /// receipt's no. surat while it is still empty.
  void addScanned(PupukLabDraftSample sample, {String? noSurat}) {
    final draft = state;
    if (draft.kodes.contains(sample.kode)) return;
    state = draft.copyWith(
      samples: [...draft.samples, sample],
      noSurat: draft.noSurat.trim().isEmpty && noSurat != null
          ? noSurat
          : draft.noSurat,
      jenisPupuk: draft.jenisPupuk.trim().isEmpty
          ? sample.jenisPupuk ?? ''
          : draft.jenisPupuk,
      parameters: _withNewKode(draft, sample.kode),
    );
  }

  Future<PupukLabManualResult> addManual(String raw) async {
    final kode = sanitizeKodeSampel(raw.trim());
    if (kode.isEmpty) return PupukLabManualResult.empty;
    if (kode.length < kPupukLabKodeMin) return PupukLabManualResult.tooShort;
    if (kode.length > kPupukLabKodeMax) return PupukLabManualResult.tooLong;
    if (state.kodes.contains(kode)) return PupukLabManualResult.duplicate;
    if (await ref.read(pupukLabScanResolverProvider).isSystemKode(kode)) {
      return PupukLabManualResult.isSystemSample;
    }
    final draft = state;
    if (draft.kodes.contains(kode)) return PupukLabManualResult.duplicate;
    state = draft.copyWith(
      samples: [
        ...draft.samples,
        PupukLabDraftSample(
          sample: PupukLabSample(kodeSampel: kode, isManual: true),
        ),
      ],
      parameters: _withNewKode(draft, kode),
    );
    return PupukLabManualResult.added;
  }

  void removeSample(String kode) {
    final draft = state;
    state = draft.copyWith(
      samples: [
        for (final s in draft.samples)
          if (s.kode != kode) s,
      ],
      parameters: [
        for (final p in draft.parameters)
          p.copyWith(
            kodeSampel: [
              for (final k in p.kodeSampel)
                if (k != kode) k,
            ],
          ),
      ],
    );
  }

  /// A new code joins the parameters that were testing every sample so far.
  List<PupukLabParameterDraft> _withNewKode(PupukLabDraft draft, String kode) {
    final all = draft.kodes.toSet();
    return [
      for (final p in draft.parameters)
        all.isNotEmpty && p.kodeSampel.toSet().containsAll(all)
            ? p.copyWith(kodeSampel: [...p.kodeSampel, kode])
            : p,
    ];
  }

  // Jenis and dates

  void setJenis(PupukLabMaster master, int id) {
    if (state.jenisSampelId == id) return;
    state = state.withJenis(master, id);
  }

  /// Moves the receipt date with the memo until the user picks one.
  void setMemo(DateTime memo) {
    final draft = state;
    state = draft.copyWith(
      tanggalMemo: memo,
      tanggalTerima: draft.tanggalTerimaEdited
          ? draft.tanggalTerima
          : PupukLabForm.defaultTanggalTerima(memo),
    );
  }

  void setTanggalTerima(DateTime value) {
    state = state.copyWith(
      tanggalTerima: DateTime(value.year, value.month, value.day),
      tanggalTerimaEdited: true,
    );
  }

  // Parameters

  void addParameter() {
    final draft = state;
    state = draft.copyWith(
      parameters: [
        ...draft.parameters,
        PupukLabParameterDraft(
          key: draft.nextParameterKey,
          totalSample: draft.samples.isEmpty ? 1 : draft.samples.length,
          kodeSampel: draft.kodes,
        ),
      ],
      nextParameterKey: draft.nextParameterKey + 1,
    );
  }

  void removeParameter(int key) {
    state = state.copyWith(
      parameters: [
        for (final p in state.parameters)
          if (p.key != key) p,
      ],
    );
  }

  void updateParameter(
    int key,
    PupukLabParameterDraft Function(PupukLabParameterDraft row) change,
  ) {
    state = state.copyWith(
      parameters: [
        for (final p in state.parameters) p.key == key ? change(p) : p,
      ],
    );
  }

  // Photos

  void addPhoto(String path) {
    if (state.fotoPaths.contains(path)) return;
    state = state.copyWith(fotoPaths: [...state.fotoPaths, path]);
  }

  void removePhoto(String path) {
    state = state.copyWith(
      fotoPaths: [
        for (final p in state.fotoPaths)
          if (p != path) p,
      ],
    );
  }

  // Save

  /// Stores the receipt on the device. Returns the saved row.
  Future<PupukLab> save(PupukLabMaster? master) async {
    final validation = state.validate(master);
    if (!validation.isValid) throw PupukLabInvalidException(validation);

    final dao = ref.read(pupukLabDaoProvider);
    final receipt = state.toReceipt(newClientUuid: const Uuid().v4());
    final PupukLab saved;
    if (receipt.id == null) {
      final id = await dao.insert(receipt);
      saved = PupukLab(
        id: id,
        clientUuid: receipt.clientUuid,
        noSurat: receipt.noSurat,
        samples: receipt.samples,
        form: receipt.form,
        fotoPaths: receipt.fotoPaths,
        createdAt: receipt.createdAt,
      );
    } else {
      await dao.updateDraft(receipt);
      saved = receipt;
    }
    await ref
        .read(formCompletionSuggestionsDaoProvider)
        .saveValues(
          emails: [...receipt.form.emailTo, ...receipt.form.emailCc],
          whatsappNumbers: receipt.form.noHp,
        );
    ref.invalidate(reservedPupukLabKodeProvider);
    ref.read(fertilizerCountsRefreshProvider.notifier).state++;
    state = state.copyWith(dirty: false);
    return saved;
  }
}
