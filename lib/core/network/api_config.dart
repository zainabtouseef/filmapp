class ApiConfig {
  ApiConfig._();

  static const baseUrl = String.fromEnvironment(
    'CINECONNECT_API_BASE_URL',
    defaultValue: 'https://cine.nalexustechnologies.com/api/v1',
  );
}
