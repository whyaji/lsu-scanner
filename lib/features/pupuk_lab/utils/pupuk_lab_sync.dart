import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../widgets/feedback/app_dialog.dart';
import '../../pupuk/providers/sync_sampel_pupuk_provider.dart';
import '../../regional/providers/regional_provider.dart';

/// Runs the pupuk sync behind a blocking progress dialog. Returns the error
/// message, or null when the sync worked.
Future<String?> syncPupukData(BuildContext context, WidgetRef ref) async {
  final regional = ref.read(regionalProvider).selectedRegional;
  final handle = AppDialog.progress(
    context,
    message: 'Menyinkronkan data sampel',
  );
  try {
    await ref.read(syncSampelPupukProvider.notifier).sync(regional);
  } finally {
    handle.close();
  }
  return ref.read(syncSampelPupukProvider).error;
}
