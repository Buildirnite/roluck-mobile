import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/image_picker_zone.dart';
import '../../../shared/widgets/image_viewer.dart';

class DividirScreen extends StatefulWidget {
  const DividirScreen({super.key});

  @override
  State<DividirScreen> createState() => _DividirScreenState();
}

class _DividirScreenState extends State<DividirScreen> {
  File? _image;
  int _rows = 3;
  int _cols = 3;
  bool _isProcessing = false;
  List<Uint8List>? _parts;

  Future<void> _dividir() async {
    if (_image == null) return;
    setState(() => _isProcessing = true);

    final bytes = await _image!.readAsBytes();
    final decoded = img.decodeImage(bytes);
    if (decoded == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final partW = decoded.width ~/ _cols;
    final partH = decoded.height ~/ _rows;
    final parts = <Uint8List>[];

    for (var r = 0; r < _rows; r++) {
      for (var c = 0; c < _cols; c++) {
        final cropped = img.copyCrop(decoded,
            x: c * partW, y: r * partH, width: partW, height: partH);
        parts.add(Uint8List.fromList(img.encodePng(cropped)));
      }
    }

    setState(() {
      _parts = parts;
      _isProcessing = false;
    });
  }

  Future<void> _saveAll() async {
    if (_parts == null) return;
    for (final part in _parts!) {
      final file = await ImageUtils.saveTempFile(part, 'png');
      await ImageGallerySaverPlus.saveFile(file.path);
    }
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Todas las partes guardadas')),
      );
    }
  }

  Future<void> _shareAll() async {
    if (_parts == null) return;
    final files = <XFile>[];
    for (var i = 0; i < _parts!.length; i++) {
      final file = await ImageUtils.saveTempFile(_parts![i], 'png');
      files.add(XFile(file.path));
    }
    await Share.shareXFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Dividir imagen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null)
              ImagePickerZone(onImageSelected: (f) => setState(() => _image = f))
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Filas: $_rows',
                            style: const TextStyle(color: AppColors.textMuted)),
                        Slider(
                          value: _rows.toDouble(),
                          min: 2, max: 10, divisions: 8,
                          activeColor: AppColors.accent,
                          onChanged: (v) => setState(() => _rows = v.round()),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        Text('Columnas: $_cols',
                            style: const TextStyle(color: AppColors.textMuted)),
                        Slider(
                          value: _cols.toDouble(),
                          min: 2, max: 10, divisions: 8,
                          activeColor: AppColors.accent,
                          onChanged: (v) => setState(() => _cols = v.round()),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _dividir,
                child: _isProcessing
                    ? const SizedBox(height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Dividir'),
              ),
              if (_parts != null) ...[
                const SizedBox(height: 16),
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: _cols,
                    mainAxisSpacing: 4,
                    crossAxisSpacing: 4,
                  ),
                  itemCount: _parts!.length,
                  itemBuilder: (context, i) => GestureDetector(
                    onTap: () => FullScreenImageViewer.open(
                      context,
                      MemoryImage(_parts![i]),
                    ),
                    child: Image.memory(_parts![i], fit: BoxFit.cover),
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: _saveAll,
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar todas'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _shareAll,
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
