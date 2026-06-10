import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/save_share.dart';

/// Genera un código QR a partir de texto o una URL y permite guardarlo o
/// compartirlo como imagen.
class QrGeneratorScreen extends StatefulWidget {
  const QrGeneratorScreen({super.key});

  @override
  State<QrGeneratorScreen> createState() => _QrGeneratorScreenState();
}

class _QrGeneratorScreenState extends State<QrGeneratorScreen> {
  final _controller = TextEditingController();
  String _data = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  /// Renderiza el QR a PNG con fondo blanco. Devuelve null si el texto es
  /// demasiado largo para un QR.
  Future<Uint8List?> _renderPng() async {
    try {
      final painter = QrPainter(
        data: _data,
        version: QrVersions.auto,
        gapless: true,
        eyeStyle: const QrEyeStyle(
            eyeShape: QrEyeShape.square, color: Color(0xFF000000)),
        dataModuleStyle: const QrDataModuleStyle(
            dataModuleShape: QrDataModuleShape.square, color: Color(0xFF000000)),
      );
      final data = await painter.toImageData(1024);
      if (data == null) return null;
      return compute(flattenOnWhiteOp, data.buffer.asUint8List());
    } catch (_) {
      return null;
    }
  }

  Future<void> _save() async {
    final messenger = ScaffoldMessenger.of(context);
    final png = await _renderPng();
    if (!mounted) return;
    if (png == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('El texto es demasiado largo')));
      return;
    }
    final file = await ImageUtils.saveTempFile(png, 'png');
    await ImageGallerySaverPlus.saveFile(file.path);
    if (mounted) {
      messenger.showSnackBar(
          const SnackBar(content: Text('QR guardado en galería')));
    }
  }

  Future<void> _share() async {
    final messenger = ScaffoldMessenger.of(context);
    final png = await _renderPng();
    if (png == null) {
      messenger.showSnackBar(
          const SnackBar(content: Text('El texto es demasiado largo')));
      return;
    }
    await SaveShare.shareBytes(bytes: png, fileName: 'qr.png');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Generar QR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _controller,
              maxLines: 3,
              minLines: 1,
              style: const TextStyle(color: AppColors.textPrimary),
              decoration: const InputDecoration(
                labelText: 'Texto o URL',
                labelStyle: TextStyle(color: AppColors.textMuted),
                enabledBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderSide: BorderSide(color: AppColors.accent),
                ),
              ),
              onChanged: (v) => setState(() => _data = v.trim()),
            ),
            const SizedBox(height: 20),
            if (_data.isEmpty)
              const Padding(
                padding: EdgeInsets.all(32),
                child: Text('Escribe algo para generar el QR',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textMuted)),
              )
            else ...[
              Center(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: _data,
                    version: QrVersions.auto,
                    size: 240,
                    backgroundColor: Colors.white,
                    errorStateBuilder: (context, error) => const SizedBox(
                      width: 240,
                      height: 240,
                      child: Center(
                        child: Text(
                          'El texto es demasiado largo para un QR',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.black),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _share,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
