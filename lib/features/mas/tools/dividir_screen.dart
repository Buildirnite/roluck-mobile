import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
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
  int _imgW = 0, _imgH = 0;
  int _rows = 3;
  int _cols = 3;
  bool _isProcessing = false;
  List<Uint8List>? _parts;

  Future<void> _onPick(File file) async {
    final dims = await compute(imageDimensionsOp, await file.readAsBytes());
    if (!mounted || dims[0] == 0) return;
    setState(() {
      _image = file;
      _imgW = dims[0];
      _imgH = dims[1];
      _parts = null;
    });
  }

  Future<void> _dividir() async {
    if (_image == null) return;
    if (_rows == 1 && _cols == 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Elige al menos 2 partes')),
      );
      return;
    }
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
    final messenger = ScaffoldMessenger.of(context);
    var saved = 0;
    for (final part in _parts!) {
      try {
        final file = await ImageUtils.saveTempFile(part, 'png');
        await ImageGallerySaverPlus.saveFile(file.path);
        saved++;
      } catch (_) {
        // Se omite la parte que falló y se continúa con las demás.
      }
    }
    messenger.showSnackBar(
      SnackBar(
          content: Text(saved == _parts!.length
              ? 'Todas las partes guardadas'
              : '$saved de ${_parts!.length} partes guardadas')),
    );
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
              ImagePickerZone(onImageSelected: _onPick)
            else ...[
              // Vista previa con las líneas de corte según filas/columnas.
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxHeight: 320),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: AspectRatio(
                      aspectRatio: _imgW / _imgH,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          final size = constraints.biggest;
                          return Stack(
                            children: [
                              Positioned.fill(
                                child:
                                    Image.file(_image!, fit: BoxFit.fill),
                              ),
                              for (var i = 1; i < _cols; i++)
                                Positioned(
                                  left: size.width * i / _cols - 0.75,
                                  top: 0,
                                  bottom: 0,
                                  child: Container(
                                    width: 1.5,
                                    color: AppColors.accent
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                              for (var i = 1; i < _rows; i++)
                                Positioned(
                                  top: size.height * i / _rows - 0.75,
                                  left: 0,
                                  right: 0,
                                  child: Container(
                                    height: 1.5,
                                    color: AppColors.accent
                                        .withValues(alpha: 0.85),
                                  ),
                                ),
                            ],
                          );
                        },
                      ),
                    ),
                  ),
                ),
              ),
              TextButton(
                onPressed: _isProcessing
                    ? null
                    : () => setState(() {
                          _image = null;
                          _parts = null;
                        }),
                child: const Text('Cambiar imagen',
                    style: TextStyle(color: AppColors.accent)),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Expanded(
                    child: Column(
                      children: [
                        Text('Filas: $_rows',
                            style: const TextStyle(color: AppColors.textMuted)),
                        Slider(
                          value: _rows.toDouble(),
                          min: 1, max: 10, divisions: 9,
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
                          min: 1, max: 10, divisions: 9,
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
