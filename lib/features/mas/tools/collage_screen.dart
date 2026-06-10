import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_viewer.dart';

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  List<File> _images = [];
  int _cols = 2;
  bool _isProcessing = false;
  Uint8List? _result;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() => _images = picked.map((x) => File(x.path)).toList());
    }
  }

  Future<void> _generateCollage() async {
    if (_images.isEmpty) return;
    setState(() => _isProcessing = true);

    final decoded = <img.Image>[];
    for (final f in _images) {
      final bytes = await f.readAsBytes();
      final d = img.decodeImage(bytes);
      if (d != null) decoded.add(d);
    }

    if (decoded.isEmpty) {
      setState(() => _isProcessing = false);
      return;
    }

    // Redimensionar todas al mismo tamaño
    const cellSize = 400;
    final resized = decoded.map((i) =>
        img.copyResize(i, width: cellSize, height: cellSize)).toList();

    final rows = (resized.length / _cols).ceil();
    final canvas = img.Image(
      width: cellSize * _cols,
      height: cellSize * rows,
    );

    for (var i = 0; i < resized.length; i++) {
      final x = (i % _cols) * cellSize;
      final y = (i ~/ _cols) * cellSize;
      img.compositeImage(canvas, resized[i], dstX: x, dstY: y);
    }

    setState(() {
      _result = Uint8List.fromList(img.encodePng(canvas));
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Collage')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pickImages,
              icon: const Icon(Icons.photo_library),
              label: Text(_images.isEmpty
                  ? 'Seleccionar imágenes'
                  : '${_images.length} imágenes seleccionadas'),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 16),
              Text('Columnas: $_cols',
                  style: const TextStyle(color: AppColors.textMuted)),
              Slider(
                value: _cols.toDouble(),
                min: 1, max: 5, divisions: 4,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _cols = v.round()),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _generateCollage,
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear collage'),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              ZoomableImage(
                image: MemoryImage(_result!),
                fit: BoxFit.contain,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final scaffold = ScaffoldMessenger.of(context);
                        final file =
                            await ImageUtils.saveTempFile(_result!, 'png');
                        await ImageGallerySaverPlus.saveFile(file.path);
                        if (mounted) {
                          scaffold.showSnackBar(
                            const SnackBar(content: Text('Collage guardado')),
                          );
                        }
                      },
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SaveShare.shareBytes(
                        bytes: _result!,
                        fileName: 'collage.png',
                      ),
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
