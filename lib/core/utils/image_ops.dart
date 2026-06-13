import 'dart:math';
import 'dart:typed_data';
import 'package:image/image.dart' as img;

/// Operaciones de procesamiento de imagen pensadas para ejecutarse en un
/// isolate mediante `compute`. Cada función recibe un único argumento
/// serializable y devuelve los bytes resultantes codificados en PNG (formato
/// sin pérdida, para no degradar la imagen al encadenar varias ediciones).
/// La compresión/cambio de formato final se hace con la herramienta dedicada.

/// Rota la imagen el número de grados indicado (positivo = sentido horario).
Uint8List rotateImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final degrees = args['degrees'] as num;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final rotated = img.copyRotate(decoded, angle: degrees);
  return Uint8List.fromList(img.encodePng(rotated));
}

/// Voltea la imagen. `horizontal` = true espeja en el eje horizontal (izq/der),
/// false espeja en el eje vertical (arriba/abajo).
Uint8List flipImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final horizontal = args['horizontal'] as bool;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final flipped = img.flip(
    decoded,
    direction: horizontal ? img.FlipDirection.horizontal : img.FlipDirection.vertical,
  );
  return Uint8List.fromList(img.encodePng(flipped));
}

/// Aplica un filtro de color predefinido identificado por `filter`.
/// Valores admitidos: grayscale, sepia, invert, brightnessUp, brightnessDown,
/// contrastUp, contrastDown, saturationUp, saturationDown.
Uint8List filterImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final filter = args['filter'] as String;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  late final img.Image out;
  switch (filter) {
    case 'grayscale':
      out = img.grayscale(decoded);
    case 'sepia':
      out = img.sepia(decoded);
    case 'invert':
      out = img.invert(decoded);
    case 'normalize':
      // Auto-mejora: estira el histograma al rango completo (más contraste).
      out = img.normalize(decoded, min: 0, max: 255);
    case 'brightnessUp':
      out = img.adjustColor(decoded, brightness: 1.15);
    case 'brightnessDown':
      out = img.adjustColor(decoded, brightness: 0.85);
    case 'contrastUp':
      out = img.contrast(decoded, contrast: 120);
    case 'contrastDown':
      out = img.contrast(decoded, contrast: 80);
    case 'saturationUp':
      out = img.adjustColor(decoded, saturation: 1.4);
    case 'saturationDown':
      out = img.adjustColor(decoded, saturation: 0.6);
    default:
      out = decoded;
  }
  return Uint8List.fromList(img.encodePng(out));
}

/// Redimensiona la imagen a `width` x `height` (en píxeles).
Uint8List resizeImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final width = args['width'] as int;
  final height = args['height'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final resized = img.copyResize(
    decoded,
    width: width,
    height: height,
    interpolation: img.Interpolation.cubic,
  );
  return Uint8List.fromList(img.encodePng(resized));
}

/// Aplica un desenfoque gaussiano con el `radius` indicado.
Uint8List blurImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final radius = args['radius'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final blurred = img.gaussianBlur(decoded, radius: radius);
  return Uint8List.fromList(img.encodePng(blurred));
}

/// Recodifica la imagen como JPEG con la `quality` dada (1-100).
/// Devuelve bytes JPEG (a diferencia del resto de operaciones, que dan PNG),
/// porque el objetivo de esta herramienta es reducir el tamaño del archivo.
Uint8List compressImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final quality = args['quality'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  return Uint8List.fromList(img.encodeJpg(decoded, quality: quality));
}

