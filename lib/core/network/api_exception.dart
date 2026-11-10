import 'dart:convert';

import 'package:http/http.dart' as http;

class ApiException implements Exception {
  const ApiException(this.code, this.message, {this.status = 0});

  final String code;
  final String message;
  final int status;

  factory ApiException.fromResponse(http.Response response) {
    var code = 'HTTP_ERROR';
    try {
      final body = jsonDecode(utf8.decode(response.bodyBytes));
      if (body is Map && body['code'] is String) code = body['code'] as String;
    } on FormatException {
      // A proxy may return HTML; never expose its body to users or logs.
    }
    final message = switch (code) {
      'AUTHENTICATION_FAILED' =>
        'Tên đăng nhập hoặc mật khẩu không đúng, hoặc tài khoản đã bị khóa.',
      'CSRF_INVALID' =>
        'Cấu hình kết nối đăng nhập chưa được máy chủ cho phép.',
      _ when response.statusCode == 401 =>
        'Phiên đăng nhập đã hết hạn. Vui lòng đăng nhập lại.',
      _ when response.statusCode == 403 =>
        'Tài khoản chưa có quyền truy cập chức năng này.',
      _ when response.statusCode == 429 =>
        'Có quá nhiều yêu cầu. Vui lòng chờ một lúc rồi thử lại.',
      _ => 'Máy chủ chưa xử lý được yêu cầu. Vui lòng thử lại sau.',
    };
    return ApiException(code, message, status: response.statusCode);
  }

  @override
  String toString() => 'ApiException($code, status: $status)';
}

String authErrorMessage(Object error) => error is ApiException
    ? error.message
    : 'Không thể xử lý phiên đăng nhập. Vui lòng thử lại.';
