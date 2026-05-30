import '../../constants/permission_constants.dart';

class LoginRequest {
  final String username;
  final String password;
  final String platformId;
  final String userAgent;

  LoginRequest({
    required this.username,
    required this.password,
    required this.platformId,
    required this.userAgent,
  });

  Map<String, dynamic> toJson() {
    return {
      'username': username,
      'password': password,
      'platformId': platformId,
      'userAgent': userAgent,
    };
  }
}

class LoginResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User user;

  LoginResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    required this.user,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: json['expiresIn'] as int,
      user: User.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class RefreshTokenRequest {
  final String refreshToken;
  final String platformId;

  RefreshTokenRequest({required this.refreshToken, required this.platformId});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken, 'platformId': platformId};
  }
}

/// Response shape from `POST /auth/mobile-refresh` (same token fields as login).
class MobileRefreshResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresIn;
  final User? user;

  MobileRefreshResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
    this.user,
  });

  factory MobileRefreshResponse.fromJson(Map<String, dynamic> json) {
    return MobileRefreshResponse(
      accessToken: json['accessToken'] as String,
      refreshToken: json['refreshToken'] as String,
      expiresIn: (json['expiresIn'] as num).toInt(),
      user: json['user'] != null
          ? User.fromJson(json['user'] as Map<String, dynamic>)
          : null,
    );
  }
}

class MobileLogoutRequest {
  final String platformId;
  final String userAgent;

  MobileLogoutRequest({required this.platformId, required this.userAgent});

  Map<String, dynamic> toJson() {
    return {'platformId': platformId, 'userAgent': userAgent};
  }
}

/// Central user + RBAC (matches backend `UserResponseDto`).
class UserLocationItem {
  final int id;
  final String locationType;
  final String? locationName;

  UserLocationItem({
    required this.id,
    required this.locationType,
    this.locationName,
  });

  factory UserLocationItem.fromJson(Map<String, dynamic> json) {
    return UserLocationItem(
      id: json['id'] as int,
      locationType: json['locationType'] as String,
      locationName: json['locationName'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'locationType': locationType,
    if (locationName != null) 'locationName': locationName,
  };
}

class User {
  final int userId;
  final String email;
  final String namaLengkap;
  final String departemen;
  final String jabatan;
  final String? afdeling;
  final String? noHp;
  final String statusAkun;
  final String lokasiKerja;
  final String? namaPerusahaan;
  final String aksesLevel;
  final String foto;
  final int? idDepartement;
  final int? idJabatan;
  final List<String> roles;
  final List<String> permissions;
  final List<UserLocationItem> lokasi;

  User({
    required this.userId,
    required this.email,
    required this.namaLengkap,
    required this.departemen,
    required this.jabatan,
    this.afdeling,
    this.noHp,
    required this.statusAkun,
    required this.lokasiKerja,
    this.namaPerusahaan,
    required this.aksesLevel,
    required this.foto,
    this.idDepartement,
    this.idJabatan,
    required this.roles,
    required this.permissions,
    this.lokasi = const [],
  });

  /// Display name (legacy field name used in UI).
  String get nama => namaLengkap;

  /// Login email (legacy field name used in UI).
  String get username => email;

  /// Legacy alias for [userId] (local DB foreign keys).
  int get id => userId;

  factory User.fromJson(Map<String, dynamic> json) {
    final permissions = _parsePermissions(json);
    final roles = _parseStringList(json['roles']);
    final lokasiList = json['lokasi'];
    final lokasi = lokasiList is List
        ? lokasiList
              .map((e) => UserLocationItem.fromJson(e as Map<String, dynamic>))
              .toList()
        : <UserLocationItem>[];

    return User(
      userId: (json['userId'] ?? json['id']) as int,
      email: (json['email'] ?? json['username'] ?? '') as String,
      namaLengkap: (json['namaLengkap'] ?? json['nama'] ?? '') as String,
      departemen: json['departemen'] as String? ?? '',
      jabatan: json['jabatan'] as String? ?? '',
      afdeling: json['afdeling'] as String?,
      noHp: json['noHp'] as String?,
      statusAkun: json['statusAkun']?.toString() ?? '1',
      lokasiKerja: json['lokasiKerja'] as String? ?? '',
      namaPerusahaan: json['namaPerusahaan'] as String?,
      aksesLevel: json['aksesLevel']?.toString() ?? '1',
      foto: json['foto'] as String? ?? '',
      idDepartement: json['idDepartement'] as int?,
      idJabatan: json['idJabatan'] as int?,
      roles: roles,
      permissions: permissions,
      lokasi: lokasi,
    );
  }

  List<String> get estateLocationNames => lokasi
      .where(
        (l) =>
            l.locationType == 'estate' && (l.locationName?.isNotEmpty ?? false),
      )
      .map((l) => l.locationName!)
      .toList();

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'email': email,
      'namaLengkap': namaLengkap,
      'departemen': departemen,
      'jabatan': jabatan,
      if (afdeling != null) 'afdeling': afdeling,
      if (noHp != null) 'noHp': noHp,
      'statusAkun': statusAkun,
      'lokasiKerja': lokasiKerja,
      if (namaPerusahaan != null) 'namaPerusahaan': namaPerusahaan,
      'aksesLevel': aksesLevel,
      'foto': foto,
      if (idDepartement != null) 'idDepartement': idDepartement,
      if (idJabatan != null) 'idJabatan': idJabatan,
      'roles': roles,
      'permissions': permissions,
      'lokasi': lokasi.map((l) => l.toJson()).toList(),
    };
  }

  bool hasPermission(String permission) => permissions.contains(permission);

  bool get hasLsuMobileTerima =>
      hasPermission(PermissionConstants.lsuMobileTerima);

  bool get hasLsuMobileSelesai =>
      hasPermission(PermissionConstants.lsuMobileSelesai);

  bool get hasAnyLsuMobileAccess => hasLsuMobileTerima || hasLsuMobileSelesai;

  bool get hasPupukMobileKirimEstate =>
      hasPermission(PermissionConstants.pupukMobileKirimEstate);

  bool get hasPupukMobileKirimLab =>
      hasPermission(PermissionConstants.pupukMobileKirimLab);

  bool get hasPupukMobileKirimSertifikat =>
      hasPermission(PermissionConstants.pupukMobileKirimSertifikat);

  bool get hasAnyPupukMobileAccess =>
      hasPupukMobileKirimEstate ||
      hasPupukMobileKirimLab ||
      hasPupukMobileKirimSertifikat;

  static List<String> _parseStringList(dynamic value) {
    if (value is! List) return [];
    return value.map((e) => e.toString()).toList();
  }

  static List<String> _parsePermissions(Map<String, dynamic> json) {
    if (json['permissions'] != null) {
      return _parseStringList(json['permissions']);
    }
    if (json['access'] != null) {
      return _migrateLegacyAccess(_parseStringList(json['access']));
    }
    return [];
  }

  /// Maps deprecated `access` keys until the user logs in again.
  static List<String> _migrateLegacyAccess(List<String> access) {
    final migrated = <String>{};
    for (final key in access) {
      switch (key) {
        case 'lsu':
          migrated.add(PermissionConstants.lsuMobileTerima);
          migrated.add(PermissionConstants.lsuMobileSelesai);
        case 'pupuk:estate':
          migrated.add(PermissionConstants.pupukMobileKirimEstate);
        case 'pupuk:nt':
          migrated.add(PermissionConstants.pupukMobileKirimLab);
          migrated.add(PermissionConstants.pupukMobileKirimSertifikat);
        default:
          migrated.add(key);
      }
    }
    return migrated.toList();
  }
}
