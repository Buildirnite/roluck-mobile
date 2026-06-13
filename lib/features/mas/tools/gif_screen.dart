import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/image_viewer.dart';
import '../../../shared/widgets/thumb_strip.dart';

/// Crea un GIF animado a partir de varias imágenes seleccionadas, en el orden
/// en que se eligieron, con una velocidad ajustable.
class GifScreen extends StatefulWidget {
  const GifScreen({super.key});

  @override
  State<GifScreen> createState() => _GifScreenState();
}

class _GifScreenState extends State<GifScreen> {
  List<File> _images = [];
  double _delayMs = 200;
  bool _isProcessing = false;
  Uint8List? _result;

  Future<void> _pickImages() async {
    final picker = ImagePicker();
    final picked = await picker.pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        // Se agregan al final de la selección actual.
        _images = [..._images, ...picked.map((x) => File(x.path))];
        _result = null;
      });
    }
  }

  Future<void> _generateGif() async {
    if (_images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos 2 imágenes')),
      );
      return;
    }
    setState(() => _isProcessing = true);

    final framesBytes = <Uint8List>[];
    for (final f in _images) {
      framesBytes.add(await f.readAsBytes());
    }

    final result = await compute(gifFromImagesOp, {
      'frames': framesBytes,
      'delayMs': _delayMs.round(),
      'maxWidth': 480,
    });

    setState(() {
      _result = result.isEmpty ? null : result;
      _isProcessing = false;
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    final scaffold = ScaffoldMessenger.of(context);
    final file = await ImageUtils.saveTempFile(_result!, 'gif');
    await ImageGallerySaverPlus.saveFile(file.path);
    if (mounted) {
      scaffold.showSnackBar(const SnackBar(content: Text('GIF guardado')));
    }
  }

  Future<void> _share() async {
    if (_result == null) return;
    final file = await ImageUtils.saveTempFile(_result!, 'gif');
    await Share.shareXFiles([XFile(file.path)]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GIF animado')),
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
                  : 'Añadir más (${_images.length} elegidas)'),
            ),
            if (_images.isNotEmpty) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Mantén pulsado un cuadro y arrástralo para reordenar',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 12),
                    ),
                  ),
                  TextButton(
                    onPressed: () => setState(() {
                      _images = [];
                      _result = null;
                    }),
                    child: const Text('Quitar todas',
                        style: TextStyle(
                            color: AppColors.textMuted, fontSize: 12)),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              // Cuadros de la animación: reordenables y con ✕ para quitar.
              ReorderableThumbStrip(
                images: _images,
                onReorder: (oldIndex, newIndex) => setState(() {
                  final item = _images.removeAt(oldIndex);
                  _images.insert(newIndex, item);
                  _result = null;
                }),
                onRemove: (i) => setState(() {
                  _images.removeAt(i);
                  _result = null;
                }),
              ),
              const SizedBox(height: 16),
              Text('Velocidad: ${_delayMs.round()} ms por cuadro',
                  style: const TextStyle(color: AppColors.textMuted)),
              Slider(
                value: _delayMs,
                min: 50,
                max: 1000,
                divisions: 19,
                activeColor: AppColors.accent,
                label: '${_delayMs.round()} ms',
                onChanged: (v) => setState(() => _delayMs = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _generateGif,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Crear GIF'),
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
