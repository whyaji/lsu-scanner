import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/database/database_helper.dart';
import '../../../core/database/models/data_sampel_pupuk.dart';
import '../../../core/network/api_client.dart';
import '../../../core/network/api_service.dart';
import '../../../core/network/models/api_response.dart';
import '../../../core/network/models/sampel_pupuk_models.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../widgets/app_empty_state.dart';
import '../../../widgets/app_loading_state.dart';
import '../../regional/providers/regional_provider.dart';
import '../constants/data_sampel_pupuk_progress.dart';
import '../providers/sync_sampel_pupuk_provider.dart';
import '../widgets/list_progress_tabs.dart';
import 'data_sampel_pupuk_detail_screen.dart';

class DataSampelPupukListScreen extends ConsumerStatefulWidget {
  const DataSampelPupukListScreen({super.key});

  @override
  ConsumerState<DataSampelPupukListScreen> createState() =>
      _DataSampelPupukListScreenState();
}

class _DataSampelPupukListScreenState
    extends ConsumerState<DataSampelPupukListScreen> {
  final DatabaseHelper _dbHelper = DatabaseHelper.instance;
  final ApiService _apiService = ApiService(ApiClient().dio);
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DataSampelPupuk> _items = [];
  Map<DataSampelPupukProgress, int> _counts = emptyProgressCounts();
  DataSampelPupukProgress _activeProgress = DataSampelPupukProgress.semua;

  bool _isOnline = false;
  bool _loading = true;
  bool _loadingMore = false;
  int _page = 1;
  int _totalPages = 1;
  Timer? _searchDebounce;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    _bootstrap();
  }

  @override
  void dispose() {
    _searchDebounce?.cancel();
    _searchController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (!_isOnline || _loading || _loadingMore || _page >= _totalPages) return;
    final position = _scrollController.position;
    if (position.pixels >= position.maxScrollExtent - 240) {
      _loadOnlineNextPage();
    }
  }

  Future<void> _bootstrap({bool preferOnline = true}) async {
    setState(() => _loading = true);
    if (preferOnline) {
      final onlineOk = await _tryLoadOnline(reset: true);
      if (onlineOk) return;
    }
    await _loadOffline();
  }

  bool _isNetworkFailure<T>(ApiResponse<T> response) {
    return !response.success &&
        (response.error?.code == 'NETWORK_ERROR' ||
            response.error?.message.toLowerCase().contains('network') == true);
  }

  Future<bool> _tryLoadOnline({required bool reset}) async {
    if (reset) {
      _page = 1;
      _totalPages = 1;
    }

    final search = _searchController.text.trim();
    final progressParam = progressToApiParam(_activeProgress);

    final listFuture = _apiService.getDataSampelPupukList(
      page: _page,
      limit: dataSampelPupukListPageSize,
      progress: progressParam,
      search: search.isEmpty ? null : search,
    );
    final countsFuture = reset
        ? _apiService.getDataSampelPupukProgressCounts(
            search: search.isEmpty ? null : search,
          )
        : Future.value(
            ApiResponse<Map<String, dynamic>>(success: true, data: null),
          );

    final results = await Future.wait([listFuture, countsFuture]);
    final listResponse =
        results[0] as ApiResponse<PaginatedDataSampelPupukResponse>;
    final countsResponse = results[1] as ApiResponse<Map<String, dynamic>>;

    if (_isNetworkFailure(listResponse)) return false;

    if (!listResponse.success || listResponse.data == null) {
      if (!mounted) return false;
      setState(() {
        _isOnline = true;
        _loading = false;
        _items = [];
      });
      return true;
    }

    final payload = listResponse.data!;
    if (!mounted) return false;

    setState(() {
      _isOnline = true;
      _loading = false;
      _loadingMore = false;
      _items = reset
          ? List<DataSampelPupuk>.from(payload.data)
          : [..._items, ...payload.data];
      _page = payload.page;
      _totalPages = payload.totalPages;
      if (countsResponse.success && countsResponse.data != null) {
        _counts = parseProgressCountsFromApi(countsResponse.data!);
      }
    });
    return true;
  }

  Future<void> _loadOnlineNextPage() async {
    if (_page >= _totalPages) return;
    setState(() => _loadingMore = true);
    _page += 1;
    final ok = await _tryLoadOnline(reset: false);
    if (!ok && mounted) {
      _page -= 1;
      setState(() => _loadingMore = false);
    }
  }

  Future<void> _loadOffline() async {
    final regional = ref.read(regionalProvider).selectedRegional;
    final allItems = await _dbHelper.getAllDataSampelPupuk(regional: regional);
    final query = _searchController.text;
    final filtered = allItems
        .where((item) => matchesProgressFilter(item, _activeProgress))
        .where((item) => matchesSearchQuery(item, query))
        .toList();

    if (!mounted) return;
    setState(() {
      _isOnline = false;
      _loading = false;
      _loadingMore = false;
      _items = filtered;
      _counts = countByProgress(allItems);
      _page = 1;
      _totalPages = 1;
    });
  }

  Future<void> _refresh() async {
    if (_isOnline) {
      await _bootstrap(preferOnline: true);
      return;
    }
    final regional = ref.read(regionalProvider).selectedRegional ?? 1;
    await ref.read(syncSampelPupukProvider.notifier).sync(regional);
    await _bootstrap(preferOnline: true);
  }

  void _onProgressChanged(DataSampelPupukProgress progress) {
    setState(() => _activeProgress = progress);
    if (_isOnline) {
      _bootstrap(preferOnline: true);
    } else {
      _loadOffline();
    }
  }

  void _onSearchChanged(String value) {
    setState(() {});
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 400), () {
      if (!mounted) return;
      if (_isOnline) {
        _bootstrap(preferOnline: true);
      } else {
        _loadOffline();
      }
    });
  }

  List<DataSampelPupuk> get _displayItems => _items;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final items = _displayItems;
    final syncState = ref.watch(syncSampelPupukProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Data Sampel Pupuk'),
        actions: [
          IconButton(
            tooltip: _isOnline ? 'Muat ulang' : 'Sinkronkan',
            onPressed: (_loading || syncState.isSyncing) ? null : _refresh,
            icon: (_loading || syncState.isSyncing)
                ? SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.onPrimary,
                    ),
                  )
                : Icon(_isOnline ? Icons.refresh : Icons.sync),
          ),
        ],
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.xs,
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _searchController,
                    onChanged: _onSearchChanged,
                    decoration: InputDecoration(
                      hintText: 'Cari kode, estate, supplier, PO...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                _onSearchChanged('');
                                setState(() {});
                              },
                            )
                          : null,
                      filled: true,
                      fillColor: colorScheme.surfaceContainerHighest.withValues(
                        alpha: 0.45,
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: AppSpacing.sm),
                _SourceChip(isOnline: _isOnline),
              ],
            ),
          ),
          ListProgressTabs(
            tabs: dataSampelPupukProgressTabs,
            value: _activeProgress,
            counts: _counts,
            isLoading: _loading && _isOnline,
            onChanged: _onProgressChanged,
          ),
          if (_isOnline && !_loading)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
              child: Text(
                'Halaman $_page dari $_totalPages',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          const SizedBox(height: AppSpacing.sm),
          Expanded(
            child: _loading
                ? const AppLoadingState(itemCount: 8)
                : RefreshIndicator(
                    onRefresh: _refresh,
                    child: items.isEmpty
                        ? ListView(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            children: [
                              SizedBox(
                                height:
                                    MediaQuery.of(context).size.height * 0.35,
                                child: AppEmptyState(
                                  title: _isOnline
                                      ? 'Tidak ada data pada filter ini.'
                                      : 'Belum ada data lokal. Sinkronkan atau sambungkan internet.',
                                ),
                              ),
                            ],
                          )
                        : ListView.separated(
                            controller: _scrollController,
                            physics: const AlwaysScrollableScrollPhysics(),
                            padding: AppSpacing.paddingScreen,
                            itemCount: items.length + (_loadingMore ? 1 : 0),
                            separatorBuilder: (_, _) =>
                                const SizedBox(height: AppSpacing.sm),
                            itemBuilder: (context, index) {
                              if (index >= items.length) {
                                return const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: AppSpacing.md,
                                  ),
                                  child: Center(
                                    child: CircularProgressIndicator(),
                                  ),
                                );
                              }

                              final item = items[index];
                              final progress = _isOnline
                                  ? _activeProgress ==
                                            DataSampelPupukProgress.semua
                                        ? resolveDataSampelPupukProgress(item)
                                        : _activeProgress
                                  : resolveDataSampelPupukProgress(item);
                              final tab = tabForProgress(
                                progress == DataSampelPupukProgress.semua
                                    ? resolveDataSampelPupukProgress(item)
                                    : progress,
                              );

                              return _SampelCard(
                                item: item,
                                tab: tab,
                                onTap: () {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) =>
                                          DataSampelPupukDetailScreen(
                                            id: item.id,
                                            preferOnline: _isOnline,
                                          ),
                                    ),
                                  );
                                },
                              );
                            },
                          ),
                  ),
          ),
        ],
      ),
    );
  }
}

