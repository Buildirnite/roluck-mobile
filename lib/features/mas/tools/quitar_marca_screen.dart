import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_picker_zone.dart';
import '../../../shared/widgets/image_viewer.dart';

/// Borrador mágico: el usuario dibuja recuadros sobre los objetos no deseados
/// y se rellenan interpolando el fondo circundante. Funciona mejor sobre
/// fondos uniformes (cielo, paredes, degradados).
class QuitarMarcaScreen extends StatefulWidget {
  const QuitarMarcaScreen({super.key});

  @override
  State<QuitarMarcaScreen> createState() => _QuitarMarcaScreenState();
}

class _QuitarMarcaScreenState extends State<QuitarMarcaScreen> {
  Uint8List? _bytes;
  int _imgW = 0, _imgH = 0;
  // Recuadros marcados, en coordenadas relativas (0..1) de la imagen.
  final List<Rect> _rects = [];
  Offset? _dragStart;
  Rect? _dragRect;
  bool _isProcessing = false;
  bool _processed = false;

  Future<void> _load(File file) async {
    final bytes = await file.readAsBytes();
    final dims = await compute(imageDimensionsOp, bytes);
    if (!mounted || dims[0] == 0) return;
    setState(() {
      _bytes = bytes;
      _imgW = dims[0];
      _imgH = dims[1];
      _rects.clear();
      _dragRect = null;
      _processed = false;
    });
  }

  Offset _norm(Offset local, Size size) => Offset(
        (local.dx / size.width).clamp(0.0, 1.0),
        (local.dy / size.height).clamp(0.0, 1.0),
      );

  void _onPanStart(Offset local, Size size) {
    _dragStart = _norm(local, size);
    setState(() => _dragRect = Rect.fromPoints(_dragStart!, _dragStart!));
  }

  void _onPanUpdate(Offset local, Size size) {
    final start = _dragStart;
    if (start == null) return;
    setState(() => _dragRect = Rect.fromPoints(start, _norm(local, size)));
  }

  void _onPanEnd() {
    final rect = _dragRect;
    _dragStart = null;
    if (rect == null) return;
    setState(() {
      _dragRect = null;
      // Ignorar arrastres minúsculos (toques accidentales).
      if (rect.width > 0.01 && rect.height > 0.01) _rects.add(rect);
    });
  }

  Future<void> _process() async {
    final bytes = _bytes;
    if (bytes == null || _rects.isEmpty) return;
    setState(() => _isProcessing = true);

    final rects = _rects
        .map((r) => [
              r.left * _imgW,
              r.top * _imgH,
              r.width * _imgW,
              r.height * _imgH,
            ])
        .toList();
    final result =
        await compute(inpaintRegionsOp, {'bytes': bytes, 'rects': rects});

    if (!mounted) return;
    setState(() {
      // El resultado pasa a ser la imagen de trabajo: se pueden marcar más
      // zonas y volver a quitar, las veces que haga falta.
      _bytes = result;
      _rects.clear();
      _isProcessing = false;
      _processed = true;
    });
  }

  Future<void> _save() async {
    if (_bytes == null) return;
    final messenger = ScaffoldMessenger.of(context);
    try {
      final file = await ImageUtils.saveTempFile(_bytes!, 'png');
      await ImageGallerySaverPlus.saveFile(file.path);
      messenger.showSnackBar(
          const SnackBar(content: Text('Guardado en galería')));
    } catch (_) {
      messenger.showSnackBar(
          const SnackBar(content: Text('No se pudo guardar')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;

    return Scaffold(
      appBar: AppBar(title: const Text('Borrador mágico')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (bytes == null)
              ImagePickerZone(onImageSelected: _load)
            else ...[
              const Text(
                'Dibuja un recuadro sobre el objeto a borrar arrastrando el '
                'dedo. Puedes marcar varias zonas. Funciona mejor sobre '
                'fondos uniformes.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
              const SizedBox(height: 8),
              AspectRatio(
                aspectRatio: _imgW / _imgH,
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final size = constraints.biggest;
                    Rect toPx(Rect r) => Rect.fromLTWH(
                          r.left * size.width,
                          r.top * size.height,
                          r.width * size.width,
                          r.height * size.height,
                        );
                    return GestureDetector(
                      onPanStart: (d) => _onPanStart(d.localPosition, size),
                      onPanUpdate: (d) => _onPanUpdate(d.localPosition, size),
                      onPanEnd: (_) => _onPanEnd(),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: Image.memory(bytes,
                                  fit: BoxFit.fill, gaplessPlayback: true),
                            ),
                            for (final r in [..._rects, ?_dragRect])
                              Positioned.fromRect(
                                rect: toPx(r),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: AppColors.accent
                                        .withValues(alpha: 0.25),
                                    border: Border.all(
                                        color: AppColors.accent, width: 2),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => setState(() {
                      _bytes = null;
                      _rects.clear();
                      _processed = false;
                    }),
                    child: const Text('Otra imagen',
                        style: TextStyle(color: AppColors.accent)),
                  ),
                  if (_rects.isNotEmpty)
                    TextButton.icon(
                      onPressed: () =>
                          setState(() => _rects.removeLast()),
                      icon: const Icon(Icons.undo, size: 16),
                      label: Text('Deshacer (${_rects.length})'),
                      style: TextButton.styleFrom(
                          foregroundColor: AppColors.textMuted),
                    ),
                ],
              ),
              const SizedBox(height: 4),
              ElevatedButton.icon(
                onPressed: (_isProcessing || _rects.isEmpty) ? null : _process,
                icon: _isProcessing
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.healing),
                label: Text(_rects.isEmpty
                    ? 'Marca una zona para quitar'
                    : 'Quitar ${_rects.length} zona(s)'),
              ),
              if (_processed && _rects.isEmpty) ...[
                const SizedBox(height: 12),
                const Text(
                  '✓ Zonas rellenadas. Marca más zonas si hace falta, o '
                  'guarda el resultado.',
                  style: TextStyle(color: AppColors.success, fontSize: 13),
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
                        onPressed: () => SaveShare.shareBytes(
                            bytes: bytes, fileName: 'borrado.png'),
                        icon: const Icon(Icons.share),
                        label: const Text('Compartir'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => FullScreenImageViewer.open(
                      context, MemoryImage(bytes)),
                  icon: const Icon(Icons.zoom_in),
                  label: const Text('Ver a pantalla completa'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                  ),
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
