class AuthUser {
  const AuthUser({
    required this.id,
    required this.username,
    required this.roles,
    required this.permissions,
    this.studentProfileId,
    this.staffProfileId,
  });

  final int id;
  final String username;
  final Set<String> roles;
  final Set<String> permissions;
  final int? studentProfileId;
  final int? staffProfileId;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    if (json['id'] is! int ||
        (json['id'] as int) <= 0 ||
        json['username'] is! String ||
        (json['username'] as String).trim().isEmpty) {
      throw const FormatException('Invalid account response');
    }
    Set<String> strings(Object? value) {
      if (value is! List || value.any((item) => item is! String)) {
        throw const FormatException('Invalid account authorities');
      }
      return Set.unmodifiable(value.cast<String>());
    }

    return AuthUser(
      id: json['id'] as int,
      username: json['username'] as String,
      roles: strings(json['roles']),
      permissions: strings(json['permissions']),
      studentProfileId: json['hoSoSVID'] as int?,
      staffProfileId: json['hoSoCanBoID'] as int?,
    );
  }
}
