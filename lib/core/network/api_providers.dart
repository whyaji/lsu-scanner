import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'api/area_api.dart';
import 'api/auth_api.dart';
import 'api/lsu_api.dart';
import 'api/notification_api.dart';
import 'api/pupuk_api.dart';
import 'api/upload_api.dart';
import 'api_client.dart';

/// Shared Dio with the fallback, auth and logging interceptors. Override in
/// tests to point the APIs at a fake transport.
final dioProvider = Provider<Dio>((ref) => ApiClient().dio);

final authApiProvider = Provider<AuthApi>((ref) => AuthApi(ref.watch(dioProvider)));
final lsuApiProvider = Provider<LsuApi>((ref) => LsuApi(ref.watch(dioProvider)));
final pupukApiProvider = Provider<PupukApi>(
  (ref) => PupukApi(ref.watch(dioProvider)),
);
final areaApiProvider = Provider<AreaApi>((ref) => AreaApi(ref.watch(dioProvider)));
final notificationApiProvider = Provider<NotificationApi>(
  (ref) => NotificationApi(ref.watch(dioProvider)),
);
final uploadApiProvider = Provider<UploadApi>(
  (ref) => UploadApi(ref.watch(dioProvider)),
);
