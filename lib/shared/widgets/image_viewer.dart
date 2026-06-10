import 'package:flutter/material.dart';

/// Visor de imagen a pantalla completa con zoom (pellizco), desplazamiento y
/// doble toque para acercar/alejar rápido. Acepta cualquier [ImageProvider],
/// así sirve tanto para archivos (`FileImage`) como para bytes en memoria
/// (`MemoryImage`, incl. GIF).
class FullScreenImageViewer extends StatefulWidget {
  // Se muestra [image] como `Image`, o [child] si se pasa un widget propio
  // (p. ej. `AvifImage`, que Flutter no puede decodificar como ImageProvider).
  final ImageProvider? image;
  final Widget? child;

  const FullScreenImageViewer({super.key, this.image, this.child})
      : assert(image != null || child != null,
            'Hay que pasar image o child');

  /// Abre el visor con un [ImageProvider].
  static Future<void> open(BuildContext context, ImageProvider image) {
    return _push(context, FullScreenImageViewer(image: image));
  }

  /// Abre el visor con un widget de imagen propio (p. ej. `AvifImage`).
  static Future<void> openWidget(BuildContext context, Widget child) {
    return _push(context, FullScreenImageViewer(child: child));
  }

  static Future<void> _push(BuildContext context, Widget viewer) {
    return Navigator.of(context).push(
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, _, _) => viewer,
        transitionsBuilder: (_, animation, _, child) =>
            FadeTransition(opacity: animation, child: child),
      ),
    );
  }

  @override
  State<FullScreenImageViewer> createState() => _FullScreenImageViewerState();
}

class _FullScreenImageViewerState extends State<FullScreenImageViewer>
    with SingleTickerProviderStateMixin {
  // Escala a la que lleva el doble toque cuando la imagen está sin acercar.
  static const double _doubleTapScale = 3.0;

  final TransformationController _controller = TransformationController();
  late final AnimationController _animController;
  Animation<Matrix4>? _animation;
  // Posición del último doble toque, para acercar centrado en ese punto.
  Offset _doubleTapPos = Offset.zero;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 250),
    )..addListener(() {
        if (_animation != null) _controller.value = _animation!.value;
      });
  }

  @override
  void dispose() {
    _animController.dispose();
    _controller.dispose();
    super.dispose();
  }

  void _animateTo(Matrix4 target) {
    _animation = Matrix4Tween(
      begin: _controller.value,
      end: target,
    ).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOut),
    );
    _animController.forward(from: 0);
  }

  void _handleDoubleTap() {
    // Si ya está acercada, volver al tamaño original; si no, acercar al punto.
    final isZoomedIn = _controller.value.getMaxScaleOnAxis() > 1.01;
    if (isZoomedIn) {
      _animateTo(Matrix4.identity());
    } else {
      final s = _doubleTapScale;
      // Acercar manteniendo fijo el punto tocado: escala s con la traslación
      // necesaria para que (dx, dy) quede en su sitio. Matriz en columnas.
      final x = -_doubleTapPos.dx * (s - 1);
      final y = -_doubleTapPos.dy * (s - 1);
      final target = Matrix4(
        s, 0, 0, 0,
        0, s, 0, 0,
        0, 0, 1, 0,
        x, y, 0, 1,
      );
      _animateTo(target);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: GestureDetector(
              onDoubleTapDown: (d) => _doubleTapPos = d.localPosition,
              onDoubleTap: _handleDoubleTap,
              child: InteractiveViewer(
                transformationController: _controller,
                minScale: 0.8,
                maxScale: 6,
                child: Center(
                  child: widget.child ??
                      Image(image: widget.image!, gaplessPlayback: true),
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: IconButton(
                onPressed: () => Navigator.of(context).pop(),
                icon: const Icon(Icons.close, color: Colors.white),
                tooltip: 'Cerrar',
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Imagen tocable que abre el [FullScreenImageViewer] con zoom al pulsarla.
/// Muestra una pequeña insignia de lupa para indicar que es interactiva.
class ZoomableImage extends StatelessWidget {
  final ImageProvider image;
  final double? height;
  final double? width;
  final BoxFit fit;
  final BorderRadius borderRadius;
  final bool showHint;

  const ZoomableImage({
    super.key,
    required this.image,
    this.height,
    this.width,
    this.fit = BoxFit.cover,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
    this.showHint = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FullScreenImageViewer.open(context, image),
      child: ClipRRect(
        borderRadius: borderRadius,
        child: Stack(
          children: [
            Image(
              image: image,
              height: height,
              width: width,
              fit: fit,
              gaplessPlayback: true,
            ),
            if (showHint)
              Positioned(
                right: 8,
                bottom: 8,
                child: Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.zoom_in,
                    color: Colors.white,
                    size: 18,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
