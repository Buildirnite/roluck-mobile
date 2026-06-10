import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_picker_zone.dart';

class Base64Screen extends StatefulWidget {
  const Base64Screen({super.key});

  @override
  State<Base64Screen> createState() => _Base64ScreenState();
}

class _Base64ScreenState extends State<Base64Screen> {
  // Límite de caracteres a renderizar: un SelectableText con cientos de miles
  // de caracteres se queda en blanco / congela el render, así que mostramos solo
  // una vista previa. El contenido completo sigue disponible para copiar,
  // descargar y compartir.
  static const int _previewLimit = 5000;

  String? _base64;
  bool _isLoading = false;

  Future<void> _encode(File file) async {
    setState(() => _isLoading = true);
    final bytes = await file.readAsBytes();
    final encoded = base64Encode(bytes);
    setState(() {
      _base64 = encoded;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final base64 = _base64;
    final isTruncated = base64 != null && base64.length > _previewLimit;
    final preview =
        isTruncated ? '${base64.substring(0, _previewLimit)}…' : base64;

    return Scaffold(
      appBar: AppBar(title: const Text('Base64')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            ImagePickerZone(onImageSelected: _encode),
            const SizedBox(height: 16),
            if (_isLoading)
              const Center(
                  child: CircularProgressIndicator(color: AppColors.accent))
            else if (base64 != null) ...[
              Text(
                '${(base64.length / 1024).toStringAsFixed(1)} KB de texto · ${base64.length} caracteres',
                style: const TextStyle(
                    color: AppColors.textMuted, fontFamily: 'monospace'),
              ),
              const SizedBox(height: 12),
              Container(
                height: 220,
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.border),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    preview!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                      fontSize: 11,
                    ),
                  ),
                ),
              ),
              if (isTruncated) ...[
                const SizedBox(height: 6),
                Text(
                  'Vista previa de los primeros $_previewLimit caracteres. Usa Copiar, Descargar o Compartir para el contenido completo.',
                  style: const TextStyle(
                      color: AppColors.textMuted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: base64));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                              content: Text('Copiado al portapapeles')),
                        );
                      },
                      icon: const Icon(Icons.copy, size: 18),
                      label: const Text('Copiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => SaveShare.downloadText(
                        context,
                        text: base64,
                        fileName: 'base64.txt',
                      ),
                      icon: const Icon(Icons.download, size: 18),
                      label: const Text('Descargar'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => SaveShare.shareBytes(
                  bytes: Uint8List.fromList(utf8.encode(base64)),
                  fileName: 'base64.txt',
                ),
                icon: const Icon(Icons.share, size: 18),
                label: const Text('Compartir'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.accent,
                  side: const BorderSide(color: AppColors.accent),
                  minimumSize: const Size.fromHeight(48),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
