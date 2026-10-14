import 'dart:convert';
import '../network/save_download.dart';

Future<bool> downloadCsv(String filename, String content) => saveDownload(
    filename, utf8.encode('\uFEFF$content'), 'text/csv;charset=utf-8');
