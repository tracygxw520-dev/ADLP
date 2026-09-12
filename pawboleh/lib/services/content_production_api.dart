import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../core/app_config.dart';
import '../models/content_production.dart';

/// A user-facing error raised when the content-production service cannot
/// complete a request.
class ContentProductionApiException implements Exception {
  const ContentProductionApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

/// Client for PawSnap's content-production API.
///
/// The API accepts an uploaded product image, then returns generated marketing
/// copy along with poster and video URLs. Pass [baseUri] in tests or when the
/// API is hosted somewhere other than [AppConfig.apiBaseUri].
class ContentProductionApi {
  ContentProductionApi({http.Client? client, Uri? baseUri})
      : _client = client ?? http.Client(),
        _ownsClient = client == null,
        _baseUri = baseUri ?? AppConfig.apiBaseUri;

  final http.Client _client;
  final bool _ownsClient;
  final Uri _baseUri;

  static const _timeout = Duration(minutes: 3);

  Future<ContentProduction> create(
    CreateContentProductionRequest request,
  ) async {
    final response = await _send(
      () => _client
          .post(
            _endpoint('content-productions'),
            headers: const {'Content-Type': 'application/json'},
            body: jsonEncode(request.toJson()),
          )
          .timeout(_timeout),
    );

    return ContentProduction.fromJson(_decodeMap(response));
  }

  /// Uploads a product image and returns the URL the API assigns to it.
  Future<String> uploadImage(String name, List<int> bytes) async {
    final request = http.MultipartRequest(
      'POST',
      _endpoint('content-productions/uploads'),
    )..files.add(http.MultipartFile.fromBytes('file', bytes, filename: name));

    final streamed = await _sendStreamed(
      () => _client.send(request).timeout(_timeout),
    );
    final response = await http.Response.fromStream(streamed);
    final decoded = _decodeMap(response);
    final url = decoded['url'];
    if (url is! String || url.trim().isEmpty) {
      throw const ContentProductionApiException(
        'The server did not return an image URL.',
      );
    }
    return url;
  }

  Future<List<ContentProduction>> list() async {
    final response = await _send(
      () => _client.get(_endpoint('content-productions')).timeout(_timeout),
    );
    final decoded = _decode(response);
    if (decoded is! List) {
      throw const ContentProductionApiException(
        'The server returned an unexpected history response.',
      );
    }
    return decoded
        .whereType<Map<String, dynamic>>()
        .map(ContentProduction.fromJson)
        .toList(growable: false);
  }

  Future<ContentProduction> getById(String id) async {
    final response = await _send(
      () => _client
          .get(_endpoint('content-productions/${Uri.encodeComponent(id)}'))
          .timeout(_timeout),
    );
    return ContentProduction.fromJson(_decodeMap(response));
  }

  /// Turns an API-relative asset path such as `/assets/poster.svg` into a
  /// browser/device-reachable URL. Absolute provider URLs are returned intact.
  String? resolveAssetUrl(String? value) {
    if (value == null || value.trim().isEmpty) return null;
    final raw = value.trim();
    final parsed = Uri.tryParse(raw);
    if (parsed != null && parsed.hasScheme) {
      // FastAPI may have been started with its default PUBLIC_BASE_URL
      // (localhost) while the Flutter app reaches it through 10.0.2.2 or a
      // LAN address. Reuse the configured API host for local asset URLs so a
      // successful upload still renders on emulators and physical devices.
      if ((parsed.host == 'localhost' || parsed.host == '127.0.0.1') &&
          parsed.host != _baseUri.host) {
        return parsed
            .replace(
              scheme: _baseUri.scheme,
              host: _baseUri.host,
              port: _baseUri.port,
            )
            .toString();
      }
      return parsed.toString();
    }
    return _baseUri.resolve(raw).toString();
  }

  /// Closes a client created by this API instance.
  ///
  /// A supplied [http.Client] remains owned by its caller.
  void dispose() {
    if (_ownsClient) _client.close();
  }

  Uri _endpoint(String path) => _baseUri.resolve('/$path');

  Future<http.Response> _send(Future<http.Response> Function() action) async {
    try {
      final response = await action();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw ContentProductionApiException(
          _errorMessage(response),
          statusCode: response.statusCode,
        );
      }
      return response;
    } on TimeoutException {
      throw const ContentProductionApiException(
        'The request took too long. Check the API and try again.',
      );
    } on http.ClientException {
      throw const ContentProductionApiException(
        'Could not reach the API. Check API_BASE_URL and your connection.',
      );
    }
  }

  Future<http.StreamedResponse> _sendStreamed(
    Future<http.StreamedResponse> Function() action,
  ) async {
    try {
      final response = await action();
      if (response.statusCode < 200 || response.statusCode >= 300) {
        final completeResponse = await http.Response.fromStream(response);
        throw ContentProductionApiException(
          _errorMessage(completeResponse),
          statusCode: completeResponse.statusCode,
        );
      }
      return response;
    } on TimeoutException {
      throw const ContentProductionApiException(
        'The request took too long. Check the API and try again.',
      );
    } on http.ClientException {
      throw const ContentProductionApiException(
        'Could not reach the API. Check API_BASE_URL and your connection.',
      );
    }
  }

  dynamic _decode(http.Response response) {
    try {
      return jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw const ContentProductionApiException(
        'The server returned invalid JSON.',
      );
    }
  }

  Map<String, dynamic> _decodeMap(http.Response response) {
    final decoded = _decode(response);
    if (decoded is Map<String, dynamic>) return decoded;
    throw const ContentProductionApiException(
      'The server returned an unexpected content package.',
    );
  }

  String _errorMessage(http.Response response) {
    try {
      final decoded = jsonDecode(utf8.decode(response.bodyBytes));
      if (decoded is Map<String, dynamic>) {
        final detail = decoded['detail'] ?? decoded['message'];
        if (detail is String && detail.trim().isNotEmpty) return detail;
      }
    } on FormatException {
      // Fall back to the status code below.
    }
    return 'Request failed (${response.statusCode}). Please try again.';
  }
}
