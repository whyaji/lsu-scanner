import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import '../../../core/constants/app_constants.dart';
import '../../../widgets/inline_pdf_preview_panel.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/database/models/kirim_sertifikat_estate.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

const _defaultRekomendasi = 'Pupuk dapat diaplikasi';

class _NoSuratGroup {
  const _NoSuratGroup({required this.noSurat, required this.samples});

  final String noSurat;
  final List<DataSampelPupuk> samples;
}

class KirimSertifikatFormScreen extends StatefulWidget {
  const KirimSertifikatFormScreen({super.key});

  @override
  State<KirimSertifikatFormScreen> createState() =>
      _KirimSertifikatFormScreenState();
}

class _KirimSertifikatFormScreenState extends State<KirimSertifikatFormScreen> {
  final _dbHelper = DatabaseHelper.instance;
  final _formKey = GlobalKey<FormState>();

  bool _loading = true;
  List<_NoSuratGroup> _noSuratGroups = [];

  String? _selectedNoSurat;
  List<DataSampelPupuk> _selectedSamples = [];
  final Map<int, TextEditingController> _rekomendasiControllers = {};
  DateTime? _tanggalKirim;
  String? _fileSertifikatPath;
  bool _processingPdf = false;
  final GlobalKey<InlinePdfPreviewPanelState> _pdfPanelKey =
      GlobalKey<InlinePdfPreviewPanelState>();
  final ImagePicker _imagePicker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _disposeRekomendasiControllers();
    super.dispose();
  }

  void _disposeRekomendasiControllers() {
    for (final controller in _rekomendasiControllers.values) {
      controller.dispose();
    }
    _rekomendasiControllers.clear();
  }

  void _initRekomendasiControllersForSamples(List<DataSampelPupuk> samples) {
    _disposeRekomendasiControllers();
    for (final sample in samples) {
      final existing = sample.rekomendasi?.trim() ?? '';
      _rekomendasiControllers[sample.id] = TextEditingController(
        text: existing.isNotEmpty ? existing : _defaultRekomendasi,
      );
    }
  }

  Future<void> _popRoute([Object? result]) async {
    await _pdfPanelKey.currentState?.prepareForRoutePop();
    if (!mounted) return;
    Navigator.of(context).pop(result);
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    final list = await _dbHelper.getEligibleDataSampelPupukKirimSertifikat();
    final byNoSurat = <String, List<DataSampelPupuk>>{};
    for (final item in list) {
      final noSurat = await _dbHelper.resolveNoSuratForDataSampelPupuk(
        item.id,
        fromData: item.noSurat,
      );
      if (noSurat == null || noSurat.isEmpty) continue;
      byNoSurat.putIfAbsent(noSurat, () => []).add(item);
    }
    final groups =
        byNoSurat.entries
            .map((e) => _NoSuratGroup(noSurat: e.key, samples: e.value))
            .toList()
          ..sort((a, b) => a.noSurat.compareTo(b.noSurat));

    if (!mounted) return;
    setState(() {
      _noSuratGroups = groups;
      _loading = false;
      if (_selectedNoSurat != null) {
        final match = groups
            .where((g) => g.noSurat == _selectedNoSurat)
            .toList();
        if (match.isEmpty) {
          _selectedNoSurat = null;
          _selectedSamples = [];
          _disposeRekomendasiControllers();
        } else {
          final newSamples = match.first.samples;
          final oldIds = _selectedSamples.map((s) => s.id).toSet();
          final newIds = newSamples.map((s) => s.id).toSet();
          _selectedSamples = newSamples;
          if (oldIds.length != newIds.length || !oldIds.containsAll(newIds)) {
            _initRekomendasiControllersForSamples(newSamples);
          }
        }
      }
    });
  }

  String? get _tanggalIso => _tanggalKirim?.toIso8601String();

  String get _tanggalDisplay => _tanggalKirim == null
      ? 'Pilih tanggal & waktu'
      : app_date_utils.DateUtils.formatDateTimeForDisplay(_tanggalKirim!);

  Future<void> _pickTanggalKirim() async {
    final now = DateTime.now();
    final initial = _tanggalKirim ?? now;
    final date = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (date == null || !mounted) return;
    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(initial),
    );
    if (time == null || !mounted) return;
    setState(() {
      _tanggalKirim = DateTime(
        date.year,
        date.month,
        date.day,
        time.hour,
        time.minute,
      );
    });
  }

  Future<_NoSuratGroup?> _showSearchableSelect() async {
    return showDialog<_NoSuratGroup>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        List<_NoSuratGroup> filtered = List.of(_noSuratGroups);

        void applyFilter(String q) {
          final query = q.trim().toLowerCase();
          filtered = query.isEmpty
              ? List.of(_noSuratGroups)
              : _noSuratGroups
                    .where((g) => g.noSurat.toLowerCase().contains(query))
                    .toList();
        }

        return StatefulBuilder(
          builder: (ctx2, setState2) {
            return AlertDialog(
              title: const Text('Pilih No. Surat'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari no. surat…',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (v) {
                        setState2(() => applyFilter(v));
                      },
                    ),
                    const SizedBox(height: 12),
                    Flexible(
                      child: filtered.isEmpty
                          ? const Center(child: Text('Tidak ada data'))
                          : ListView.builder(
                              shrinkWrap: true,
                              itemCount: filtered.length,
                              itemBuilder: (context, index) {
                                final group = filtered[index];
                                final kodes = group.samples
                                    .map((s) => s.kodeSampel ?? '-')
                                    .join(', ');
                                return ListTile(
                                  title: Text(group.noSurat),
                                  subtitle: Text(
                                    '${group.samples.length} sampel · $kodes',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  onTap: () => Navigator.of(ctx).pop(group),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Batal'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _save() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field yang wajib diisi.'),
        ),
      );
      return;
    }

    final tanggalIso = _tanggalIso!;
    final fileSertifikatPath = _fileSertifikatPath!;
    final nowIso = DateTime.now().toIso8601String();

    for (final sample in _selectedSamples) {
      final rekomendasi = _rekomendasiControllers[sample.id]?.text.trim() ?? '';
      final row = KirimSertifikatEstate(
        dataSampelPupukId: sample.id,
        kodeSampel: sample.kodeSampel ?? '',
        tanggalKirimSertifikatEstate: tanggalIso,
        rekomendasi: rekomendasi,
        fileSertifikat: fileSertifikatPath,
        createdAt: nowIso,
      );
      await _dbHelper.insertKirimSertifikatEstate(row);
      await _dbHelper.updateDataSampelPupukTanggalKirimSertifikatEstate(
        sample.id,
        tanggalIso,
        rekomendasi: rekomendasi,
      );
    }

    if (!mounted) return;
    await _popRoute(true);
  }

  Future<String> _createPdfFromImage(String imagePath) async {
    final imageFile = File(imagePath);
    final imageBytes = await imageFile.readAsBytes();
    final decodedImage = img.decodeImage(imageBytes);
    if (decodedImage == null) {
      throw Exception('Foto tidak valid untuk dijadikan PDF');
    }
    final imageProvider = pw.MemoryImage(imageBytes);
    final pdf = pw.Document();
    const pageMargin = 24.0;
    final contentWidth = PdfPageFormat.a4.width - (pageMargin * 2);
    final contentHeight = PdfPageFormat.a4.height - (pageMargin * 2);
    final imageAspectRatio = decodedImage.width / decodedImage.height;
    final contentAspectRatio = contentWidth / contentHeight;
    final targetWidth = imageAspectRatio > contentAspectRatio
        ? contentWidth
        : contentHeight * imageAspectRatio;
    final targetHeight = imageAspectRatio > contentAspectRatio
        ? contentWidth / imageAspectRatio
        : contentHeight;

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(pageMargin),
        build: (context) {
          return pw.Center(
            child: pw.SizedBox(
              width: targetWidth,
              height: targetHeight,
              child: pw.Image(imageProvider, fit: pw.BoxFit.fill),
            ),
          );
        },
      ),
    );

    final tempDir = await getTemporaryDirectory();
    final pdfFileName =
        'sertifikat_${DateTime.now().millisecondsSinceEpoch}.pdf';
    final pdfPath = p.join(tempDir.path, pdfFileName);
    final pdfFile = File(pdfPath);
    await pdfFile.writeAsBytes(await pdf.save(), flush: true);
    return pdfPath;
  }

  Future<void> _pickPdfFromFile() async {
    final result = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    final path = result?.files.single.path;
    if (!mounted || path == null || path.isEmpty) {
      return;
    }
    setState(() => _fileSertifikatPath = path);
  }

  Future<void> _takePhotoAndConvertToPdf() async {
    final captured = await _imagePicker.pickImage(
      source: ImageSource.camera,
      preferredCameraDevice: CameraDevice.rear,
      imageQuality: 90,
    );
    if (!mounted || captured == null || captured.path.isEmpty) {
      return;
    }

    setState(() => _processingPdf = true);
    try {
      final pdfPath = await _createPdfFromImage(captured.path);
      if (!mounted) return;
      setState(() => _fileSertifikatPath = pdfPath);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gagal membuat PDF dari foto. Silakan coba lagi.'),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _processingPdf = false);
      }
    }
  }

  Future<void> _pickSertifikatFile() async {
    final action = await showModalBottomSheet<String>(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.picture_as_pdf),
              title: const Text('Pilih file PDF'),
              onTap: () => Navigator.of(ctx).pop('file'),
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt),
              title: const Text('Ambil foto & ubah ke PDF'),
              onTap: () => Navigator.of(ctx).pop('camera'),
            ),
          ],
        ),
      ),
    );

    if (!mounted || action == null) return;
    if (action == 'file') {
      await _pickPdfFromFile();
      return;
    }
    await _takePhotoAndConvertToPdf();
  }

  Future<bool> _showConfirmBack() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Keluar?'),
        content: const Text(
          'Data yang telah diisi akan hilang. Yakin ingin kembali?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Keluar'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<bool> _showConfirmSave() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Simpan data?'),
        content: Text(
          _selectedSamples.length > 1
              ? 'File sertifikat dan tanggal kirim sama untuk '
                    '${_selectedSamples.length} sampel (No. Surat $_selectedNoSurat). '
                    'Rekomendasi disimpan per sampel.'
              : 'Pastikan semua data sudah benar sebelum menyimpan.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Batal'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Ya, simpan'),
          ),
        ],
      ),
    );
    return result ?? false;
  }

  Future<void> _onBackPressed() async {
    if (!mounted) return;
    final ok = await _showConfirmBack();
    if (!mounted || !ok) return;
    await _popRoute();
  }

  Future<void> _confirmAndSave() async {
    final isValid = _formKey.currentState?.validate() ?? false;
    if (!isValid) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Mohon lengkapi semua field yang wajib diisi.'),
        ),
      );
      return;
    }
    if (!mounted) return;
    final ok = await _showConfirmSave();
    if (!mounted || !ok) return;
    await _save();
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, Object? result) async {
        if (didPop) return;
        final ok = await _showConfirmBack();
        if (!context.mounted || !ok) return;
        await _popRoute();
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Kirim Sertifikat'),
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back),
            onPressed: _onBackPressed,
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.refresh),
              onPressed: _loading ? null : _loadOptions,
              tooltip: 'Muat ulang',
            ),
          ],
        ),
        body: SafeArea(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : SingleChildScrollView(
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: EdgeInsets.fromLTRB(
                    16,
                    16,
                    16,
                    16 + MediaQuery.of(context).viewInsets.bottom,
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        InkWell(
                          onTap: () async {
                            if (_noSuratGroups.isEmpty) return;
                            final picked = await _showSearchableSelect();
                            if (!mounted || picked == null) return;
                            setState(() {
                              _selectedNoSurat = picked.noSurat;
                              _selectedSamples = List.of(picked.samples);
                              _initRekomendasiControllersForSamples(
                                _selectedSamples,
                              );
                            });
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'No. Surat',
                              border: const OutlineInputBorder(),
                              errorText:
                                  (_selectedNoSurat == null ||
                                      _selectedSamples.isEmpty)
                                  ? 'No. surat wajib dipilih'
                                  : null,
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(_selectedNoSurat ?? 'Pilih no. surat'),
                          ),
                        ),
                        if (_selectedSamples.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Sampel (${_selectedSamples.length})',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'File sertifikat dan tanggal kirim sama untuk '
                                    'semua sampel. Isi rekomendasi per sampel di bawah.',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.bodySmall,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _pickTanggalKirim,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Tanggal Kirim Sertifikat',
                              border: const OutlineInputBorder(),
                              errorText: (_tanggalKirim == null)
                                  ? 'Tanggal kirim wajib diisi'
                                  : null,
                              suffixIcon: const Icon(Icons.calendar_month),
                            ),
                            child: Text(_tanggalDisplay),
                          ),
                        ),
                        if (_selectedSamples.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            'Rekomendasi per Sampel',
                            style: Theme.of(context).textTheme.titleSmall
                                ?.copyWith(fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 8),
                          ..._selectedSamples.map((sample) {
                            final kode = sample.kodeSampel ?? '-';
                            final controller =
                                _rekomendasiControllers[sample.id];
                            if (controller == null) {
                              return const SizedBox.shrink();
                            }
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 12),
                              child: TextFormField(
                                controller: controller,
                                decoration: InputDecoration(
                                  labelText: 'Rekomendasi — $kode',
                                  border: const OutlineInputBorder(),
                                ),
                                validator: (v) {
                                  final value = v?.trim() ?? '';
                                  if (value.isEmpty) {
                                    return 'Rekomendasi wajib diisi';
                                  }
                                  return null;
                                },
                                textInputAction: TextInputAction.next,
                              ),
                            );
                          }),
                        ],
                        const SizedBox(height: 16),
                        InkWell(
                          onTap: _processingPdf ? null : _pickSertifikatFile,
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'File Sertifikat (PDF)',
                              border: const OutlineInputBorder(),
                              errorText:
                                  (_fileSertifikatPath == null ||
                                      _fileSertifikatPath!.isEmpty)
                                  ? 'File PDF sertifikat wajib dipilih'
                                  : null,
                              suffixIcon: const Icon(Icons.attach_file),
                            ),
                            child: Text(
                              _processingPdf
                                  ? 'Membuat PDF dari foto...'
                                  : _fileSertifikatPath == null ||
                                        _fileSertifikatPath!.isEmpty
                                  ? 'Pilih file PDF'
                                  : p.basename(_fileSertifikatPath!),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ),
                        if (_fileSertifikatPath != null &&
                            _fileSertifikatPath!.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              border: Border.all(color: Colors.grey.shade400),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: InlinePdfPreviewPanel(
                              key: _pdfPanelKey,
                              filePath: _fileSertifikatPath!,
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _noSuratGroups.isEmpty
                              ? null
                              : _confirmAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Simpan'),
                        ),
                        if (_noSuratGroups.isEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada data yang memenuhi syarat (no. sertifikat terisi, '
                            'belum kirim sertifikat, dan memiliki no. surat dari Kirim Lab).',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
