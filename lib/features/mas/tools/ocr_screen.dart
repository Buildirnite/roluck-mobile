import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_picker_zone.dart';

class OcrScreen extends StatefulWidget {
  const OcrScreen({super.key});

  @override
  State<OcrScreen> createState() => _OcrScreenState();
}

class _OcrScreenState extends State<OcrScreen> {
  File? _image;
  String? _extractedText;
  bool _isProcessing = false;

  Future<void> _processImage(File file) async {
    setState(() {
      _image = file;
      _isProcessing = true;
      _extractedText = null;
    });

    final recognizer = TextRecognizer();
    final inputImage = InputImage.fromFile(file);
    final result = await recognizer.processImage(inputImage);
    await recognizer.close();

    setState(() {
      _extractedText = result.text;
      _isProcessing = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('OCR')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null)
              ImagePickerZone(onImageSelected: _processImage)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 16),
              if (_isProcessing)
                const Center(child: CircularProgressIndicator(color: AppColors.accent))
              else if (_extractedText != null) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Texto extraído',
                        style: TextStyle(color: AppColors.textMuted)),
                    IconButton(
                      onPressed: () {
                        Clipboard.setData(ClipboardData(text: _extractedText!));
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Copiado al portapapeles')),
                        );
                      },
                      icon: const Icon(Icons.copy, color: AppColors.accent),
                    ),
                  ],
                ),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: AppColors.border),
                  ),
                  child: SelectableText(
                    _extractedText!.isEmpty ? 'No se detectó texto' : _extractedText!,
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
                ),
                if (_extractedText!.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => SaveShare.downloadText(
                            context,
                            text: _extractedText!,
                            fileName: 'texto.txt',
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Descargar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => SaveShare.shareText(_extractedText!),
                          icon: const Icon(Icons.share, size: 18),
                          label: const Text('Compartir'),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ],
        ),
      ),
    );
  }
}
