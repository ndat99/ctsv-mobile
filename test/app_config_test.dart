import 'package:ctsv_mobile/core/config/app_config.dart';
import 'package:ctsv_mobile/core/network/api_endpoints.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('API endpoints resolve against the configured backend origin', () {
    final config = AppConfig(apiBaseUri: Uri.parse('http://10.0.2.2:8080'));
    expect(
      config.endpoint(ApiEndpoints.schedule(12)).toString(),
      'http://10.0.2.2:8080/api/shcn/lich-hop/12',
    );
    expect(
      config.endpoint(ApiEndpoints.scholarship(7)).path,
      '/api/hoc-bong/tai-tro/thong-bao/7',
    );
  });

  test('invalid origins and endpoint identifiers fail before a request', () {
    for (final url in [
      'file:///tmp/api',
      'https://user:password@example.com',
      'https://example.com/api',
      'https://example.com?token=secret',
      'https://example.com#fragment',
    ]) {
      expect(() => AppConfig(apiBaseUri: Uri.parse(url)), throwsArgumentError);
    }
    expect(() => ApiEndpoints.schedule(0), throwsArgumentError);
  });
}
