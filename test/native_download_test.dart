import 'dart:io';
import 'dart:typed_data';

import 'package:cineconnect/core/network/save_download_stub.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter_test/flutter_test.dart';

class _SaveDialog extends FilePicker {
  String? destination;
  String? suggestedName;
  @override
  Future<String?> saveFile({
    String? dialogTitle,
    String? fileName,
    String? initialDirectory,
    FileType type = FileType.any,
    List<String>? allowedExtensions,
    Uint8List? bytes,
    bool lockParentWindow = false,
  }) async {
    suggestedName = fileName;
    return destination;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  FilePicker.platform = _SaveDialog();
  test('native save writes returned bytes to the chosen desktop file',
      () async {
    final directory =
        await Directory.systemTemp.createTemp('cine-download-test-');
    final original = FilePicker.platform;
    final dialog = _SaveDialog()..destination = '${directory.path}/report.csv';
    FilePicker.platform = dialog;
    try {
      expect(await saveDownload('report/2026.csv', [65, 66, 67], 'text/csv'),
          isTrue);
      expect(await File(dialog.destination!).readAsBytes(), [65, 66, 67]);
      expect(dialog.suggestedName, 'report_2026.csv');
    } finally {
      FilePicker.platform = original;
      await directory.delete(recursive: true);
    }
  });

  test('cancelled native save reports cancellation', () async {
    final original = FilePicker.platform;
    FilePicker.platform = _SaveDialog();
    try {
      expect(
          await saveDownload('report.pdf', [65], 'application/pdf'), isFalse);
    } finally {
      FilePicker.platform = original;
    }
  });
}
