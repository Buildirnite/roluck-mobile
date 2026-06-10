import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;

class ColorPaletteExtractor {
  static List<Color> extractDominantColors(Uint8List imageBytes, {int count = 5}) {
    final image = img.decodeImage(imageBytes);
    if (image == null) return [];

    final Map<int, int> colorCounts = {};
    final step = (image.width * image.height / 1000).clamp(1, 100).toInt();

    for (var i = 0; i < image.width * image.height; i += step) {
      final x = i % image.width;
      final y = i ~/ image.width;
      final pixel = image.getPixel(x, y);
      // Cuantizar a reducir variaciones menores
      final r = (pixel.r.toInt() ~/ 32) * 32;
      final g = (pixel.g.toInt() ~/ 32) * 32;
      final b = (pixel.b.toInt() ~/ 32) * 32;
      final key = (r << 16) | (g << 8) | b;
      colorCounts[key] = (colorCounts[key] ?? 0) + 1;
    }

    final sorted = colorCounts.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(count).map((e) {
      final r = (e.key >> 16) & 0xFF;
      final g = (e.key >> 8) & 0xFF;
      final b = e.key & 0xFF;
      return Color.fromARGB(255, r, g, b);
    }).toList();
  }
}
