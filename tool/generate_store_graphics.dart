import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Genera los gráficos requeridos por Google Play Store a partir del ícono ya
/// existente (`assets/icon/app_icon.png`, 1024x1024, logo sobre fondo #0A0A0A):
///   - store/play_icon_512.png        (512x512)  — ícono de la ficha
///   - store/feature_graphic.png      (1024x500) — gráfico de cabecera
///
/// Reutilizamos el logo ya tipografiado para evitar rasterizar fuentes feas.
void main() {
  final icon = img.decodeImage(File('assets/icon/app_icon.png').readAsBytesSync());
  if (icon == null) {
    stderr.writeln('No se pudo decodificar assets/icon/app_icon.png');
    exit(1);
  }
  Directory('store').createSync(recursive: true);

  // 1) Ícono de la ficha: 512x512.
  final icon512 = img.copyResize(icon,
      width: 512, height: 512, interpolation: img.Interpolation.average);
  File('store/play_icon_512.png').writeAsBytesSync(img.encodePng(icon512));
  stdout.writeln('✓ store/play_icon_512.png (512x512)');

  // 2) Feature graphic: 1024x500, fondo oscuro de la app con el logo centrado.
  const w = 1024, h = 500;
  final canvas = img.Image(width: w, height: h, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(0x0A, 0x0A, 0x0A, 255));

  // El logo cuadrado escalado para dejar margen vertical (~6%).
  final content = (h * 0.88).round(); // 440 px de alto aprox.
  final scale = min(content / icon.width, content / icon.height);
  final lw = (icon.width * scale).round();
  final lh = (icon.height * scale).round();
  final logo = img.copyResize(icon,
      width: lw, height: lh, interpolation: img.Interpolation.cubic);
  img.compositeImage(canvas, logo, dstX: (w - lw) ~/ 2, dstY: (h - lh) ~/ 2);

  File('store/feature_graphic.png').writeAsBytesSync(img.encodePng(canvas));
  stdout.writeln('✓ store/feature_graphic.png (1024x500)');
}
