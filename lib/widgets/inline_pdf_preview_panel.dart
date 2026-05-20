import 'dart:io';

import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_pdfviewer/pdfviewer.dart';

import '../core/constants/app_constants.dart';

/// Single-page inline PDF viewer (owns its [PdfViewerController]).
class InlinePdfPreview extends StatefulWidget {
  const InlinePdfPreview({
    super.key,
    required this.filePath,
    this.onLoadFailed,
  });

  final String filePath;
  final void Function(String error)? onLoadFailed;

  @override
  State<InlinePdfPreview> createState() => _InlinePdfPreviewState();
}

class _InlinePdfPreviewState extends State<InlinePdfPreview> {
  final PdfViewerController _controller = PdfViewerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SfPdfViewer.file(
      File(widget.filePath),
      controller: _controller,
      canShowScrollHead: false,
      canShowScrollStatus: false,
      canShowPaginationDialog: false,
      onDocumentLoadFailed: (details) {
        widget.onLoadFailed?.call(details.error);
      },
    );
  }
}

/// Fixed-height inline PDF with optional full-screen; unmounts viewer before route pop.
class InlinePdfPreviewPanel extends StatefulWidget {
  const InlinePdfPreviewPanel({
    super.key,
    required this.filePath,
    this.title = 'Preview halaman pertama PDF',
    this.height = 220,
    this.padding,
    this.wrapInCard = false,
    this.titleStyle,
  });

  final String filePath;
  final String title;
  final double height;
  final EdgeInsetsGeometry? padding;
  final bool wrapInCard;
  final TextStyle? titleStyle;

  @override
  State<InlinePdfPreviewPanel> createState() => InlinePdfPreviewPanelState();
}

class InlinePdfPreviewPanelState extends State<InlinePdfPreviewPanel> {
  bool _showInlineViewer = true;
  int _viewerKey = 0;

  /// Hides the inline viewer so the parent route can pop without SfPdfViewer layout errors.
  Future<void> prepareForRoutePop() async {
    if (!_showInlineViewer) return;
    setState(() => _showInlineViewer = false);
    await Future<void>.delayed(Duration.zero);
  }

  bool get _routeIsCurrent => ModalRoute.of(context)?.isCurrent ?? true;

  bool get _shouldRenderViewer => _showInlineViewer && _routeIsCurrent;

  @override
  void didUpdateWidget(InlinePdfPreviewPanel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.filePath != widget.filePath) {
      _viewerKey++;
      _showInlineViewer = true;
    }
  }

  Future<void> _openFullScreen() async {
    setState(() => _showInlineViewer = false);

    await Navigator.of(context).push<void>(
      MaterialPageRoute<void>(
        builder: (_) => Scaffold(
          appBar: AppBar(
            title: const Text('Preview PDF Sertifikat'),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: SfPdfViewer.file(
            File(widget.filePath),
            canShowPaginationDialog: false,
            canShowScrollHead: true,
            canShowScrollStatus: true,
          ),
        ),
      ),
    );

    if (!mounted) return;
    setState(() {
      _viewerKey++;
      _showInlineViewer = true;
    });
  }

  @override
  void deactivate() {
    _showInlineViewer = false;
    super.deactivate();
  }

  void _onLoadFailed(String error) {
    if (!mounted) return;
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text('Preview PDF gagal dimuat: $error')));
  }

  Widget _buildPreviewArea() {
    return SizedBox(
      height: widget.height,
      width: double.infinity,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: _shouldRenderViewer
            ? Stack(
                fit: StackFit.expand,
                children: [
                  InlinePdfPreview(
                    key: ValueKey('${widget.filePath}_$_viewerKey'),
                    filePath: widget.filePath,
                    onLoadFailed: _onLoadFailed,
                  ),
                  Positioned.fill(
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(onTap: _openFullScreen),
                    ),
                  ),
                ],
              )
            : ColoredBox(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                child: const Center(
                  child: SizedBox(
                    width: 28,
                    height: 28,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
      ),
    );
  }

  Widget _buildInner() {
    final titleStyle =
        widget.titleStyle ??
        TextStyle(
          fontWeight: FontWeight.w600,
          color: Theme.of(context).colorScheme.onSurface,
        );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(widget.title, style: titleStyle),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            onPressed: _openFullScreen,
            icon: const Icon(Icons.open_in_full),
            label: const Text('Layar penuh'),
          ),
        ),
        const SizedBox(height: 8),
        _buildPreviewArea(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.wrapInCard) {
      return Card(
        elevation: 2,
        child: Padding(
          padding: widget.padding ?? const EdgeInsets.all(16),
          child: _buildInner(),
        ),
      );
    }
    if (widget.padding != null) {
      return Padding(padding: widget.padding!, child: _buildInner());
    }
    return _buildInner();
  }
}
