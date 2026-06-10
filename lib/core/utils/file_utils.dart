import 'dart:io';
import 'package:path_provider/path_provider.dart';

class FileUtils {
  /// Borra los archivos temporales que genera la app (prefijo `roluck_`) de
  /// sesiones anteriores. Es best-effort: si algo falla, se ignora.
  static Future<void> cleanTempFiles() async {
    try {
      final dir = await getTemporaryDirectory();
      for (final entity in dir.listSync()) {
        if (entity is File && entity.path.contains('roluck_')) {
          await entity.delete();
        }
      }
    } catch (_) {
      // Sin acceso o sin temporales: nada que limpiar.
    }
  }
}
