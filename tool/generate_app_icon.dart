import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Genera los íconos cuadrados de la app a partir de `assets/icon/logo.png`:
///  - assets/icon/app_icon.png         (1024x1024, logo sobre fondo blanco)
///  - assets/icon/app_icon_foreground.png (1024x1024, logo con más margen para
///    la zona segura de los íconos adaptativos de Android)
void main() {
  final raw = img.decodeImage(File('assets/icon/logo.png').readAsBytesSync());
  if (raw == null) {
    stderr.writeln('No se pudo decodificar logo.png');
    exit(1);
  }
  stdout.writeln('Logo original: ${raw.width}x${raw.height}');

  // El logo trae una sombra gris de relieve y alguna marca tenue que el trim
  // normal no quita. Detectamos el CONTENIDO real (lima saturado o líneas
  // oscuras) y contamos por fila/columna, exigiendo un mínimo de píxeles para
  // ignorar ruido suelto y centrar bien el recorte.
  final colCount = List<int>.filled(raw.width, 0);
  final rowCount = List<int>.filled(raw.height, 0);
  for (final p in raw) {
    // Contenido = píxel opaco (el fondo del logo es transparente).
    if (p.a > 32) {
      colCount[p.x.toInt()]++;
      rowCount[p.y.toInt()]++;
    }
  }

  const minRun = 5; // píxeles de contenido para considerar la fila/columna
  final minX = colCount.indexWhere((c) => c > minRun);
  final maxX = colCount.lastIndexWhere((c) => c > minRun);
  final minY = rowCount.indexWhere((c) => c > minRun);
  final maxY = rowCount.lastIndexWhere((c) => c > minRun);

  final logo = img.copyCrop(raw,
      x: minX, y: minY, width: maxX - minX + 1, height: maxY - minY + 1);
  stdout.writeln('Logo recortado: ${logo.width}x${logo.height}');

  // Ícono legacy: logo sobre fondo blanco.
  img.encodePng(_compose(logo, 0.82, transparent: false)).let((b) =>
      File('assets/icon/app_icon.png').writeAsBytesSync(b));
  // Foreground adaptativo: fondo transparente (el sistema pone el blanco) y más
  // margen para la zona segura del recorte circular/squircle.
  img.encodePng(_compose(logo, 0.58, transparent: true)).let((b) =>
      File('assets/icon/app_icon_foreground.png').writeAsBytesSync(b));

  stdout.writeln('Íconos generados en assets/icon/');
}

/// Coloca el [logo] centrado dentro de un cuadrado 1024x1024, ocupando [fill]
/// (0..1) del lado. Si [transparent] es false rellena el fondo con el oscuro
/// de la app (#0A0A0A).
img.Image _compose(img.Image logo, double fill, {required bool transparent}) {
  const size = 1024;
  final canvas = img.Image(width: size, height: size, numChannels: 4);
  if (!transparent) {
    img.fill(canvas, color: img.ColorRgba8(0x0A, 0x0A, 0x0A, 255));
  }

  final maxContent = (size * fill).round();
  final scale = min(maxContent / logo.width, maxContent / logo.height);
  final w = (logo.width * scale).round();
  final h = (logo.height * scale).round();
  final resized = img.copyResize(logo, width: w, height: h,
      interpolation: img.Interpolation.cubic);

  img.compositeImage(canvas, resized,
      dstX: (size - w) ~/ 2, dstY: (size - h) ~/ 2);
  return canvas;
}

extension<T> on T {
  R let<R>(R Function(T) f) => f(this);
}
