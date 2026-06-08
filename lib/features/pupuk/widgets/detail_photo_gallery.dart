import 'dart:io';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import '../../../core/theme/app_spacing.dart';
import '../../sample/screens/full_screen_image_preview_screen.dart';

String resolveProtectedMediaUrl(String path) {
  var normalized = path.trim();
  if (normalized.startsWith('http://') || normalized.startsWith('https://')) {
    return normalized;
  }
  if (normalized.startsWith('api/protected/')) {
    normalized = '/${normalized.replaceFirst(RegExp(r'^api/'), '')}';
  } else if (normalized.startsWith('protected/')) {
    normalized = '/$normalized';
  } else if (!normalized.startsWith('/')) {
    normalized = '/$normalized';
  }
  return '${ApiConstants.baseUrlWithoutApi}$normalized';
}

bool isLocalMediaPath(String? path) {
  if (path == null || path.trim().isEmpty) return false;
  final trimmed = path.trim();
  if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
    return false;
  }
  if (trimmed.startsWith('/protected/') || trimmed.startsWith('protected/')) {
    return false;
  }
  return File(trimmed).existsSync();
}

List<String> parseRegistrasiLabPhotoUrls(String? value) {
  if (value == null || value.trim().isEmpty) return [];
  return value
      .split(',')
      .map((item) => item.trim())
      .where((item) => item.isNotEmpty)
      .toList();
}

class DetailPhotoGallery extends StatelessWidget {
  const DetailPhotoGallery({
    super.key,
    this.fotoKirimDariEstate,
    this.fotoKirimLab,
    this.fotoRegistrasiLab,
  });

  final String? fotoKirimDariEstate;
  final String? fotoKirimLab;
  final String? fotoRegistrasiLab;

  @override
  Widget build(BuildContext context) {
    final registrasiUrls = parseRegistrasiLabPhotoUrls(fotoRegistrasiLab);
    final hasEstate =
        fotoKirimDariEstate != null && fotoKirimDariEstate!.trim().isNotEmpty;
    final hasLab = fotoKirimLab != null && fotoKirimLab!.trim().isNotEmpty;

    if (!hasEstate && !hasLab && registrasiUrls.isEmpty) {
      return const SizedBox.shrink();
    }

    final theme = Theme.of(context);

    return Card(
      margin: EdgeInsets.zero,
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Dokumentasi Foto',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount = constraints.maxWidth >= 520 ? 2 : 1;
                final tiles = <Widget>[
                  if (hasEstate)
                    _PhotoTile(
                      label: 'Kirim dari Estate',
                      protectedPath: fotoKirimDariEstate,
                    ),
                  if (hasLab)
                    _PhotoTile(label: 'Kirim Lab', protectedPath: fotoKirimLab),
                  for (var i = 0; i < registrasiUrls.length; i++)
                    _PhotoTile(
                      label: registrasiUrls.length > 1
                          ? 'Registrasi Lab ${i + 1}'
                          : 'Registrasi Lab',
                      directUrl: registrasiUrls[i],
                    ),
                ];

                return GridView.count(
                  crossAxisCount: crossAxisCount,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: AppSpacing.sm,
                  crossAxisSpacing: AppSpacing.sm,
                  childAspectRatio: crossAxisCount == 1 ? 1.45 : 1.1,
                  children: tiles,
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _PhotoTile extends StatelessWidget {
  const _PhotoTile({required this.label, this.protectedPath, this.directUrl});

  final String label;
  final String? protectedPath;
  final String? directUrl;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelMedium?.copyWith(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: directUrl != null
              ? _DirectRemoteImage(url: directUrl!, title: label)
              : _ProtectedRemoteImage(path: protectedPath!, title: label),
        ),
      ],
    );
  }
}

class _ProtectedRemoteImage extends StatefulWidget {
  const _ProtectedRemoteImage({required this.path, required this.title});

  final String path;
  final String title;