/// Estampa un texto como marca de agua. `position` admite: topLeft, topRight,
/// bottomLeft, bottomRight, center. `size` admite: s, m, l. `opacity` (0..1)
/// regula la opacidad del texto (por defecto 0.9).
Uint8List watermarkImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final text = args['text'] as String;
  final position = args['position'] as String;
  final size = args['size'] as String;
  final opacity = ((args['opacity'] as num?) ?? 0.9).toDouble();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  final font = switch (size) {
    's' => img.arial14,
    'l' => img.arial48,
    _ => img.arial24,
  };

  // Ancho/alto del texto a partir de las métricas de la fuente bitmap.
  var textWidth = 0;
  for (final c in text.codeUnits) {
    final ch = font.characters[c];
    if (ch != null) textWidth += ch.xAdvance;
  }
  final textHeight = font.lineHeight;

  const margin = 16;
  final maxX = decoded.width - textWidth - margin;
  final maxY = decoded.height - textHeight - margin;
  final (x, y) = switch (position) {
    'topLeft' => (margin, margin),
    'topRight' => (maxX, margin),
    'bottomLeft' => (margin, maxY),
    'center' => ((decoded.width - textWidth) ~/ 2, (decoded.height - textHeight) ~/ 2),
    _ => (maxX, maxY), // bottomRight
  };

  // Sombra sutil para legibilidad sobre fondos claros, y el texto en blanco.
  final textA = (255 * opacity).round().clamp(0, 255);
  final shadowA = (textA * 0.6).round();
  img.drawString(decoded, text,
      font: font, x: x + 2, y: y + 2, color: img.ColorRgba8(0, 0, 0, shadowA));
  img.drawString(decoded, text,
      font: font, x: x, y: y, color: img.ColorRgba8(255, 255, 255, textA));

  return Uint8List.fromList(img.encodePng(decoded));
}

/// Ajusta brillo, contraste, saturación y tono a la vez. Brillo/contraste/
/// saturación van de -100 a 100 (0 = neutro); el tono [hue] en grados (-180..180).
Uint8List adjustImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final brightness = (args['brightness'] as num).toDouble();
  final contrast = (args['contrast'] as num).toDouble();
  final saturation = (args['saturation'] as num).toDouble();
  final hue = (args['hue'] as num?)?.toDouble() ?? 0;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final out = img.adjustColor(
    decoded,
    brightness: 1.0 + brightness / 100.0,
    contrast: 1.0 + contrast / 100.0,
    saturation: 1.0 + saturation / 100.0,
    hue: hue,
  );
  return Uint8List.fromList(img.encodePng(out));
}

/// Aumenta la nitidez de la imagen (convolución con núcleo de realce).
Uint8List sharpenImageOp(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final out = img.convolution(
    decoded,
    filter: [0, -1, 0, -1, 5, -1, 0, -1, 0],
    div: 1,
    offset: 0,
  );
  return Uint8List.fromList(img.encodePng(out));
}

/// Aplica un efecto de viñeta (oscurece los bordes).
Uint8List vignetteImageOp(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final out = img.vignette(decoded);
  return Uint8List.fromList(img.encodePng(out));
}

/// Pixela la imagen con bloques del tamaño [size] (en píxeles).
Uint8List pixelateImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final size = args['size'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final out = img.pixelate(decoded, size: size);
  return Uint8List.fromList(img.encodePng(out));
}

/// Añade un borde/marco de color [r,g,b] de [width] píxeles alrededor.
Uint8List borderImageOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final r = args['r'] as int, g = args['g'] as int, b = args['b'] as int;
  final width = args['width'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final canvas = img.Image(
    width: decoded.width + width * 2,
    height: decoded.height + width * 2,
    numChannels: 4,
  );
  img.fill(canvas, color: img.ColorRgba8(r, g, b, 255));
  img.compositeImage(canvas, decoded, dstX: width, dstY: width);
  return Uint8List.fromList(img.encodePng(canvas));
}

/// Aplica la orientación EXIF a los píxeles y la elimina de los metadatos, para
/// que las coordenadas coincidan con lo que ve un detector (caras, etc.).
Uint8List bakeOrientationOp(Uint8List bytes) {
  final d = img.decodeImage(bytes);
  if (d == null) return bytes;
  final baked = img.bakeOrientation(d);
  return Uint8List.fromList(img.encodePng(baked));
}

