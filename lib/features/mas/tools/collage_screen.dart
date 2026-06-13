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

class CollageScreen extends StatefulWidget {
  const CollageScreen({super.key});

  @override
  State<CollageScreen> createState() => _CollageScreenState();
}

class _CollageScreenState extends State<CollageScreen> {
  List<File> _images = [];
  int _cols = 2;
  double _spacing = 8;
  String _bg = 'white';
  bool _isProcessing = false;
  Uint8List? _result;

  static const _bgOptions = {
    'white': 'Blanco',
    'black': 'Negro',
    'transparent': 'Transparente',
  };

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

  Future<void> _generateCollage() async {
    if (_images.isEmpty) return;
    setState(() => _isProcessing = true);

    final frames = <Uint8List>[];
    for (final f in _images) {
      frames.add(await f.readAsBytes());
    }

    // Todo el trabajo pesado (decodificar, redimensionar, componer) ocurre en
    // un isolate para no congelar la interfaz.
    final result = await compute(collageOp, {
      'frames': frames,
      'cols': _cols,
      'cellSize': 400,
      'spacing': _spacing.round(),
      'bg': _bg,
    });

    if (!mounted) return;
    setState(() {
      _result = result.isEmpty ? null : result;
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
              Text('Columnas: $_cols',
                  style: const TextStyle(color: AppColors.textMuted)),
              Slider(
                value: _cols.toDouble(),
                min: 1, max: 5, divisions: 4,
                activeColor: AppColors.accent,
                onChanged: (v) => setState(() => _cols = v.round()),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Espaciado',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('${_spacing.round()} px',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace')),
                ],
              ),
              Slider(
                value: _spacing,
                min: 0, max: 40, divisions: 20,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.bgElevated,
                label: '${_spacing.round()}',
                onChanged: (v) => setState(() => _spacing = v),
              ),
              const Text('Fondo',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _bgOptions.entries.map((e) {
                  final selected = _bg == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _bg = e.key),
                    selectedColor: AppColors.accentDim,
                    backgroundColor: AppColors.bgElevated,
                    labelStyle: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontSize: 12),
                  );
                }).toList(),
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
                        try {
                          final file =
                              await ImageUtils.saveTempFile(_result!, 'png');
                          await ImageGallerySaverPlus.saveFile(file.path);
                          scaffold.showSnackBar(
                            const SnackBar(content: Text('Collage guardado')),
                          );
                        } catch (_) {
                          scaffold.showSnackBar(
                            const SnackBar(
                                content: Text('No se pudo guardar')),
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
