import 'package:sampletrack/core/network/models/auth_models.dart';

User testUser(List<String> permissions, {int userId = 1}) => User(
  userId: userId,
  email: 'user$userId@example.com',
  namaLengkap: 'User $userId',
  departemen: 'Lab',
  jabatan: 'Staf',
  statusAkun: '1',
  lokasiKerja: 'Pusat',
  aksesLevel: '1',
  foto: '',
  roles: const [],
  permissions: permissions,
);