/// Difumina las regiones indicadas (cada una [x, y, w, h] en píxeles). Se usa
/// para tapar caras detectadas.
Uint8List blurRegionsOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final rects = (args['rects'] as List).cast<List>();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  for (final r in rects) {
    var x = (r[0] as num).toInt();
    var y = (r[1] as num).toInt();
    var w = (r[2] as num).toInt();
    var h = (r[3] as num).toInt();
    // Acotar a los límites de la imagen.
    x = x.clamp(0, decoded.width - 1);
    y = y.clamp(0, decoded.height - 1);
    w = w.clamp(1, decoded.width - x);
    h = h.clamp(1, decoded.height - y);

    final region = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
    final radius = (max(w, h) / 5).round().clamp(3, 60);
    final blurred = img.gaussianBlur(region, radius: radius);
    img.compositeImage(decoded, blurred, dstX: x, dstY: y);
  }
  return Uint8List.fromList(img.encodePng(decoded));
}

/// Rellena las regiones indicadas (cada una [x, y, w, h] en píxeles)
/// interpolando los colores del borde exterior de cada región (inpainting
/// suave) y difuminando ligeramente el resultado. Sirve para borrar marcas de
/// agua, logos o texto sobre fondos razonablemente uniformes.
Uint8List inpaintRegionsOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final rects = (args['rects'] as List).cast<List>();
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  for (final r in rects) {
    var x = (r[0] as num).round();
    var y = (r[1] as num).round();
    var w = (r[2] as num).round();
    var h = (r[3] as num).round();
    x = x.clamp(0, decoded.width - 1);
    y = y.clamp(0, decoded.height - 1);
    w = w.clamp(1, decoded.width - x);
    h = h.clamp(1, decoded.height - y);

    // Columnas/filas justo fuera de la región, de donde se toman los colores.
    final left = x - 1, right = x + w, top = y - 1, bottom = y + h;
    final hasL = left >= 0, hasR = right < decoded.width;
    final hasT = top >= 0, hasB = bottom < decoded.height;

    for (var py = y; py < y + h; py++) {
      for (var px = x; px < x + w; px++) {
        double sr = 0, sg = 0, sb = 0, sw = 0;
        void add(int sx, int sy, double weight) {
          final p = decoded.getPixel(sx, sy);
          sr += p.r * weight;
          sg += p.g * weight;
          sb += p.b * weight;
          sw += weight;
        }

        // Peso inverso a la distancia a cada borde disponible.
        if (hasL) add(left, py, 1.0 / (px - left));
        if (hasR) add(right, py, 1.0 / (right - px));
        if (hasT) add(px, top, 1.0 / (py - top));
        if (hasB) add(px, bottom, 1.0 / (bottom - py));
        if (sw == 0) continue;
        decoded.setPixelRgba(px, py, (sr / sw).round(), (sg / sw).round(),
            (sb / sw).round(), 255);
      }
    }

    // Difuminado leve solo de la zona rellenada, para disimular el degradado.
    if (w > 8 && h > 8) {
      final region = img.copyCrop(decoded, x: x, y: y, width: w, height: h);
      final blurred = img.gaussianBlur(region, radius: 3);
      img.compositeImage(decoded, blurred, dstX: x, dstY: y);
    }
  }
  return Uint8List.fromList(img.encodePng(decoded));
}

/// Aplana una imagen con transparencia sobre fondo blanco (p. ej. para que un
/// QR generado tenga fondo blanco y sea fácil de escanear).
Uint8List flattenOnWhiteOp(Uint8List bytes) {
  final d = img.decodeImage(bytes);
  if (d == null) return bytes;
  final canvas = img.Image(width: d.width, height: d.height, numChannels: 4);
  img.fill(canvas, color: img.ColorRgba8(255, 255, 255, 255));
  img.compositeImage(canvas, d);
  return Uint8List.fromList(img.encodePng(canvas));
}

/// Recorta la imagen en círculo, dejando las esquinas transparentes.
Uint8List circleCropOp(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final out = img.copyCropCircle(decoded);
  return Uint8List.fromList(img.encodePng(out));
}

