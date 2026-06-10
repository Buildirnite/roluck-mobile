import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:exif/exif.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/image_picker_zone.dart';
import '../../../shared/widgets/result_card.dart';

/// Quita los metadatos (EXIF: GPS, modelo de cámara, fecha, etc.) re-codificando
/// la imagen. flutter_image_compress no conserva EXIF por defecto, así que el
/// resultado queda limpio.
class LimpiarExifScreen extends StatefulWidget {
  const LimpiarExifScreen({super.key});

  @override
  State<LimpiarExifScreen> createState() => _LimpiarExifScreenState();
}

class _LimpiarExifScreenState extends State<LimpiarExifScreen> {
  File? _image;
  int _originalSize = 0;
  int _exifCountBefore = 0;
  bool _isProcessing = false;
  File? _result;
  int _resultSize = 0;
  int _exifCountAfter = 0;

  Future<void> _onPick(File file) async {
    final bytes = await file.readAsBytes();
    final exif = await readExifFromBytes(bytes);
    setState(() {
      _image = file;
      _originalSize = bytes.length;
      _exifCountBefore = exif.length;
      _result = null;
    });
  }

  Future<void> _clean() async {
    final image = _image;
    if (image == null) return;
    setState(() => _isProcessing = true);

    final isPng = image.path.toLowerCase().endsWith('.png');
    final cleaned = await ImageUtils.compressImage(
      inputPath: image.path,
      format: isPng ? CompressFormat.png : CompressFormat.jpeg,
      quality: 95,
    );
    if (cleaned == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final exifAfter = await readExifFromBytes(cleaned);
    final file = await ImageUtils.saveTempFile(cleaned, isPng ? 'png' : 'jpg');
    setState(() {
      _result = file;
      _resultSize = cleaned.length;
      _exifCountAfter = exifAfter.length;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Limpiar metadatos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null)
              ImagePickerZone(onImageSelected: _onPick)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 180, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    Icon(
                      _exifCountBefore > 0 ? Icons.warning_amber : Icons.check_circle,
                      color: _exifCountBefore > 0
                          ? AppColors.error
                          : AppColors.success,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _exifCountBefore > 0
                            ? 'La imagen tiene $_exifCountBefore campos de metadatos (posible GPS, cámara, fecha).'
                            : 'La imagen no tiene metadatos EXIF.',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 13),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _isProcessing ? null : _clean,
                icon: const Icon(Icons.cleaning_services),
                label: _isProcessing
                    ? const Text('Limpiando…')
                    : const Text('Limpiar metadatos'),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _image = null;
                  _result = null;
                }),
                child: const Text('Cambiar imagen',
                    style: TextStyle(color: AppColors.accent)),
              ),
              if (_result != null) ...[
                const SizedBox(height: 8),
                Text(
                  _exifCountAfter == 0
                      ? '✓ Metadatos eliminados ($_exifCountBefore → 0)'
                      : 'Quedan $_exifCountAfter campos',
                  style: const TextStyle(color: AppColors.success, fontSize: 13),
                ),
                const SizedBox(height: 8),
                ResultCard(
                  file: _result!,
                  originalSize: _originalSize,
                  resultSize: _resultSize,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
