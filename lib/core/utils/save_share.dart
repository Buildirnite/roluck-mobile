import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

/// Utilidades compartidas para descargar (guardar en una ubicación elegida por
/// el usuario) y compartir resultados desde cualquier herramienta.
class SaveShare {
  /// Deja que el usuario elija dónde guardar [bytes] (carpeta Descargas u otra).
  /// Devuelve true si se guardó.
  static Future<bool> downloadBytes(
    BuildContext context, {
    required Uint8List bytes,
    required String fileName,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final path = await FilePicker.platform.saveFile(
        dialogTitle: 'Guardar archivo',
        fileName: fileName,
        bytes: bytes,
      );
      if (path == null) return false; // cancelado por el usuario
      messenger.showSnackBar(
        SnackBar(content: Text('Guardado: ${p.basename(path)}')),
      );
      return true;
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(content: Text('No se pudo guardar: $e')),
      );
      return false;
    }
  }

  /// Guarda texto en un archivo elegido por el usuario.
  static Future<bool> downloadText(
    BuildContext context, {
    required String text,
    required String fileName,
  }) {
    return downloadBytes(
      context,
      bytes: Uint8List.fromList(utf8.encode(text)),
      fileName: fileName,
    );
  }

  /// Comparte [bytes] como un archivo temporal con el nombre indicado.
  static Future<void> shareBytes({
    required Uint8List bytes,
    required String fileName,
  }) async {
    final dir = await getTemporaryDirectory();
    final file = File(p.join(dir.path, fileName));
    await file.writeAsBytes(bytes);
    await Share.shareXFiles([XFile(file.path)]);
  }

  /// Comparte texto plano mediante la hoja de compartir del sistema.
  static Future<void> shareText(String text) => Share.share(text);
}
