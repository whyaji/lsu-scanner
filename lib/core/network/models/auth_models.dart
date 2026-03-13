class LoginRequest {
  final String username;
  final String password;

  LoginRequest({required this.username, required this.password});

  Map<String, dynamic> toJson() {
    return {'username': username, 'password': password};
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

  RefreshTokenRequest({required this.refreshToken});

  Map<String, dynamic> toJson() {
    return {'refreshToken': refreshToken};
  }
}

class RefreshTokenResponse {
  final String accessToken;
  final int expiresIn;

  RefreshTokenResponse({required this.accessToken, required this.expiresIn});

  factory RefreshTokenResponse.fromJson(Map<String, dynamic> json) {
    return RefreshTokenResponse(
      accessToken: json['accessToken'] as String,
      expiresIn: json['expiresIn'] as int,
    );
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