/// Reduce la imagen (lado más largo = [maxDim]) para previsualización rápida.
/// Si ya es más pequeña, devuelve los bytes tal cual.
Uint8List downscalePngOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final maxDim = args['maxDim'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longest <= maxDim) return bytes;
  final out = decoded.width >= decoded.height
      ? img.copyResize(decoded, width: maxDim)
      : img.copyResize(decoded, height: maxDim);
  return Uint8List.fromList(img.encodePng(out));
}

/// Prepara una imagen para la segmentación (quitar fondo): la decodifica y la
/// vuelve a codificar como PNG limpio, reduciéndola si su lado más largo supera
/// `maxDim`. Esto evita fallos del modelo de ML Kit con imágenes demasiado
/// grandes o con bytes mal formados (causa típica de "Tensor received: 0").
Uint8List prepareForSegmentationOp(Map<String, dynamic> args) {
  final bytes = args['bytes'] as Uint8List;
  final maxDim = args['maxDim'] as int;
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return bytes;

  var out = decoded;
  final longest =
      decoded.width > decoded.height ? decoded.width : decoded.height;
  if (longest > maxDim) {
    out = decoded.width >= decoded.height
        ? img.copyResize(decoded, width: maxDim)
        : img.copyResize(decoded, height: maxDim);
  }
  return Uint8List.fromList(img.encodePng(out));
}

/// Estampa una imagen/logo como marca de agua sobre [base]. [scale] es el ancho
/// del logo como fracción (0..1) del ancho de la base, [opacity] su opacidad
/// (0..1) y [position] una de: topLeft, topRight, bottomLeft, bottomRight,
/// center.
Uint8List watermarkLogoOp(Map<String, dynamic> args) {
  final baseBytes = args['base'] as Uint8List;
  final logoBytes = args['logo'] as Uint8List;
  final position = args['position'] as String;
  final scale = (args['scale'] as num).toDouble();
  final opacity = (args['opacity'] as num).toDouble();

  final base = img.decodeImage(baseBytes);
  final logoSrc = img.decodeImage(logoBytes);
  if (base == null || logoSrc == null) return baseBytes;

  final targetW = (base.width * scale).round().clamp(1, base.width);
  var logo = img.copyResize(logoSrc, width: targetW);
  logo = logo.convert(numChannels: 4); // asegurar canal alfa
  if (opacity < 1.0) {
    for (final p in logo) {
      p.a = (p.a * opacity).round();
    }
  }

  const margin = 16;
  final maxX = base.width - logo.width - margin;
  final maxY = base.height - logo.height - margin;
  final (x, y) = switch (position) {
    'topLeft' => (margin, margin),
    'topRight' => (maxX, margin),
    'bottomLeft' => (margin, maxY),
    'center' => ((base.width - logo.width) ~/ 2, (base.height - logo.height) ~/ 2),
    _ => (maxX, maxY), // bottomRight
  };

  img.compositeImage(base, logo, dstX: x, dstY: y);
  return Uint8List.fromList(img.encodePng(base));
}

/// Une varias imágenes en una sola "imagen larga". Si [vertical] es true las
/// apila de arriba a abajo (igualando el ancho); si no, en fila (igualando el
/// alto). Útil para juntar capturas de pantalla.
Uint8List stitchImagesOp(Map<String, dynamic> args) {
  final frames = (args['frames'] as List).cast<Uint8List>();
  final vertical = args['vertical'] as bool;
  final decoded = <img.Image>[];
  for (final b in frames) {
    final d = img.decodeImage(b);
    if (d != null) decoded.add(d);
  }
  if (decoded.isEmpty) return Uint8List(0);

  if (vertical) {
    final w = decoded.map((e) => e.width).reduce(max);
    final resized = decoded
        .map((e) => e.width == w ? e : img.copyResize(e, width: w))
        .toList();
    final h = resized.fold<int>(0, (s, e) => s + e.height);
    final canvas = img.Image(width: w, height: h);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    var y = 0;
    for (final e in resized) {
      img.compositeImage(canvas, e, dstX: 0, dstY: y);
      y += e.height;
    }
    return Uint8List.fromList(img.encodePng(canvas));
  } else {
    final h = decoded.map((e) => e.height).reduce(max);
    final resized = decoded
        .map((e) => e.height == h ? e : img.copyResize(e, height: h))
        .toList();
    final w = resized.fold<int>(0, (s, e) => s + e.width);
    final canvas = img.Image(width: w, height: h);
    img.fill(canvas, color: img.ColorRgb8(255, 255, 255));
    var x = 0;
    for (final e in resized) {
      img.compositeImage(canvas, e, dstX: x, dstY: 0);
      x += e.width;
    }
    return Uint8List.fromList(img.encodePng(canvas));
  }
}

