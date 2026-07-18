class ApiException implements Exception {
  final String code;
  final String message;
  final int? statusCode;
  final Map<String, List<String>> fields;

  const ApiException({
    required this.code,
    required this.message,
    this.statusCode,
    this.fields = const {},
  });

  @override
  String toString() => message;
}
