import '../../../../core/network/models/pupuk_upload_models.dart';

/// Upload progress for the UI, counted per row across all activity types.
class UploadSampelPupukProgress {
  final int total;
  final int current;
  final int percentage;
  final String currentItem;

  UploadSampelPupukProgress({
    required this.total,
    required this.current,
    required this.percentage,
    required this.currentItem,
  });
}

/// A row that did not reach the server.
class PupukUploadFailure {
  const PupukUploadFailure({
    required this.id,
    required this.label,
    required this.message,
    required this.retryable,
  });

  /// Local row id.
  final int id;

  /// What the user recognises the row by (sample code, no. surat).
  final String label;
  final String message;

  /// The next upload may succeed without the user changing anything.
  final bool retryable;
}

/// Outcome of one activity type in one upload run.
class PupukUploadTypeResult {
  const PupukUploadTypeResult({
    required this.type,
    this.uploaded = 0,
    this.failures = const [],
  });

  final String type;
  final int uploaded;
  final List<PupukUploadFailure> failures;

  int get failed => failures.length;

  PupukUploadTypeResult withExtraFailures(List<PupukUploadFailure> extra) =>
      PupukUploadTypeResult(
        type: type,
        uploaded: uploaded,
        failures: [...failures, ...extra],
      );
}

/// Services a batch needs while preparing its rows.
class PupukUploadContext {
  PupukUploadContext({
    required this.total,
    required this.compress,
    required this.retryDelay,
    required this.onProgress,
  });

  final int total;
  final Future<String?> Function(String path) compress;
  final Duration retryDelay;
  final void Function(UploadSampelPupukProgress progress) onProgress;
  int _done = 0;

  /// Shows [label] as the row (or group) being worked on.
  void report(String label) {
    final current = _done + 1;
    onProgress(
      UploadSampelPupukProgress(
        total: total,
        current: current,
        percentage: (current / total * 100).round(),
        currentItem: label,
      ),
    );
  }

  void rowDone() => _done++;

  /// One retry after [retryDelay] when [attempt] returns null.
  Future<R?> withRetry<R>(Future<R?> Function() attempt) async {
    final first = await attempt();
    if (first != null) return first;
    await Future<void>.delayed(retryDelay);
    return attempt();
  }
}

/// Rows of one type that are ready to send.
class PreparedPupukUpload {
  const PreparedPupukUpload({
    required this.type,
    required this.items,
    required this.sentLabels,
    required this.photoFailures,
    required this.apply,
  });

  final String type;

  /// JSON items for the payload.
  final List<Map<String, dynamic>> items;

  /// Local id to label of every row in [items].
  final Map<int, String> sentLabels;

  /// Rows already marked `error` locally because their photo never uploaded.
  final List<PupukUploadFailure> photoFailures;

  /// Writes the server verdict into the local rows.
  final Future<PupukUploadTypeResult> Function(
    SampelPupukUploadResponse response,
  )
  apply;
}

/// Pending rows of one type, loaded but not yet prepared.
abstract class PupukUploadBatch {
  String get type;
  int get rowCount;
  Future<PreparedPupukUpload> prepare(PupukUploadContext context);
}

/// Everything that differs between activity types. The pipeline owns ordering,
/// progress, photo retry and the single upload request; a strategy only says
/// which rows are pending, how rows share a photo, what the payload item looks
/// like and how the server's answer is stored.
///
/// To add a type: implement this, register it in `uploadSampelPupukProvider`,
/// and add the key to `kUploadablePupukActivityTypes` and the payload/response
/// models.
abstract class PupukUploadStrategy<T> {
  String get type;

  /// Stored on rows whose photo could not be uploaded after the retry.
  String get photoFailureMessage => 'Gagal mengunggah foto';

  Future<List<T>> loadPending();

  int idOf(T row);

  /// Sample code or no. surat shown in progress and failure lists.
  String labelOf(T row);

  /// Rows that share one upload of the same file; default is one row per group.
  List<List<T>> groupRows(List<T> rows) => [
    for (final row in rows) [row],
  ];

  /// Local files to upload for a group; empty when there is nothing to send.
  List<String> localFiles(List<T> group);

  /// One upload attempt for [path] (already compressed); the server path, or
  /// null when it failed.
  Future<String?> uploadFile(List<T> group, String path);

  /// Payload item for [row]. [serverFiles] are the uploaded paths of its group
  /// in [localFiles] order, empty when the group had no local file.
  Map<String, dynamic> buildItem(T row, List<String> serverFiles);

  Future<void> markPhotoFailure(T row);

  Future<PupukUploadTypeResult> applyResult(
    SampelPupukUploadResponse response,
    String Function(int id) labelFor,
  );

  Future<PupukUploadBatch> load() async =>
      _StrategyBatch<T>(this, await loadPending());
}

class _StrategyBatch<T> implements PupukUploadBatch {
  _StrategyBatch(this._strategy, this._rows);

  final PupukUploadStrategy<T> _strategy;
  final List<T> _rows;

  @override
  String get type => _strategy.type;

  @override
  int get rowCount => _rows.length;

  @override
  Future<PreparedPupukUpload> prepare(PupukUploadContext context) async {
    final items = <Map<String, dynamic>>[];
    final sentLabels = <int, String>{};
    final photoFailures = <PupukUploadFailure>[];

    for (final group in _strategy.groupRows(_rows)) {
      final lead = group.first;
      final serverFiles = <String>[];

      final localFiles = _strategy.localFiles(group);
      if (localFiles.isNotEmpty) {
        context.report(
          group.length > 1
              ? '${_strategy.labelOf(lead)} (+${group.length - 1} sampel)'
              : _strategy.labelOf(lead),
        );
        var allUploaded = true;
        for (final file in localFiles) {
          final path = await context.compress(file) ?? file;
          final serverPath = await context.withRetry(
            () => _strategy.uploadFile(group, path),
          );
          if (serverPath == null) {
            allUploaded = false;
            break;
          }
          serverFiles.add(serverPath);
        }
        if (!allUploaded) {
          for (final row in group) {
            await _strategy.markPhotoFailure(row);
            photoFailures.add(
              PupukUploadFailure(
                id: _strategy.idOf(row),
                label: _strategy.labelOf(row),
                message: _strategy.photoFailureMessage,
                retryable: true,
              ),
            );
            context.rowDone();
          }
          continue;
        }
      }

      for (final row in group) {
        context.report(_strategy.labelOf(row));
        items.add(_strategy.buildItem(row, serverFiles));
        sentLabels[_strategy.idOf(row)] = _strategy.labelOf(row);
        context.rowDone();
      }
    }

    return PreparedPupukUpload(
      type: type,
      items: items,
      sentLabels: sentLabels,
      photoFailures: photoFailures,
      apply: (response) => _strategy.applyResult(
        response,
        (id) => sentLabels[id] ?? '#$id',
      ),
    );
  }
}
