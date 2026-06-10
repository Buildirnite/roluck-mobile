import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_utils.dart';
import '../../../shared/widgets/image_picker_zone.dart';
import '../../../shared/widgets/result_card.dart';

/// Comprime una imagen para que pese como máximo un tamaño objetivo, buscando
/// automáticamente la mayor calidad posible (búsqueda binaria sobre la calidad).
class ComprimirScreen extends StatefulWidget {
  const ComprimirScreen({super.key});

  @override
  State<ComprimirScreen> createState() => _ComprimirScreenState();
}

class _ComprimirScreenState extends State<ComprimirScreen> {
  File? _image;
  int _originalSize = 0;
  double _targetKb = 500;
  bool _isProcessing = false;
  File? _result;
  int _resultSize = 0;
  bool _reachedTarget = true;

  Future<void> _onPick(File file) async {
    final size = await file.length();
    setState(() {
      _image = file;
      _originalSize = size;
      _result = null;
      // Objetivo por defecto: la mitad del tamaño original (acotado).
      _targetKb = (size / 1024 / 2).clamp(50, 5000).roundToDouble();
    });
  }

  Future<void> _compress() async {
    final image = _image;
    if (image == null) return;
    setState(() => _isProcessing = true);

    final targetBytes = (_targetKb * 1024).round();
    int lo = 1, hi = 100;
    Uint8List? best;

    // Buscamos la mayor calidad cuyo resultado quepa en el objetivo.
    for (var i = 0; i < 8 && lo <= hi; i++) {
      final q = ((lo + hi) / 2).round();
      final bytes = await ImageUtils.compressImage(
        inputPath: image.path,
        format: CompressFormat.jpeg,
        quality: q,
      );
      if (bytes == null) break;
      if (bytes.length <= targetBytes) {
        best = bytes;
        lo = q + 1;
      } else {
        hi = q - 1;
      }
    }

    var reached = best != null;
    // Si ni con calidad mínima se alcanza, devolvemos lo más pequeño posible.
    best ??= await ImageUtils.compressImage(
      inputPath: image.path,
      format: CompressFormat.jpeg,
      quality: 1,
    );

    if (best == null) {
      setState(() => _isProcessing = false);
      return;
    }

    final file = await ImageUtils.saveTempFile(best, 'jpg');
    setState(() {
      _result = file;
      _resultSize = best!.length;
      _reachedTarget = reached;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Comprimir a tamaño')),
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
              const SizedBox(height: 8),
              Text('Original: ${ImageUtils.formatFileSize(_originalSize)}',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontFamily: 'monospace')),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tamaño objetivo',
                      style:
                          TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('${_targetKb.round()} KB',
                      style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontFamily: 'monospace')),
                ],
              ),
              Slider(
                value: _targetKb,
                min: 50,
                max: (_originalSize / 1024).clamp(100, 10000).toDouble(),
                divisions: 100,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.bgElevated,
                label: '${_targetKb.round()} KB',
                onChanged: _isProcessing
                    ? null
                    : (v) => setState(() => _targetKb = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _compress,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Comprimir'),
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
                if (!_reachedTarget)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      'No se pudo bajar tanto sin perder demasiada calidad; '
                      'este es el menor tamaño posible para esta imagen.',
                      style: TextStyle(
                          color: AppColors.error.withValues(alpha: 0.9),
                          fontSize: 12),
                    ),
                  ),
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
