import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image/image.dart' as img;
import '../../../core/constants/colors.dart';
import '../../../core/utils/color_palette.dart';
import '../../../shared/widgets/image_picker_zone.dart';

class PaletaScreen extends StatefulWidget {
  const PaletaScreen({super.key});

  @override
  State<PaletaScreen> createState() => _PaletaScreenState();
}

class _PaletaScreenState extends State<PaletaScreen> {
  Uint8List? _bytes;
  img.Image? _decoded;
  List<Color>? _colors;
  Color? _picked;
  // Posición relativa (0..1) del cuentagotas para dibujar el marcador.
  Offset? _markerRel;
  bool _isLoading = false;

  Future<void> _extract(File file) async {
    setState(() => _isLoading = true);
    final bytes = await file.readAsBytes();
    final decoded = img.decodeImage(bytes);
    final colors = ColorPaletteExtractor.extractDominantColors(bytes, count: 12);
    setState(() {
      _bytes = bytes;
      _decoded = decoded;
      _colors = colors;
      _picked = null;
      _markerRel = null;
      _isLoading = false;
    });
  }

  void _pickAt(Offset localPos, Size widgetSize) {
    final image = _decoded;
    if (image == null || widgetSize.width == 0 || widgetSize.height == 0) return;
    final fx = (localPos.dx / widgetSize.width).clamp(0.0, 1.0);
    final fy = (localPos.dy / widgetSize.height).clamp(0.0, 1.0);
    final px = (fx * (image.width - 1)).round();
    final py = (fy * (image.height - 1)).round();
    final pixel = image.getPixel(px, py);
    setState(() {
      _picked = Color.fromARGB(
        255,
        pixel.r.toInt(),
        pixel.g.toInt(),
        pixel.b.toInt(),
      );
      _markerRel = Offset(fx, fy);
    });
  }

  String _colorToHex(Color c) {
    final r = (c.r * 255.0).round().clamp(0, 255);
    final g = (c.g * 255.0).round().clamp(0, 255);
    final b = (c.b * 255.0).round().clamp(0, 255);
    return '#${r.toRadixString(16).padLeft(2, '0')}${g.toRadixString(16).padLeft(2, '0')}${b.toRadixString(16).padLeft(2, '0')}'
        .toUpperCase();
  }

  void _copyHex(String hex) {
    Clipboard.setData(ClipboardData(text: hex));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$hex copiado')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final decoded = _decoded;

    return Scaffold(
      appBar: AppBar(title: const Text('Paleta de colores')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePickerZone(onImageSelected: _extract),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
            else if (bytes != null && decoded != null) ...[
              // Cuentagotas: toca la imagen para leer el color de ese punto.
              const Text(
                'Toca la imagen para conocer el color de ese punto',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: decoded.width / decoded.height,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    return GestureDetector(
                      onTapDown: (d) => _pickAt(d.localPosition, size),
                      onPanUpdate: (d) => _pickAt(d.localPosition, size),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.memory(bytes, fit: BoxFit.fill),
                            ),
                            if (_markerRel != null)
                              Positioned(
                                left: _markerRel!.dx * size.width - 11,
                                top: _markerRel!.dy * size.height - 11,
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    color: _picked,
                                    border: Border.all(
                                        color: Colors.white, width: 2),
                                    boxShadow: const [
                                      BoxShadow(
                                          color: Colors.black54, blurRadius: 3),
                                    ],
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 12),
              // Color seleccionado con el cuentagotas.
              if (_picked != null)
                GestureDetector(
                  onTap: () => _copyHex(_colorToHex(_picked!)),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            color: _picked,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: AppColors.border),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Color seleccionado',
                                  style: TextStyle(
                                      color: AppColors.textMuted,
                                      fontSize: 12)),
                              const SizedBox(height: 2),
                              Text(
                                _colorToHex(_picked!),
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontFamily: 'monospace',
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const Icon(Icons.copy,
                            color: AppColors.accent, size: 20),
                      ],
                    ),
                  ),
                ),
              const SizedBox(height: 20),
              // Paleta de colores dominantes.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Colores dominantes',
                    style: TextStyle(
                        color: AppColors.textMuted,
                        fontSize: 13,
                        fontWeight: FontWeight.bold),
                  ),
                  if (_colors != null && _colors!.isNotEmpty)
                    TextButton.icon(
                      onPressed: () {
                        final all =
                            _colors!.map(_colorToHex).join(', ');
                        Clipboard.setData(ClipboardData(text: all));
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content: Text(
                                  'Paleta copiada (${_colors!.length} colores)')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 14),
                      label: const Text('Copiar todos',
                          style: TextStyle(fontSize: 12)),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.accent),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Toca un color para copiar su código',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 10),
              if (_colors != null)
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _colors!.map((c) {
                    final hex = _colorToHex(c);
                    return GestureDetector(
                      onTap: () => _copyHex(hex),
                      child: Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          color: c,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        alignment: Alignment.bottomCenter,
                        padding: const EdgeInsets.only(bottom: 4),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            hex,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 9,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
            ],
          ],
        ),
      ),
    );
  }
}
