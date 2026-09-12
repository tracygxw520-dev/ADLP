/// Runtime configuration supplied with `--dart-define`.
///
/// Android emulators can reach a local FastAPI server at `10.0.2.2`. For a
/// web browser, iOS simulator, or physical device, pass a reachable address,
/// for example:
/// `--dart-define=API_BASE_URL=http://localhost:8000`.
abstract final class AppConfig {
  static const _rawApiBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'http://10.0.2.2:8000',
  );

  /// The FastAPI server URL without a trailing slash.
  static Uri get apiBaseUri => Uri.parse(
        _rawApiBaseUrl.endsWith('/')
            ? _rawApiBaseUrl.substring(0, _rawApiBaseUrl.length - 1)
            : _rawApiBaseUrl,
      );
}