/// Compone un collage en cuadrícula: celdas cuadradas de [cellSize] px,
/// [cols] columnas, separadas (y rodeadas) por [spacing] px. El fondo [bg]
/// admite: white, black, transparent.
Uint8List collageOp(Map<String, dynamic> args) {
  final frames = (args['frames'] as List).cast<Uint8List>();
  final cols = args['cols'] as int;
  final cellSize = args['cellSize'] as int;
  final spacing = args['spacing'] as int;
  final bg = args['bg'] as String;

  final decoded = <img.Image>[];
  for (final b in frames) {
    final d = img.decodeImage(b);
    if (d != null) decoded.add(d);
  }
  if (decoded.isEmpty) return Uint8List(0);

  final resized = decoded
      .map((i) => img.copyResize(i, width: cellSize, height: cellSize))
      .toList();
  final rows = (resized.length / cols).ceil();
  final canvas = img.Image(
    width: cellSize * cols + spacing * (cols + 1),
    height: cellSize * rows + spacing * (rows + 1),
    numChannels: 4,
  );
  final color = switch (bg) {
    'black' => img.ColorRgba8(0, 0, 0, 255),
    'transparent' => img.ColorRgba8(0, 0, 0, 0),
    _ => img.ColorRgba8(255, 255, 255, 255),
  };
  img.fill(canvas, color: color);

  for (var i = 0; i < resized.length; i++) {
    final x = spacing + (i % cols) * (cellSize + spacing);
    final y = spacing + (i ~/ cols) * (cellSize + spacing);
    img.compositeImage(canvas, resized[i], dstX: x, dstY: y);
  }
  return Uint8List.fromList(img.encodePng(canvas));
}

/// Devuelve las dimensiones [width, height] de la imagen sin modificarla.
List<int> imageDimensionsOp(Uint8List bytes) {
  final decoded = img.decodeImage(bytes);
  if (decoded == null) return [0, 0];
  return [decoded.width, decoded.height];
}

/// Crea un GIF animado a partir de varias imágenes. Todos los cuadros se
/// reescalan a `maxWidth` (manteniendo la proporción del primero) porque un GIF
/// exige que todos los cuadros tengan el mismo tamaño. `delayMs` es el tiempo
/// que se muestra cada cuadro, en milisegundos.
Uint8List gifFromImagesOp(Map<String, dynamic> args) {
  final frames = (args['frames'] as List).cast<Uint8List>();
  final delayMs = args['delayMs'] as int;
  final maxWidth = args['maxWidth'] as int;
  if (frames.isEmpty) return Uint8List(0);

  img.Image? animation;
  int? w, h;
  for (final bytes in frames) {
    var frame = img.decodeImage(bytes);
    if (frame == null) continue;
    if (w == null) {
      w = maxWidth;
      h = (frame.height * maxWidth / frame.width).round();
    }
    frame = img.copyResize(frame, width: w, height: h);
    frame.frameDuration = delayMs;
    if (animation == null) {
      animation = frame;
    } else {
      animation.addFrame(frame);
    }
  }
  if (animation == null) return Uint8List(0);
  return Uint8List.fromList(img.encodeGif(animation));
}
