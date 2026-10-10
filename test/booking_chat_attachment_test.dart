import 'package:cineconnect/core/bookings/booking_models.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('conversation message parses ready file attachments', () {
    final message = ConversationMessage.fromJson({
      'public_id': 'MSG-001',
      'sender': {
        'public_id': 'USR-001',
        'display_name': 'Director One',
      },
      'body': null,
      'message_type': 'attachment',
      'created_at': '2026-10-10T15:00:00Z',
      'attachments': [
        {
          'attachment_type': 'file',
          'caption': 'Call sheet',
          'file': {
            'public_id': 'FIL-001',
            'mime_type': 'application/pdf',
            'size_bytes': 2048,
            'scan_status': 'clean',
            'processing_status': 'ready',
            'original_name': 'call-sheet.pdf',
            'visibility': 'authorized',
            'download_url': '/api/v1/files/FIL-001/download',
            'public_url': null,
          },
        },
      ],
    });

    expect(message.attachments, hasLength(1));
    expect(message.attachments.single.file.originalName, 'call-sheet.pdf');
    expect(message.attachments.single.file.processingStatus, 'ready');
    expect(message.attachments.single.caption, 'Call sheet');
  });

  test('attachment input serializes the backend contract', () {
    const input = ConversationAttachmentInput(
      fileId: 'FIL-001',
      attachmentType: 'image',
      caption: 'Location reference',
    );

    expect(input.toJson(), {
      'file_id': 'FIL-001',
      'attachment_type': 'image',
      'caption': 'Location reference',
    });
  });
}
