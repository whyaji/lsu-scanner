import 'dart:io';

import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/database/models/kirim_sertifikat_estate.dart';
import '../../../core/utils/date_utils.dart' as app_date_utils;

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
  List<DataSampelPupuk> _options = [];

  DataSampelPupuk? _selected;
  DateTime? _tanggalKirim;
  final TextEditingController _rekomendasiController = TextEditingController();
  String? _fileSertifikatPath;
  bool _processingPdf = false;
  final ImagePicker _imagePicker = ImagePicker();
  final PdfViewerController _pdfViewerController = PdfViewerController();

  @override
  void initState() {
    super.initState();
    _loadOptions();
  }

  @override
  void dispose() {
    _rekomendasiController.dispose();
    _pdfViewerController.dispose();
    super.dispose();
  }

  Future<void> _loadOptions() async {
    setState(() => _loading = true);
    final list = await _dbHelper.getEligibleDataSampelPupukKirimSertifikat();
    if (!mounted) return;
    setState(() {
      _options = list;
      _loading = false;
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

  Future<DataSampelPupuk?> _showSearchableSelect() async {
    return showDialog<DataSampelPupuk>(
      context: context,
      builder: (ctx) {
        final controller = TextEditingController();
        List<DataSampelPupuk> filtered = List.of(_options);

        void applyFilter(String q) {
          final query = q.trim().toLowerCase();
          filtered = query.isEmpty
              ? List.of(_options)
              : _options
                    .where(
                      (e) => (e.kodeSampel ?? '').toLowerCase().contains(query),
                    )
                    .toList();
        }

        return StatefulBuilder(
          builder: (ctx2, setState2) {
            return AlertDialog(
              title: const Text('Pilih Kode Sampel'),
              content: SizedBox(
                width: double.maxFinite,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: controller,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search),
                        hintText: 'Cari kode sampel…',
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
                                final item = filtered[index];
                                final kode = item.kodeSampel ?? '-';
                                return ListTile(
                                  title: Text(kode),
                                  subtitle:
                                      item.noSertifikat != null &&
                                          item.noSertifikat!.isNotEmpty
                                      ? Text(
                                          'No. Sertifikat: ${item.noSertifikat}',
                                        )
                                      : null,
                                  onTap: () => Navigator.of(ctx).pop(item),
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

    final selected = _selected!;
    final tanggalIso = _tanggalIso!;
    final rekomendasi = _rekomendasiController.text.trim();
    final fileSertifikatPath = _fileSertifikatPath!;

    final nowIso = DateTime.now().toIso8601String();
    final row = KirimSertifikatEstate(
      dataSampelPupukId: selected.id,
      kodeSampel: selected.kodeSampel ?? '',
      tanggalKirimSertifikatEstate: tanggalIso,
      rekomendasi: rekomendasi,
      fileSertifikat: fileSertifikatPath,
      createdAt: nowIso,
    );

    await _dbHelper.insertKirimSertifikatEstate(row);
    await _dbHelper.updateDataSampelPupukTanggalKirimSertifikatEstate(
      selected.id,
      tanggalIso,
    );

    if (!mounted) return;
    Navigator.of(context).pop(true);
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
    setState(() {
      _fileSertifikatPath = path;
    });
  }

  Future<void> _takePhotoAndConvertToPdf() async {
    final captured = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 90,
    );
    if (!mounted || captured == null || captured.path.isEmpty) {
      return;
    }

    setState(() => _processingPdf = true);
    try {
      final pdfPath = await _createPdfFromImage(captured.path);
      if (!mounted) return;
      setState(() {
        _fileSertifikatPath = pdfPath;
      });
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

  void _openPdfPreviewFullScreen() {
    if (_fileSertifikatPath == null || _fileSertifikatPath!.isEmpty) return;
    final path = _fileSertifikatPath!;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Preview PDF Sertifikat'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SfPdfViewer.file(
            File(path),
            canShowPaginationDialog: false,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        ),
      ),
    );
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
        content: const Text(
          'Pastikan semua data sudah benar sebelum menyimpan.',
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
    Navigator.of(context).pop();
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
        Navigator.of(context).pop();
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
                            if (_options.isEmpty) return;
                            final picked = await _showSearchableSelect();
                            if (!mounted || picked == null) return;
                            setState(() => _selected = picked);
                          },
                          borderRadius: BorderRadius.circular(12),
                          child: InputDecorator(
                            decoration: InputDecoration(
                              labelText: 'Kode Sampel',
                              border: const OutlineInputBorder(),
                              errorText: (_selected == null)
                                  ? 'Kode sampel wajib dipilih'
                                  : null,
                              suffixIcon: const Icon(Icons.arrow_drop_down),
                            ),
                            child: Text(
                              _selected?.kodeSampel ?? 'Pilih kode sampel',
                            ),
                          ),
                        ),
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
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _rekomendasiController,
                          decoration: const InputDecoration(
                            labelText: 'Rekomendasi',
                            border: OutlineInputBorder(),
                          ),
                          validator: (v) {
                            final value = v?.trim() ?? '';
                            if (value.isEmpty) return 'Rekomendasi wajib diisi';
                            return null;
                          },
                          textInputAction: TextInputAction.done,
                        ),
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
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Preview halaman pertama PDF',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                                Align(
                                  alignment: Alignment.centerRight,
                                  child: TextButton.icon(
                                    onPressed: _openPdfPreviewFullScreen,
                                    icon: const Icon(Icons.open_in_full),
                                    label: const Text('Layar penuh'),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                SizedBox(
                                  height: 220,
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: InkWell(
                                      onTap: _openPdfPreviewFullScreen,
                                      child: SfPdfViewer.file(
                                        File(_fileSertifikatPath!),
                                        key: ValueKey(_fileSertifikatPath),
                                        controller: _pdfViewerController,
                                        canShowScrollHead: false,
                                        canShowScrollStatus: false,
                                        canShowPaginationDialog: false,
                                        onDocumentLoaded: (_) {
                                          _pdfViewerController.jumpToPage(1);
                                        },
                                        onDocumentLoadFailed: (details) {
                                          ScaffoldMessenger.of(
                                            context,
                                          ).showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Preview PDF gagal dimuat: ${details.error}',
                                              ),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                        const SizedBox(height: 24),
                        ElevatedButton(
                          onPressed: _options.isEmpty ? null : _confirmAndSave,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('Simpan'),
                        ),
                        if (_options.isEmpty) ...[
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada data yang memenuhi syarat (no sertifikat terisi & belum ada tanggal kirim sertifikat).',
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