class _SourceChip extends StatelessWidget {
  const _SourceChip({required this.isOnline});

  final bool isOnline;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: (isOnline ? Colors.green : colorScheme.tertiary).withValues(
          alpha: 0.12,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: (isOnline ? Colors.green : colorScheme.tertiary).withValues(
            alpha: 0.35,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isOnline ? Icons.cloud_done_outlined : Icons.storage_outlined,
            size: 16,
            color: isOnline ? Colors.green.shade700 : colorScheme.tertiary,
          ),
          const SizedBox(width: 4),
          Text(
            isOnline ? 'Online' : 'Offline',
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
              fontWeight: FontWeight.w700,
              color: isOnline ? Colors.green.shade700 : colorScheme.tertiary,
            ),
          ),
        ],
      ),
    );
  }
}

class _SampelCard extends StatelessWidget {
  const _SampelCard({
    required this.item,
    required this.tab,
    required this.onTap,
  });

  final DataSampelPupuk item;
  final DataSampelPupukProgressTab tab;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: AppSpacing.paddingMd,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: tab.color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(tab.icon, color: tab.color, size: 22),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.kodeSampel ?? '–',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          [
                            if (item.estate != null) item.estate,
                            if (item.supplier != null) item.supplier,
                          ].join(' • '),
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right,
                    color: colorScheme.onSurfaceVariant,
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _InfoChip(label: tab.label, color: tab.color),
                  if (item.jenisPupuk != null && item.jenisPupuk!.isNotEmpty)
                    _InfoChip(
                      label: item.jenisPupuk!,
                      color: colorScheme.primary,
                    ),
                  if (item.noPo != null && item.noPo!.isNotEmpty)
                    _InfoChip(
                      label: 'PO: ${item.noPo}',
                      color: colorScheme.tertiary,
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelSmall?.copyWith(
          color: color.darken(),
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

extension on Color {
  Color darken([double amount = 0.12]) {
    final hsl = HSLColor.fromColor(this);
    return hsl
        .withLightness((hsl.lightness - amount).clamp(0.0, 1.0))
        .toColor();
  }
}
