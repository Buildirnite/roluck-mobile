import 'dart:io';
import 'dart:math';
import 'package:image/image.dart' as img;

/// Genera una foto de muestra colorida (degradado + formas) para usar en las
/// capturas de pantalla de la tienda. No forma parte de la app.
void main() {
  const w = 1600, h = 1200;
  final im = img.Image(width: w, height: h, numChannels: 3);
  // Degradado diagonal cielo→atardecer.
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      final t = (x + y) / (w + h);
      final r = (40 + 200 * t).round().clamp(0, 255);
      final g = (90 + 90 * sin(t * pi)).round().clamp(0, 255);
      final b = (180 - 120 * t).round().clamp(0, 255);
      im.setPixelRgb(x, y, r, g, b);
    }
  }
  // Sol.
  img.fillCircle(im, x: 1180, y: 320, radius: 140,
      color: img.ColorRgb8(255, 220, 120));
  // Montañas.
  img.fillPolygon(im, vertices: [
    img.Point(0, 1200), img.Point(380, 700),
    img.Point(760, 1200),
  ], color: img.ColorRgb8(30, 60, 70));
  img.fillPolygon(im, vertices: [
    img.Point(520, 1200), img.Point(1000, 620),
    img.Point(1480, 1200),
  ], color: img.ColorRgb8(45, 80, 90));
  File('store/sample_photo.jpg').writeAsBytesSync(img.encodeJpg(im, quality: 92));
  stdout.writeln('✓ store/sample_photo.jpg (${w}x$h)');
}
