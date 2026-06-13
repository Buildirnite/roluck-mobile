import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_viewer.dart';
import '../../../shared/widgets/thumb_strip.dart';

/// Une varias imágenes en una sola "imagen larga" (vertical u horizontal),
/// ideal para juntar capturas de pantalla.
class ImagenLargaScreen extends StatefulWidget {
  const ImagenLargaScreen({super.key});

  @override
  State<ImagenLargaScreen> createState() => _ImagenLargaScreenState();
}

class _ImagenLargaScreenState extends State<ImagenLargaScreen> {
  List<File> _images = [];
  bool _vertical = true;
  bool _isProcessing = false;
  Uint8List? _result;

  Future<void> _pick() async {
    final picked = await ImagePicker().pickMultiImage();
    if (picked.isNotEmpty) {
      setState(() {
        // Se agregan al final de la selección actual.
        _images = [..._images, ...picked.map((x) => File(x.path))];
        _result = null;
      });
    }
  }

  Future<void> _join() async {
    if (_images.length < 2) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecciona al menos 2 imágenes')),
      );
      return;
    }
    setState(() => _isProcessing = true);
    final frames = <Uint8List>[];
    for (final f in _images) {
      frames.add(await f.readAsBytes());
    }
    final result = await compute(stitchImagesOp, {
      'frames': frames,
      'vertical': _vertical,
    });
    setState(() {
      _result = result.isEmpty ? null : result;
      _isProcessing = false;
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImageUtils.saveTempFile(_result!, 'png');
    await ImageGallerySaverPlus.saveFile(file.path);
    if (mounted) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Imagen guardada en galería')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Imagen larga')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _pick,
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
                      'Mantén pulsada una miniatura y arrástrala para reordenar',
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
              const Text('Dirección',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Vertical'),
                      selected: _vertical,
                      onSelected: (_) => setState(() => _vertical = true),
                      selectedColor: AppColors.accentDim,
                      backgroundColor: AppColors.bgElevated,
                      labelStyle: TextStyle(
                          color: _vertical
                              ? AppColors.accent
                              : AppColors.textPrimary),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ChoiceChip(
                      label: const Text('Horizontal'),
                      selected: !_vertical,
                      onSelected: (_) => setState(() => _vertical = false),
                      selectedColor: AppColors.accentDim,
                      backgroundColor: AppColors.bgElevated,
                      labelStyle: TextStyle(
                          color: !_vertical
                              ? AppColors.accent
                              : AppColors.textPrimary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _join,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Unir'),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
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
                          bytes: _result!, fileName: 'imagen_larga.png'),
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
