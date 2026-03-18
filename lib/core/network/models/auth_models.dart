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

class User {
  final int id;
  final String username;
  final String nama;
  final String? jabatan;
  final String? lokasiKerja;
  final bool isAdmin;
  final List<String>? access;

  User({
    required this.id,
    required this.username,
    required this.nama,
    this.jabatan,
    this.lokasiKerja,
    required this.isAdmin,
    this.access,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    List<String>? accessList;
    if (json['access'] != null) {
      final list = json['access'];
      if (list is List) {
        accessList = list.map((e) => e.toString()).toList();
      }
    }
    return User(
      id: json['id'] as int,
      username: json['username'] as String,
      nama: json['nama'] as String,
      jabatan: json['jabatan'] as String?,
      lokasiKerja: json['lokasiKerja'] as String?,
      isAdmin: json['isAdmin'] as bool? ?? false,
      access: accessList,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'nama': nama,
      'jabatan': jabatan,
      'lokasiKerja': lokasiKerja,
      'isAdmin': isAdmin,
      if (access != null) 'access': access,
    };
  }

  bool get hasPupukEstateAccess =>
      access != null && access!.contains('pupuk:estate');
  bool get hasPupukNtAccess => access != null && access!.contains('pupuk:nt');
  bool get hasAnyPupukAccess => hasPupukEstateAccess || hasPupukNtAccess;
}
