import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:flutter_avif/flutter_avif.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/image_ops.dart';

enum OutputFormat { jpeg, png, webp, avif }

class ConvertirState {
  final File? inputFile;
  final OutputFormat format;
  final int quality;
  final double scale; // 1.0 = tamaño original
  final bool isConverting;
  final File? resultFile;
  final int? originalSize;
  final int? resultSize;
  // Mensaje de error de la última conversión (null si fue bien).
  final String? error;

  const ConvertirState({
    this.inputFile,
    this.format = OutputFormat.jpeg,
    this.quality = 85,
    this.scale = 1.0,
    this.isConverting = false,
    this.resultFile,
    this.originalSize,
    this.resultSize,
    this.error,
  });

  ConvertirState copyWith({
    File? inputFile,
    OutputFormat? format,
    int? quality,
    double? scale,
    bool? isConverting,
    File? resultFile,
    int? originalSize,
    int? resultSize,
    String? error,
    bool clearError = false,
  }) {
    return ConvertirState(
      inputFile: inputFile ?? this.inputFile,
      format: format ?? this.format,
      quality: quality ?? this.quality,
      scale: scale ?? this.scale,
      isConverting: isConverting ?? this.isConverting,
      resultFile: resultFile ?? this.resultFile,
      originalSize: originalSize ?? this.originalSize,
      resultSize: resultSize ?? this.resultSize,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class ConvertirNotifier extends StateNotifier<ConvertirState> {
  ConvertirNotifier() : super(const ConvertirState());

  Future<void> setInput(File file) async {
    final size = await file.length();
    state = ConvertirState(inputFile: file, originalSize: size);
  }

  void setFormat(OutputFormat format) => state = state.copyWith(format: format);
  void setQuality(int quality) => state = state.copyWith(quality: quality);
  void setScale(double scale) => state = state.copyWith(scale: scale);

  Future<void> convert() async {
    if (state.inputFile == null) return;
    state = state.copyWith(isConverting: true, clearError: true);

    try {
      final input = state.inputFile!;
      final scale = state.scale;

      // Si hay reducción de escala, calculamos las dimensiones destino para
      // pasarlas como caja de tamaño (o redimensionar antes de AVIF).
      int? mw, mh;
      if (scale != 1.0) {
        final dims = await compute(imageDimensionsOp, await input.readAsBytes());
        if (dims[0] > 0) {
          mw = (dims[0] * scale).round();
          mh = (dims[1] * scale).round();
        }
      }

      Uint8List? bytes;
      String ext;

      switch (state.format) {
        case OutputFormat.jpeg:
          bytes = await ImageUtils.compressImage(
            inputPath: input.path,
            format: CompressFormat.jpeg,
            quality: state.quality,
            minWidth: mw,
            minHeight: mh,
          );
          ext = 'jpg';
        case OutputFormat.png:
          bytes = await ImageUtils.compressImage(
            inputPath: input.path,
            format: CompressFormat.png,
            minWidth: mw,
            minHeight: mh,
          );
          ext = 'png';
        case OutputFormat.webp:
          bytes = await ImageUtils.compressImage(
            inputPath: input.path,
            format: CompressFormat.webp,
            quality: state.quality,
            minWidth: mw,
            minHeight: mh,
          );
          ext = 'webp';
        case OutputFormat.avif:
          // Conversión real a AVIF con flutter_avif (libavif, on-device).
          var src = await input.readAsBytes();
          if (mw != null && mh != null) {
            src = await compute(resizeImageOp, {
              'bytes': src,
              'width': mw,
              'height': mh,
            });
          }
          bytes = await encodeAvif(src);
          ext = 'avif';
      }

      if (bytes != null) {
        final resultFile = await ImageUtils.saveTempFile(bytes, ext);
        state = state.copyWith(
          isConverting: false,
          resultFile: resultFile,
          resultSize: bytes.length,
        );
      } else {
        state = state.copyWith(
          isConverting: false,
          error: 'No se pudo convertir la imagen. Prueba con otro formato.',
        );
      }
    } catch (_) {
      state = state.copyWith(
        isConverting: false,
        error: 'No se pudo convertir la imagen. Prueba con otro formato.',
      );
    }
  }
}

final convertirProvider =
    StateNotifierProvider<ConvertirNotifier, ConvertirState>(
  (ref) => ConvertirNotifier(),
);
