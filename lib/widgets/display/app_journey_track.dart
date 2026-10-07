import 'package:flutter/material.dart';

import '../../core/theme/app_semantic_colors.dart';
import '../../core/theme/app_spacing.dart';

enum AppJourneyStageState { done, current, pending, error }

@immutable
class AppJourneyStage {
  const AppJourneyStage({required this.label, required this.state});

  final String label;
  final AppJourneyStageState state;

  String get spokenState => switch (state) {
    AppJourneyStageState.done => 'selesai',
    AppJourneyStageState.current => 'sedang berjalan',
    AppJourneyStageState.pending => 'belum',
    AppJourneyStageState.error => 'bermasalah',
  };
}

/// Connected stage dots that show how far a sample has travelled.
/// Compact (default) draws dots and one caption line for list items. showLabels draws every stage name for detail screens and scrolls sideways when the names do not fit.
class AppJourneyTrack extends StatelessWidget {
  const AppJourneyTrack({
    super.key,
    required this.stages,
    this.showLabels = false,
  }) : assert(stages.length > 0);

  /// The six lifecycle stages of a sample, in order.
  static const sampleStageLabels = [
    'Gudang Estate',
    'Kirim Estate',
    'Kirim Lab',
    'Terima Lab',
    'Estimasi KUPA',
    'Sertifikat',
  ];

  /// Builds the sample lifecycle with [completed] stages done. The next stage is current, or error when [hasError].
  factory AppJourneyTrack.sample({
    Key? key,
    required int completed,
    bool hasError = false,
    bool showLabels = false,
  }) {
    final done = completed.clamp(0, sampleStageLabels.length);
    return AppJourneyTrack(
      key: key,
      showLabels: showLabels,
      stages: [
        for (var i = 0; i < sampleStageLabels.length; i++)
          AppJourneyStage(
            label: sampleStageLabels[i],
            state: i < done
                ? AppJourneyStageState.done
                : i == done
                ? (hasError
                      ? AppJourneyStageState.error
                      : AppJourneyStageState.current)
                : AppJourneyStageState.pending,
          ),
      ],
    );
  }

  final List<AppJourneyStage> stages;
  final bool showLabels;

  String get summary {
    final error = stages.where((s) => s.state == AppJourneyStageState.error);
    if (error.isNotEmpty) return '${error.first.label} bermasalah';
    final i = stages.indexWhere((s) => s.state == AppJourneyStageState.current);
    if (i >= 0) return '${stages[i].label} (${i + 1} dari ${stages.length})';
    if (stages.every((s) => s.state == AppJourneyStageState.done)) {
      return 'Semua tahap selesai';
    }
    return 'Belum dimulai';
  }

  String get semanticLabel =>
      'Perjalanan sampel. $summary. '
      '${stages.map((s) => '${s.label} ${s.spokenState}').join(', ')}';

  @override
  Widget build(BuildContext context) {
    return Semantics(
      container: true,
      label: semanticLabel,
      child: ExcludeSemantics(
        child: showLabels ? _Labeled(stages: stages) : _Compact(track: this),
      ),
    );
  }
}

class _Compact extends StatelessWidget {
  const _Compact({required this.track});

  final AppJourneyTrack track;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final stages = track.stages;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            for (var i = 0; i < stages.length; i++) ...[
              _Node(state: stages[i].state, size: 16),
              if (i < stages.length - 1)
                Expanded(
                  child: _Connector(
                    done: stages[i].state == AppJourneyStageState.done,
                  ),
                ),
            ],
          ],
        ),
        const SizedBox(height: AppSpacing.xs + 2),
        Text(
          track.summary,
          style: theme.textTheme.labelSmall?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _Labeled extends StatelessWidget {
  const _Labeled({required this.stages});

  final List<AppJourneyStage> stages;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final minWidth = MediaQuery.textScalerOf(context).scale(76);

    return LayoutBuilder(
      builder: (context, constraints) {
        final share = constraints.maxWidth.isFinite
            ? constraints.maxWidth / stages.length
            : minWidth;
        final width = share < minWidth ? minWidth : share;

        final row = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            for (var i = 0; i < stages.length; i++)
              SizedBox(
                width: width,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: i == 0
                              ? const SizedBox.shrink()
                              : _Connector(
                                  done: stages[i - 1].state ==
                                      AppJourneyStageState.done,
                                ),
                        ),
                        _Node(state: stages[i].state, size: 24),
                        Expanded(
                          child: i == stages.length - 1
                              ? const SizedBox.shrink()
                              : _Connector(
                                  done: stages[i].state ==
                                      AppJourneyStageState.done,
                                ),
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs + 2),
                    Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.xs,
                      ),
                      child: Text(
                        stages[i].label,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.labelSmall?.copyWith(
                          color: stages[i].state == AppJourneyStageState.pending
                              ? theme.colorScheme.onSurfaceVariant
                              : theme.colorScheme.onSurface,
                          fontWeight:
                              stages[i].state == AppJourneyStageState.current
                              ? FontWeight.w700
                              : FontWeight.w500,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        );

        if (width * stages.length <= constraints.maxWidth) return row;
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: row,
        );
      },
    );
  }
}

class _Connector extends StatelessWidget {
  const _Connector({required this.done});

  final bool done;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      height: 2,
      color: done ? scheme.primary : scheme.outlineVariant,
    );
  }
}

class _Node extends StatelessWidget {
  const _Node({required this.state, required this.size});

  final AppJourneyStageState state;
  final double size;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final iconSize = size * 0.65;

    switch (state) {
      case AppJourneyStageState.done:
        return _disc(scheme.primary, Icons.check_rounded, scheme.onPrimary, iconSize);
      case AppJourneyStageState.error:
        return _disc(
          AppSemanticColors.of(context).error.accent,
          Icons.priority_high_rounded,
          scheme.surface,
          iconSize,
        );
      case AppJourneyStageState.current:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
            border: Border.all(color: scheme.primary, width: 2.5),
          ),
          child: Center(
            child: Container(
              width: size * 0.4,
              height: size * 0.4,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: scheme.primary,
              ),
            ),
          ),
        );
      case AppJourneyStageState.pending:
        return Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: scheme.surface,
            border: Border.all(color: scheme.outline, width: 1.5),
          ),
        );
    }
  }

  Widget _disc(Color fill, IconData icon, Color iconColor, double iconSize) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: fill),
      child: Icon(icon, size: iconSize, color: iconColor),
    );
  }
}
