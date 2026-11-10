/// Public build configuration. Never put credentials or signing keys here.
class AppConfig {
  AppConfig({required Uri apiBaseUri, Uri? authOrigin})
    : apiBaseUri = _validateBaseUri(apiBaseUri),
      authOrigin = _validateBaseUri(
        authOrigin ?? Uri.parse('http://localhost:5173'),
      );

  factory AppConfig.fromEnvironment() {
    const baseUrl = String.fromEnvironment(
      'API_BASE_URL',
      defaultValue: 'http://10.0.2.2:8080',
    );
    const origin = String.fromEnvironment(
      'AUTH_ORIGIN',
      defaultValue: 'http://localhost:5173',
    );
    return AppConfig(
      apiBaseUri: Uri.parse(baseUrl),
      authOrigin: Uri.parse(origin),
    );
  }

  final Uri apiBaseUri;
  final Uri authOrigin;

  Uri endpoint(String path) {
    if (!path.startsWith('/api/')) {
      throw ArgumentError.value(path, 'path', 'Expected an /api/ endpoint.');
    }
    return apiBaseUri.resolve(path);
  }

  static Uri _validateBaseUri(Uri uri) {
    if (!{'http', 'https'}.contains(uri.scheme) ||
        uri.host.isEmpty ||
        uri.userInfo.isNotEmpty ||
        (uri.path.isNotEmpty && uri.path != '/') ||
        uri.hasQuery ||
        uri.hasFragment) {
      throw ArgumentError.value(
        uri,
        'API_BASE_URL',
        'Use an HTTP(S) origin without credentials, path, query or fragment.',
      );
    }
    return uri;
  }
}
