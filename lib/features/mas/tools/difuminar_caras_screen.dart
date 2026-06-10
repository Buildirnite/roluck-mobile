import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_picker_zone.dart';
import '../../../shared/widgets/image_viewer.dart';

/// Detecta caras en una imagen y las difumina automáticamente (privacidad).
class DifuminarCarasScreen extends StatefulWidget {
  const DifuminarCarasScreen({super.key});

  @override
  State<DifuminarCarasScreen> createState() => _DifuminarCarasScreenState();
}

class _DifuminarCarasScreenState extends State<DifuminarCarasScreen> {
  bool _isProcessing = false;
  Uint8List? _result;
  int _faceCount = 0;
  bool _done = false;

  Future<void> _process(File file) async {
    setState(() {
      _isProcessing = true;
      _result = null;
      _done = false;
    });

    // Normalizamos la orientación (horneamos la rotación EXIF) y usamos la MISMA
    // imagen para detectar y para difuminar, así las coordenadas coinciden.
    final raw = await file.readAsBytes();
    final normBytes = await compute(bakeOrientationOp, raw);
    final tempFile = await ImageUtils.saveTempFile(normBytes, 'png');

    final detector = FaceDetector(options: FaceDetectorOptions());
    List<Face> faces = [];
    try {
      faces = await detector.processImage(InputImage.fromFile(tempFile));
    } catch (_) {
    } finally {
      await detector.close();
    }

    if (faces.isEmpty) {
      setState(() {
        _isProcessing = false;
        _faceCount = 0;
        _done = true;
      });
      return;
    }

    final rects = faces
        .map((f) => [
              f.boundingBox.left,
              f.boundingBox.top,
              f.boundingBox.width,
              f.boundingBox.height,
            ])
        .toList();

    final result =
        await compute(blurRegionsOp, {'bytes': normBytes, 'rects': rects});

    if (!mounted) return;
    setState(() {
      _result = result;
      _faceCount = faces.length;
      _isProcessing = false;
      _done = true;
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImageUtils.saveTempFile(_result!, 'png');
    await ImageGallerySaverPlus.saveFile(file.path);
    if (mounted) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Guardado en galería')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Difuminar caras')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePickerZone(onImageSelected: _process),
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            ],
            if (_done && _result == null && _faceCount == 0)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Text('No se detectaron caras',
                    style: TextStyle(color: AppColors.textMuted)),
              ),
            if (_result != null) ...[
              const SizedBox(height: 16),
              Text('$_faceCount cara(s) difuminada(s)',
                  style: const TextStyle(color: AppColors.success)),
              const SizedBox(height: 8),
              ZoomableImage(image: MemoryImage(_result!), fit: BoxFit.contain),
              const SizedBox(height: 12),
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
                      onPressed: () => SaveShare.shareBytes(
                          bytes: _result!, fileName: 'caras_difuminadas.png'),
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
