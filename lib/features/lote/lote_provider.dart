import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:archive/archive_io.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;
import '../../core/utils/image_utils.dart';
import '../../core/utils/image_ops.dart';
import '../../shared/widgets/batch_list.dart';
import '../convertir/convertir_provider.dart';

class LoteState {
  final List<File> inputFiles;
  final OutputFormat format;
  final int quality;
  final double scale;
  final List<BatchItem> items;
  final bool isProcessing;
  final List<File> results;

  const LoteState({
    this.inputFiles = const [],
    this.format = OutputFormat.jpeg,
    this.quality = 85,
    this.scale = 1.0,
    this.items = const [],
    this.isProcessing = false,
    this.results = const [],
  });

  LoteState copyWith({
    List<File>? inputFiles,
    OutputFormat? format,
    int? quality,
    double? scale,
    List<BatchItem>? items,
    bool? isProcessing,
    List<File>? results,
  }) {
    return LoteState(
      inputFiles: inputFiles ?? this.inputFiles,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      scale: scale ?? this.scale,
      items: items ?? this.items,
      isProcessing: isProcessing ?? this.isProcessing,
      results: results ?? this.results,
    );
  }
}

class LoteNotifier extends StateNotifier<LoteState> {
  LoteNotifier() : super(const LoteState());

  void setFiles(List<File> files) {
    state = state.copyWith(
      inputFiles: files,
      items: files
          .map((f) => BatchItem(
                name: p.basename(f.path),
                status: BatchItemStatus.queued,
                path: f.path,
              ))
          .toList(),
    );
  }

  /// Añade imágenes a la selección actual (quedan en cola para procesar).
  void addFiles(List<File> files) {
    if (files.isEmpty) return;
    state = state.copyWith(
      inputFiles: [...state.inputFiles, ...files],
      items: [
        ...state.items,
        ...files.map((f) => BatchItem(
              name: p.basename(f.path),
              status: BatchItemStatus.queued,
              path: f.path,
            )),
      ],
    );
  }

  /// Quita una imagen (y su ítem de estado) de la lista.
  void removeAt(int index) {
    if (index < 0 || index >= state.inputFiles.length) return;
    state = state.copyWith(
      inputFiles: List<File>.from(state.inputFiles)..removeAt(index),
      items: List<BatchItem>.from(state.items)..removeAt(index),
    );
  }

  void setFormat(OutputFormat format) => state = state.copyWith(format: format);
  void setQuality(int quality) => state = state.copyWith(quality: quality);
  void setScale(double scale) => state = state.copyWith(scale: scale);

  CompressFormat _toCompressFormat(OutputFormat f) {
    switch (f) {
      case OutputFormat.jpeg:
        return CompressFormat.jpeg;
      case OutputFormat.png:
        return CompressFormat.png;
      case OutputFormat.webp:
      case OutputFormat.avif:
        return CompressFormat.webp; // no usado para avif (ver _processOne)
    }
  }

  String _extFor(OutputFormat f) =>
      f == OutputFormat.jpeg ? 'jpg' : f.name;

  /// Convierte un archivo aplicando formato, calidad y escala. AVIF se procesa
  /// con flutter_avif; el resto con flutter_image_compress.
  Future<Uint8List?> _processOne(File input) async {
    final scale = state.scale;
    int? mw, mh;
    if (scale != 1.0) {
      final origBytes = await input.readAsBytes();
      final dims = await compute(imageDimensionsOp, origBytes);
      if (dims[0] > 0) {
        mw = (dims[0] * scale).round();
        mh = (dims[1] * scale).round();
      }
    }

    if (state.format == OutputFormat.avif) {
      var src = await input.readAsBytes();
      if (mw != null && mh != null) {
        src = await compute(resizeImageOp, {
          'bytes': src,
          'width': mw,
          'height': mh,
        });
      }
      return encodeAvif(src);
    }

    return ImageUtils.compressImage(
      inputPath: input.path,
      format: _toCompressFormat(state.format),
      quality: state.quality,
      minWidth: mw,
      minHeight: mh,
    );
  }

  Future<void> processAll() async {
    state = state.copyWith(isProcessing: true, results: []);

    final results = <File>[];
    final updatedItems = List<BatchItem>.from(state.items);

    // Procesar en serie (no en paralelo) para no saturar memoria.
    for (var i = 0; i < state.inputFiles.length; i++) {
      updatedItems[i] = BatchItem(
        name: updatedItems[i].name,
        status: BatchItemStatus.processing,
        path: updatedItems[i].path,
      );
      state = state.copyWith(items: List.from(updatedItems));

      try {
        final bytes = await _processOne(state.inputFiles[i]);

        if (bytes != null) {
          final file =
              await ImageUtils.saveTempFile(bytes, _extFor(state.format));
          results.add(file);
          updatedItems[i] = BatchItem(
            name: updatedItems[i].name,
            status: BatchItemStatus.done,
            path: updatedItems[i].path,
          );
        } else {
          updatedItems[i] = BatchItem(
            name: updatedItems[i].name,
            status: BatchItemStatus.error,
            errorMessage: 'Conversión falló',
            path: updatedItems[i].path,
          );
        }
      } catch (e) {
        updatedItems[i] = BatchItem(
          name: updatedItems[i].name,
          status: BatchItemStatus.error,
          errorMessage: e.toString(),
          path: updatedItems[i].path,
        );
      }
      state = state.copyWith(items: List.from(updatedItems));
    }

    state = state.copyWith(isProcessing: false, results: results);
  }

  /// Guarda todos los resultados en la galería del dispositivo. Devuelve
  /// cuántos se guardaron; los que fallen no interrumpen al resto.
  Future<int> saveAllToGallery() async {
    var saved = 0;
    for (final file in state.results) {
      try {
        await ImageGallerySaverPlus.saveFile(file.path);
        saved++;
      } catch (_) {
        // Se omite el archivo que falló y se continúa con los demás.
      }
    }
    return saved;
  }

  /// Empaqueta todos los resultados en un ZIP y devuelve el archivo.
  Future<File?> exportZip() async {
    if (state.results.isEmpty) return null;
    final dir = await getTemporaryDirectory();
    final zipPath = p.join(
        dir.path, 'RoLuck_lote_${DateTime.now().millisecondsSinceEpoch}.zip');

    final encoder = ZipFileEncoder();
    encoder.create(zipPath);
    for (final file in state.results) {
      await encoder.addFile(file, p.basename(file.path));
    }
    encoder.closeSync();
    return File(zipPath);
  }

  void clear() => state = const LoteState();
}

final loteProvider = StateNotifierProvider<LoteNotifier, LoteState>(
  (ref) => LoteNotifier(),
);
