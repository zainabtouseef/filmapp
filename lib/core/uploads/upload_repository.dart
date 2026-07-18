import 'dart:typed_data';

import '../network/api_client.dart';
import '../verification/verification_models.dart';

class PickedFileData {
  final String name;
  final String mimeType;
  final Uint8List bytes;

  const PickedFileData({
    required this.name,
    required this.mimeType,
    required this.bytes,
  });

  int get sizeBytes => bytes.length;
}

class UploadRepository {
  final ApiClient _client;

  const UploadRepository(this._client);

  Future<UploadedFile> uploadFile({
    required String purpose,
    required PickedFileData file,
    void Function(int sentBytes, int totalBytes)? onProgress,
  }) async {
    final presign = await _client.post(
      '/uploads/presign',
      body: {
        'purpose': purpose,
        'mime_type': file.mimeType,
        'original_name': file.name,
        'size_bytes': file.sizeBytes,
      },
    );
    final ticket =
        UploadTicket.fromJson(presign['data'] as Map<String, dynamic>);
    await _client.putBytes(
      ticket.uploadUrl,
      bytes: file.bytes,
      contentType: file.mimeType,
      onProgress: onProgress,
    );
    final complete = await _client.post('/uploads/${ticket.id}/complete');
    final data = complete['data'] as Map<String, dynamic>;
    return UploadedFile.fromJson(data['file'] as Map<String, dynamic>);
  }
}
