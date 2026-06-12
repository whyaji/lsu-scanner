import 'package:flutter/material.dart';

import '../../../core/network/models/notification_model.dart';
import '../../pupuk/screens/data_sampel_pupuk_detail_screen.dart';
import '../screens/notification_sample_list_screen.dart';

class NotificationSampleTarget {
  const NotificationSampleTarget({required this.id, required this.kodeSampel});

  final int id;
  final String kodeSampel;
}

List<int> parseNotificationSampleIds(Map<String, dynamic>? data) {
  if (data == null) return const [];

  final single = data['dataSampelPupukId'];
  if (single != null) {
    final parsed = int.tryParse(single.toString());
    if (parsed != null && parsed > 0) return [parsed];
  }

  final multiple = data['dataSampelPupukIds']?.toString();
  if (multiple == null || multiple.trim().isEmpty) return const [];

  return multiple
      .split(',')
      .map((part) => int.tryParse(part.trim()))
      .whereType<int>()
      .where((id) => id > 0)
      .toList();
}

List<String> parseNotificationKodeSampels(Map<String, dynamic>? data) {
  if (data == null) return const [];
  final raw = data['kodeSampels']?.toString();
  if (raw == null || raw.trim().isEmpty) return const [];
  return raw
      .split(',')
      .map((part) => part.trim())
      .where((part) => part.isNotEmpty)
      .toList();
}

bool isGroupedNotification(Map<String, dynamic>? data, List<int> ids) {
  if (data == null) return ids.length > 1;
  final flag = data['isGroup']?.toString().toLowerCase();
  if (flag == 'true') return true;
  if (flag == 'false') return false;
  return ids.length > 1;
}

List<NotificationSampleTarget> buildNotificationTargets(
  Map<String, dynamic>? data,
) {
  final ids = parseNotificationSampleIds(data);
  final kodes = parseNotificationKodeSampels(data);

  if (ids.isEmpty) return const [];

  return List<NotificationSampleTarget>.generate(ids.length, (index) {
    final kode = index < kodes.length ? kodes[index] : 'Sampel #${ids[index]}';
    return NotificationSampleTarget(id: ids[index], kodeSampel: kode);
  });
}

Future<void> openNotificationTarget(
  BuildContext context,
  MobileNotification notification,
) async {
  final data = notification.data;
  final ids = parseNotificationSampleIds(data);
  if (ids.isEmpty) return;

  final targets = buildNotificationTargets(data);
  final grouped = isGroupedNotification(data, ids);

  if (grouped && targets.length > 1) {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => NotificationSampleListScreen(
          title: notification.title,
          subtitle: notification.body,
          notificationType: notification.type,
          noSurat: data?['noSurat']?.toString(),
          estate: data?['estate']?.toString(),
          samples: targets,
        ),
      ),
    );
    return;
  }

  await Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          DataSampelPupukDetailScreen(id: ids.first, preferOnline: true),
    ),
  );
}

Future<void> openNotificationDataTarget(
  BuildContext context,
  Map<String, dynamic> data, {
  String title = 'Notifikasi',
  String body = '',
  String type = '',
}) async {
  final ids = parseNotificationSampleIds(data);
  if (ids.isEmpty) {
    await Navigator.of(context).pushNamed('/notifications');
    return;
  }

  final notification = MobileNotification(
    id: 0,
    userId: 0,
    type: type.isNotEmpty ? type : (data['type']?.toString() ?? ''),
    title: title,
    body: body,
    data: data,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  );

  await openNotificationTarget(context, notification);
}
