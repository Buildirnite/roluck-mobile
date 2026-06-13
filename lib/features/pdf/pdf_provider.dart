import 'dart:io';
import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

enum PageOrientation { auto, portrait, landscape }
enum PageSize { a4, letter }

class PdfState {
  final List<File> images;
  final PageOrientation orientation;
  final PageSize pageSize;
  final String fileName;
  final bool isGenerating;
  final File? resultFile;
  // Páginas del PDF generado rasterizadas a PNG, para la vista previa.
  final List<Uint8List> previews;

  const PdfState({
    this.images = const [],
    this.orientation = PageOrientation.auto,
    this.pageSize = PageSize.a4,
    this.fileName = 'RoLuck_documento',
    this.isGenerating = false,
    this.resultFile,
    this.previews = const [],
  });

  PdfState copyWith({
    List<File>? images,
    PageOrientation? orientation,
    PageSize? pageSize,
    String? fileName,
    bool? isGenerating,
    File? resultFile,
    List<Uint8List>? previews,
  }) {
    return PdfState(
      images: images ?? this.images,
      orientation: orientation ?? this.orientation,
      pageSize: pageSize ?? this.pageSize,
      fileName: fileName ?? this.fileName,
      isGenerating: isGenerating ?? this.isGenerating,
      resultFile: resultFile ?? this.resultFile,
      previews: previews ?? this.previews,
    );
  }
}

class PdfNotifier extends StateNotifier<PdfState> {
  PdfNotifier() : super(const PdfState());

  void setImages(List<File> files) => state = state.copyWith(images: files);

  /// Agrega imágenes al final de la lista actual (no reemplaza).
  void addImages(List<File> files) =>
      state = state.copyWith(images: [...state.images, ...files]);

  void reorder(int oldIndex, int newIndex) {
    final list = List<File>.from(state.images);
    final item = list.removeAt(oldIndex);
    if (newIndex > oldIndex) newIndex--;
    list.insert(newIndex, item);
    state = state.copyWith(images: list);
  }

  void removeAt(int index) {
    final list = List<File>.from(state.images)..removeAt(index);
    state = state.copyWith(images: list);
  }

  void setOrientation(PageOrientation o) => state = state.copyWith(orientation: o);
  void setPageSize(PageSize s) => state = state.copyWith(pageSize: s);
  void setFileName(String name) => state = state.copyWith(fileName: name);

  PdfPageFormat _getPageFormat() {
    return state.pageSize == PageSize.a4
        ? PdfPageFormat.a4
        : PdfPageFormat.letter;
  }

  Future<void> generate() async {
    state = state.copyWith(isGenerating: true, previews: const []);

    try {
      final pdf = pw.Document();
      final format = _getPageFormat();

      for (final imgFile in state.images) {
        final bytes = await imgFile.readAsBytes();
        final image = pw.MemoryImage(bytes);

        pw.PageOrientation orient;
        switch (state.orientation) {
          case PageOrientation.portrait:
            orient = pw.PageOrientation.portrait;
            break;
          case PageOrientation.landscape:
            orient = pw.PageOrientation.landscape;
            break;
          case PageOrientation.auto:
            orient = pw.PageOrientation.natural;
            break;
        }

        pdf.addPage(
          pw.Page(
            pageFormat: format,
            orientation: orient,
            build: (context) => pw.Center(
              child: pw.Image(image, fit: pw.BoxFit.contain),
            ),
          ),
        );
      }

      final dir = await getTemporaryDirectory();
      final file = File(p.join(dir.path, '${state.fileName}.pdf'));
      final pdfBytes = await pdf.save();
      await file.writeAsBytes(pdfBytes);

      // Rasterizamos las páginas (DPI bajo) para la vista previa.
      final previews = <Uint8List>[];
      try {
        await for (final page in Printing.raster(pdfBytes, dpi: 72)) {
          previews.add(await page.toPng());
        }
      } catch (_) {
        // Si la rasterización falla, seguimos sin vista previa.
      }

      state = state.copyWith(
        isGenerating: false,
        resultFile: file,
        previews: previews,
      );
    } catch (_) {
      state = state.copyWith(isGenerating: false);
    }
  }

  void clear() => state = const PdfState();
}

final pdfProvider = StateNotifierProvider<PdfNotifier, PdfState>(
  (ref) => PdfNotifier(),
);
