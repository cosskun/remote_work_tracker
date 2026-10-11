import 'dart:io';
import 'package:path_provider/path_provider.dart';

Future<String> saveExcelFile(List<int> bytes, String fileName) async {
  Directory? directory;
  try {
    if (Platform.isWindows || Platform.isMacOS) {
      directory = await getDownloadsDirectory();
    }
  } catch (_) {
    // If downloads directory fails, fallback to documents
  }
  
  directory ??= await getApplicationDocumentsDirectory();
  
  final String filePath = '${directory.path}/$fileName';
  final File file = File(filePath);
  await file.writeAsBytes(bytes);
  return 'Dosya başarıyla kaydedildi:\n$filePath';
}
