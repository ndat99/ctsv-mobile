/// Contracts provided by ../ctsv.
abstract final class ApiEndpoints {
  static const login = '/api/auth/login';
  static const refresh = '/api/auth/refresh';
  static const currentUser = '/api/auth/me';
  static const logout = '/api/auth/logout';
  static const schedules = '/api/shcn/lich-hop';
  static const scholarships = '/api/hoc-bong/tai-tro/thong-bao';

  static String schedule(int id) => '$schedules/${_positiveId(id)}';
  static String scholarship(int id) => '$scholarships/${_positiveId(id)}';

  static int _positiveId(int id) {
    if (id <= 0) throw ArgumentError.value(id, 'id', 'Must be positive.');
    return id;
  }
}