  @override
  State<_ProtectedRemoteImage> createState() => _ProtectedRemoteImageState();
}

class _ProtectedRemoteImageState extends State<_ProtectedRemoteImage> {
  Uint8List? _bytes;
  bool _loading = true;
  bool _failed = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (isLocalMediaPath(widget.path)) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = false;
      });
      return;
    }

    try {
      final url = resolveProtectedMediaUrl(widget.path);
      final response = await ApiClient().dio.get<List<int>>(
        url,
        options: Options(responseType: ResponseType.bytes),
      );
      if (!mounted) return;
      setState(() {
        _bytes = Uint8List.fromList(response.data ?? []);
        _loading = false;
        _failed = _bytes == null || _bytes!.isEmpty;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _failed = true;
      });
    }
  }

  void _openPreview() {
    if (isLocalMediaPath(widget.path)) {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => FullScreenImagePreviewScreen(
            imagePath: widget.path,
            title: widget.title,
          ),
        ),
      );
      return;
    }
    if (_bytes == null || _bytes!.isEmpty) return;
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            _FullScreenBytesImage(title: widget.title, bytes: _bytes!),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const _PhotoFrame(
        child: Center(child: CircularProgressIndicator()),
      );
    }

    final displayLink = isLocalMediaPath(widget.path)
        ? widget.path
        : resolveProtectedMediaUrl(widget.path);

    if (isLocalMediaPath(widget.path)) {
      return _PhotoFrame(
        onTap: _openPreview,
        child: Image.file(
          File(widget.path),
          fit: BoxFit.cover,
          width: double.infinity,
          height: double.infinity,
          errorBuilder: (_, _, _) => _PhotoPlaceholder(link: displayLink),
        ),
      );
    }

    if (_failed || _bytes == null) {
      return _PhotoFrame(child: _PhotoPlaceholder(link: displayLink));
    }

    return _PhotoFrame(
      onTap: _openPreview,
      child: Image.memory(
        _bytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        errorBuilder: (_, _, _) => _PhotoPlaceholder(link: displayLink),
      ),
    );
  }
}

class _DirectRemoteImage extends StatelessWidget {
  const _DirectRemoteImage({required this.url, required this.title});

  final String url;
  final String title;

  void _openPreview(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => _FullScreenNetworkImage(title: title, url: url),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return _PhotoFrame(
      onTap: () => _openPreview(context),
      child: Image.network(
        url,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        loadingBuilder: (context, child, progress) {
          if (progress == null) return child;
          return const Center(child: CircularProgressIndicator());
        },
        errorBuilder: (_, _, _) => _PhotoPlaceholder(link: url),
      ),
    );
  }
}

class _PhotoFrame extends StatelessWidget {
  const _PhotoFrame({required this.child, this.onTap});

  final Widget child;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Material(
      color: colorScheme.surfaceContainerHighest.withValues(alpha: 0.45),
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(onTap: onTap, child: child),
    );
  }
}

class _PhotoPlaceholder extends StatelessWidget {
  const _PhotoPlaceholder({this.link});

  final String? link;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final resolvedLink = link?.trim();

    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.image_not_supported,
              color: colorScheme.onSurfaceVariant,
            ),
            const SizedBox(height: 4),
            Text(
              'Foto tidak tersedia',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w600,
              ),
            ),
            if (resolvedLink != null && resolvedLink.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(
                resolvedLink,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: 10,
                ),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _FullScreenBytesImage extends StatelessWidget {
  const _FullScreenBytesImage({required this.title, required this.bytes});

  final String title;
  final Uint8List bytes;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        child: Center(child: Image.memory(bytes, fit: BoxFit.contain)),
      ),
    );
  }
}

class _FullScreenNetworkImage extends StatelessWidget {
  const _FullScreenNetworkImage({required this.title, required this.url});

  final String title;
  final String url;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.black87,
        foregroundColor: Colors.white,
      ),
      body: InteractiveViewer(
        child: Center(
          child: Image.network(
            url,
            fit: BoxFit.contain,
            loadingBuilder: (context, child, progress) {
              if (progress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (_, _, _) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white54,
              size: 64,
            ),
          ),
        ),
      ),
    );
  }
}
