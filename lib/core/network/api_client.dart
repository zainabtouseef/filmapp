import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'api_exception.dart';

class ApiClient {
  final http.Client _http;
  final String baseUrl;
  String? _accessToken;

  ApiClient({http.Client? httpClient, this.baseUrl = ApiConfig.baseUrl})
      : _http = httpClient ?? http.Client();

  set accessToken(String? value) => _accessToken = value;

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

  Future<Map<String, dynamic>> putBytes(
    String pathOrUrl, {
    required List<int> bytes,
    required String contentType,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final request = http.StreamedRequest('PUT', _uriFor(pathOrUrl))
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..headers[HttpHeaders.contentTypeHeader] = contentType
      ..contentLength = bytes.length;
    if (_accessToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $_accessToken';
    }
    request.sink.add(bytes);
    await request.sink.close();
    onProgress?.call(bytes.length, bytes.length);

    late final http.StreamedResponse streamed;
    try {
      streamed = await _http.send(request).timeout(const Duration(seconds: 60));
    } on SocketException {
      throw const ApiException(
        code: 'network.offline',
        message: 'Cannot reach CineConnect right now.',
      );
    }
    return _decodeResponse(streamed);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? body,
  }) async {
    final request = http.Request(method, _uriFor(path))
      ..headers[HttpHeaders.acceptHeader] = 'application/json'
      ..headers[HttpHeaders.contentTypeHeader] = 'application/json';
    if (_accessToken != null) {
      request.headers[HttpHeaders.authorizationHeader] = 'Bearer $_accessToken';
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
    }

    return _decodeResponse(streamed);
  }

  Uri _uriFor(String pathOrUrl) {
    final uri = Uri.parse(pathOrUrl);
    if (uri.hasScheme) return uri;
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
