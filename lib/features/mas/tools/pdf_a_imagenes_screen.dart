import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:printing/printing.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/image_viewer.dart';

/// Convierte un PDF en imágenes: rasteriza cada página con `printing` y permite
/// guardarlas en la galería o compartirlas.
class PdfAImagenesScreen extends StatefulWidget {
  const PdfAImagenesScreen({super.key});

  @override
  State<PdfAImagenesScreen> createState() => _PdfAImagenesScreenState();
}

class _PdfAImagenesScreenState extends State<PdfAImagenesScreen> {
  String? _fileName;
  double _dpi = 150;
  Uint8List? _pdfBytes;
  bool _isProcessing = false;
  List<Uint8List> _pages = [];

  Future<void> _pickPdf() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
      withData: true,
    );
    if (result == null || result.files.single.bytes == null) return;
    setState(() {
      _fileName = result.files.single.name;
      _pdfBytes = result.files.single.bytes;
      _pages = [];
    });
    _render();
  }

  Future<void> _render() async {
    final bytes = _pdfBytes;
    if (bytes == null) return;
    setState(() {
      _isProcessing = true;
      _pages = [];
    });
    final pages = <Uint8List>[];
    try {
      await for (final page in Printing.raster(bytes, dpi: _dpi)) {
        pages.add(await page.toPng());
      }
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _pages = pages;
      _isProcessing = false;
    });
  }

  Future<void> _saveAll() async {
    final messenger = ScaffoldMessenger.of(context);
    var saved = 0;
    for (final page in _pages) {
      try {
        final file = await ImageUtils.saveTempFile(page, 'png');
        await ImageGallerySaverPlus.saveFile(file.path);
        saved++;
      } catch (_) {
        // Se omite la página que falló y se continúa con las demás.
      }
    }
    messenger.showSnackBar(SnackBar(
        content: Text(saved == _pages.length
            ? '$saved páginas guardadas en galería'
            : '$saved de ${_pages.length} páginas guardadas')));
  }

  Future<void> _shareAll() async {
    final files = <XFile>[];
    for (var i = 0; i < _pages.length; i++) {
      final file = await ImageUtils.saveTempFile(_pages[i], 'png');
      files.add(XFile(file.path));
    }
    await Share.shareXFiles(files);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('PDF a imágenes')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ElevatedButton.icon(
              onPressed: _isProcessing ? null : _pickPdf,
              icon: const Icon(Icons.picture_as_pdf),
              label: Text(_fileName ?? 'Seleccionar PDF'),
            ),
            if (_pdfBytes != null) ...[
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Calidad (DPI)',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('${_dpi.round()} DPI',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace')),
                ],
              ),
              Slider(
                value: _dpi,
                min: 72,
                max: 300,
                divisions: 19,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.bgElevated,
                label: '${_dpi.round()}',
                onChanged: _isProcessing
                    ? null
                    : (v) => setState(() => _dpi = v),
                onChangeEnd: (_) => _render(),
              ),
            ],
            if (_isProcessing) ...[
              const SizedBox(height: 24),
              const Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            ],
            if (_pages.isNotEmpty && !_isProcessing) ...[
              const SizedBox(height: 16),
              Text('${_pages.length} página(s) · toca para ampliar',
                  style:
                      const TextStyle(color: AppColors.textMuted, fontSize: 12)),
              const SizedBox(height: 8),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate:
                    const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  mainAxisSpacing: 8,
                  crossAxisSpacing: 8,
                  childAspectRatio: 0.75,
                ),
                itemCount: _pages.length,
                itemBuilder: (context, i) => GestureDetector(
                  onTap: () => FullScreenImageViewer.open(
                      context, MemoryImage(_pages[i])),
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(color: AppColors.border),
                      borderRadius: BorderRadius.circular(4),
                    ),
                    clipBehavior: Clip.antiAlias,
                    child: Image.memory(_pages[i], fit: BoxFit.contain),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _saveAll,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar todas'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _shareAll,
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
