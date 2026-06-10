import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class ImageUtils {
  static Future<Uint8List?> compressImage({
    required String inputPath,
    required CompressFormat format,
    int quality = 85,
    int? minWidth,
    int? minHeight,
  }) async {
    final result = await FlutterImageCompress.compressWithFile(
      inputPath,
      format: format,
      quality: quality,
      // En flutter_image_compress, minWidth/minHeight actúan como caja máxima
      // (reduce si la imagen es mayor, nunca amplía). Sin un límite explícito
      // usamos una caja gigante para CONSERVAR la resolución original: solo se
      // reduce cuando la herramienta lo pide (p. ej. la escala del Lote).
      minWidth: minWidth ?? 65535,
      minHeight: minHeight ?? 65535,
    );
    return result;
  }

  static Future<File> saveTempFile(Uint8List bytes, String extension) async {
    final dir = await getTemporaryDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File(p.join(dir.path, 'roluck_$timestamp.$extension'));
    await file.writeAsBytes(bytes);
    return file;
  }

  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
  }

  static double calculateSavings(int original, int result) {
    if (original == 0) return 0;
    return ((original - result) / original * 100);
  }
}
