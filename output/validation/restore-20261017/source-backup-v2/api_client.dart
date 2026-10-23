import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiDownload {
  final List<int> bytes;
  final String filename;
  final String contentType;

  const ApiDownload({
    required this.bytes,
    required this.filename,
    required this.contentType,
  });
}

class ApiClient {
  final http.Client _http;
  final String baseUrl;
  String? accessToken;

  /// Called when a request comes back 401. Should attempt to refresh the
  /// session and return the new access token, or `null` if the session
  /// could not be refreshed (e.g. the refresh token is also expired).
  Future<String?> Function()? onUnauthorized;

  Future<String?>? _refreshInFlight;

  ApiClient({http.Client? httpClient, this.baseUrl = ApiConfig.baseUrl})
      : _http = httpClient ?? http.Client();

  Future<String?> _refreshAccessToken() {
    final handler = onUnauthorized;
    if (handler == null) return Future.value(null);
    return _refreshInFlight ??= handler().whenComplete(() {
      _refreshInFlight = null;
    });
  }

  /// Resolves a path returned by the API (e.g. a file's `download_url`,
  /// always path-only like `/api/v1/files/{id}/download`) into an absolute
  /// URL against this client's origin — for handing to `Image.network` or
  /// similar, not for `get`/`post` (those already prefix with [baseUrl]).
  Uri resolve(String pathOrUrl) {
    final uri = Uri.parse(pathOrUrl);
    if (uri.hasScheme) return uri;
    return Uri.parse(baseUrl).resolve(pathOrUrl);
  }

  Future<Map<String, dynamic>> get(String path) {
    return _send('GET', path);
  }

  Future<Map<String, dynamic>> post(String path, {Map<String, dynamic>? body}) {
    return _send('POST', path, body: body);
  }

  Future<Map<String, dynamic>> patch(
    String path, {
    Map<String, dynamic>? body,
  }) {
    return _send('PATCH', path, body: body);
  }

  Future<Map<String, dynamic>> delete(String path) {
    return _send('DELETE', path);
  }

  Future<ApiDownload> getBytes(
    String path, {
    String fallbackFilename = 'download',
    bool isRetry = false,
  }) async {
    final request = http.Request('GET', _uriFor(path));
    if (accessToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }
    late final http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request).timeout(const Duration(seconds: 60));
    } on SocketException {
      throw const ApiException(
        code: 'network.offline',
        message: 'Cannot reach CineConnect right now.',
      );
    } on TimeoutException {
      throw const ApiException(
        code: 'network.timeout',
        message: 'The download took too long. Please retry.',
      );
    }
    if (streamed.statusCode == 401 && !isRetry && onUnauthorized != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed != null) {
        return getBytes(
          path,
          fallbackFilename: fallbackFilename,
          isRetry: true,
        );
      }
    }
    final response = await http.Response.fromStream(streamed);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      Map<String, dynamic>? decoded;
      try {
        decoded = jsonDecode(response.body) as Map<String, dynamic>;
      } on FormatException {
        decoded = null;
      }
      final error = decoded?['error'] as Map<String, dynamic>?;
      throw ApiException(
        code: error?['code'] as String? ?? 'http.${response.statusCode}',
        message: error?['message'] as String? ?? 'Download failed.',
        statusCode: response.statusCode,
        fields: _parseFields(error?['fields']),
      );
    }
    final disposition = response.headers['content-disposition'];
    final match = disposition == null
        ? null
        : RegExp(r'filename="?([^";]+)"?').firstMatch(disposition);
    return ApiDownload(
      bytes: response.bodyBytes,
      filename: match?.group(1) ?? fallbackFilename,
      contentType: response.headers[HttpHeaders.contentTypeHeader] ??
          'application/octet-stream',
    );
  }

  Future<Map<String, dynamic>> putBytes(
    String pathOrUrl, {
    required List<int> bytes,
    required String contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
    bool isRetry = false,
  }) async {
    final request = http.StreamedRequest('PUT', _uriFor(pathOrUrl))
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..headers[HttpHeaders.contentTypeHeader] = contentType
      ..contentLength = bytes.length;
    if (accessToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }
    late final http.StreamedResponse streamed;
    try {
      final responseFuture =
          _http.send(request).timeout(const Duration(seconds: 60));
      const chunkSize = 64 * 1024;
      var sentBytes = 0;
      while (sentBytes < bytes.length) {
        final next = (sentBytes + chunkSize).clamp(0, bytes.length);
        request.sink.add(bytes.sublist(sentBytes, next));
        sentBytes = next;
        onProgress?.call(sentBytes, bytes.length);
        await Future<void>.delayed(Duration.zero);
      }
      await request.sink.close();
      streamed = await responseFuture;
    } on SocketException {
      throw const ApiException(
        code: 'network.offline',
        message: 'Cannot reach CineConnect right now.',
      );
    } on TimeoutException {
      throw const ApiException(
        code: 'network.timeout',
        message: 'Upload timed out. Please try a smaller image or retry.',
      );
    }

    if (streamed.statusCode == 401 && !isRetry && onUnauthorized != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed != null) {
        return putBytes(
          pathOrUrl,
          bytes: bytes,
          contentType: contentType,
          onProgress: onProgress,
          isRetry: true,
        );
      }
    }

    return _decodeResponse(streamed);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
    bool isRetry = false,
  }) async {
    final request = http.Request(method, _uriFor(path))
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..headers[HttpHeaders.contentTypeHeader] = 'application/json';
    if (accessToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $accessToken';
    }
    if (body != null) {
      request.body = jsonEncode(body);
    }

    late final http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request).timeout(const Duration(seconds: 18));
    } on SocketException {
      throw const ApiException(
        code: 'network.offline',
        message: 'Cannot reach CineConnect right now.',
      );
    } on TimeoutException {
      throw const ApiException(
        code: 'network.timeout',
        message: 'CineConnect took too long to respond. Please retry.',
      );
    }

    if (streamed.statusCode == 401 && !isRetry && onUnauthorized != null) {
      final refreshed = await _refreshAccessToken();
      if (refreshed != null) {
        return _send(method, path, body: body, isRetry: true);
      }
    }

    return _decodeResponse(streamed);
  }

  Uri _uriFor(String pathOrUrl) {
    final uri = Uri.parse(pathOrUrl);
    if (uri.hasScheme) return uri;
    if (pathOrUrl.startsWith('/api/v1/')) {
      final base = Uri.parse(baseUrl);
      return Uri.parse('${base.scheme}://${base.authority}$pathOrUrl');
    }
    return Uri.parse('$baseUrl$pathOrUrl');
  }

  Future<Map<String, dynamic>> _decodeResponse(
    http.StreamedResponse streamed,
  ) async {
    final response = await http.Response.fromStream(streamed);
    final decoded = response.body.isEmpty
        ? <String, dynamic>{}
        : jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }
    final error = decoded['error'] as Map<String, dynamic>?;
    throw ApiException(
      code: error?['code'] as String? ?? 'http.${response.statusCode}',
      message: error?['message'] as String? ?? 'Request failed.',
      statusCode: response.statusCode,
      fields: _parseFields(error?['fields']),
    );
  }

  Map<String, List<String>> _parseFields(Object? fields) {
    if (fields is! Map<String, dynamic>) return const {};
    return fields.map((key, value) {
      if (value is List) {
        return MapEntry(key, value.map((item) => '$item').toList());
      }
      return MapEntry(key, ['$value']);
    });
  }
}
