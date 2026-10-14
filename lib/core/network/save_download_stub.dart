import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> saveDownload(
    String filename, List<int> bytes, String contentType) async {
  final mobile = Platform.isAndroid || Platform.isIOS;
  final safeName = filename.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_');
  final destination = await FilePicker.platform.saveFile(
    dialogTitle: 'Save document',
    fileName: safeName,
    bytes: mobile ? Uint8List.fromList(bytes) : null,
  );
  if (destination == null) return false;
  if (!mobile) await File(destination).writeAsBytes(bytes, flush: true);
  return true;
}
