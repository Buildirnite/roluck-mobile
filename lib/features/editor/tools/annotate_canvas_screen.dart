import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import '../../../core/constants/colors.dart';

class _Stroke {
  final List<Offset> points;
  final Color color;
  final double width;
  _Stroke(this.points, this.color, this.width);
}

/// Lienzo de dibujo a mano alzada sobre la imagen. Devuelve, vía Navigator.pop,
/// los bytes PNG de la imagen con las anotaciones (o null si se cancela).
class AnnotateCanvasScreen extends StatefulWidget {
  final Uint8List imageBytes;
  const AnnotateCanvasScreen({super.key, required this.imageBytes});

  @override
  State<AnnotateCanvasScreen> createState() => _AnnotateCanvasScreenState();
}

class _AnnotateCanvasScreenState extends State<AnnotateCanvasScreen> {
  final _boundaryKey = GlobalKey();
  final List<_Stroke> _strokes = [];
  _Stroke? _current;

  Color _color = AppColors.accent;
  double _width = 6;
  bool _saving = false;

  ui.Image? _image;

  static const _palette = [
    AppColors.accent,
    Colors.white,
    Colors.black,
    Colors.red,
    Colors.blue,
    Colors.yellow,
  ];

  @override
  void initState() {
    super.initState();
    _decode();
  }

  Future<void> _decode() async {
    final image = await decodeImageFromList(widget.imageBytes);
    if (!mounted) return;
    setState(() => _image = image);
  }

  void _onPanStart(DragStartDetails d) {
    setState(() {
      _current = _Stroke([d.localPosition], _color, _width);
      _strokes.add(_current!);
    });
  }

  void _onPanUpdate(DragUpdateDetails d) {
    setState(() => _current?.points.add(d.localPosition));
  }

  Future<void> _save() async {
    if (_image == null || _saving) return;
    setState(() => _saving = true);
    try {
      final boundary = _boundaryKey.currentContext!.findRenderObject()
          as RenderRepaintBoundary;
      // pixelRatio elegido para reconstruir a la resolución original de la imagen.
      final pixelRatio = _image!.width / boundary.size.width;
      final rendered = await boundary.toImage(pixelRatio: pixelRatio);
      final data = await rendered.toByteData(format: ui.ImageByteFormat.png);
      if (!mounted) return;
      Navigator.of(context).pop(data?.buffer.asUint8List());
    } catch (_) {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        title: const Text('Anotar'),
        actions: [
          IconButton(
            tooltip: 'Deshacer trazo',
            onPressed: _strokes.isEmpty || _saving
                ? null
                : () => setState(() => _strokes.removeLast()),
            icon: const Icon(Icons.undo),
          ),
          IconButton(
            tooltip: 'Limpiar',
            onPressed: _strokes.isEmpty || _saving
                ? null
                : () => setState(() => _strokes.clear()),
            icon: const Icon(Icons.delete_outline),
          ),
          IconButton(
            tooltip: 'Guardar',
            onPressed: _saving ? null : _save,
            icon: const Icon(Icons.check, color: AppColors.accent),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Center(
              child: _image == null
                  ? const CircularProgressIndicator(color: AppColors.accent)
                  : AspectRatio(
                      aspectRatio: _image!.width / _image!.height,
                      child: RepaintBoundary(
                        key: _boundaryKey,
                        child: GestureDetector(
                          onPanStart: _onPanStart,
                          onPanUpdate: _onPanUpdate,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              Image.memory(widget.imageBytes,
                                  fit: BoxFit.fill),
                              CustomPaint(painter: _StrokePainter(_strokes)),
                            ],
                          ),
                        ),
                      ),
                    ),
            ),
          ),
          _buildControls(),
        ],
      ),
    );
  }

  Widget _buildControls() {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      color: AppColors.bgSurface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              const Icon(Icons.line_weight, color: AppColors.textMuted, size: 18),
              Expanded(
                child: Slider(
                  value: _width,
                  min: 2,
                  max: 30,
                  activeColor: AppColors.accent,
                  onChanged: (v) => setState(() => _width = v),
                ),
              ),
              SizedBox(
                width: 28,
                child: Text('${_width.round()}',
                    textAlign: TextAlign.end,
                    style: const TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: _palette.map((c) {
              final selected = c == _color;
              return GestureDetector(
                onTap: () => setState(() => _color = c),
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: c,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: selected ? AppColors.textPrimary : AppColors.border,
                      width: selected ? 3 : 1,
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _StrokePainter extends CustomPainter {
  final List<_Stroke> strokes;
  _StrokePainter(this.strokes);

  @override
  void paint(Canvas canvas, Size size) {
    for (final stroke in strokes) {
      final paint = Paint()
        ..color = stroke.color
        ..strokeWidth = stroke.width
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round
        ..style = PaintingStyle.stroke;

      if (stroke.points.length == 1) {
        canvas.drawPoints(ui.PointMode.points, stroke.points, paint);
        continue;
      }
      final path = Path()..moveTo(stroke.points.first.dx, stroke.points.first.dy);
      for (final p in stroke.points.skip(1)) {
        path.lineTo(p.dx, p.dy);
      }
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_StrokePainter oldDelegate) => true;
}
