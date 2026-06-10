import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_mlkit_image_labeling/google_mlkit_image_labeling.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/image_picker_zone.dart';

/// Identifica qué hay en una imagen (etiquetas con confianza), on-device.
class EtiquetarScreen extends StatefulWidget {
  const EtiquetarScreen({super.key});

  @override
  State<EtiquetarScreen> createState() => _EtiquetarScreenState();
}

class _EtiquetarScreenState extends State<EtiquetarScreen> {
  File? _image;
  bool _isProcessing = false;
  List<ImageLabel> _labels = [];
  bool _done = false;

  Future<void> _process(File file) async {
    setState(() {
      _image = file;
      _isProcessing = true;
      _done = false;
    });
    final labeler =
        ImageLabeler(options: ImageLabelerOptions(confidenceThreshold: 0.5));
    try {
      final result = await labeler.processImage(InputImage.fromFile(file));
      setState(() => _labels = result);
    } catch (_) {
      setState(() => _labels = []);
    } finally {
      await labeler.close();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _done = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Etiquetar imagen')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null)
              ImagePickerZone(onImageSelected: _process)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () => setState(() {
                  _image = null;
                  _labels = [];
                  _done = false;
                }),
                child: const Text('Otra imagen',
                    style: TextStyle(color: AppColors.accent)),
              ),
              if (_isProcessing)
                const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
              else if (_done && _labels.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No se reconoció contenido',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              else
                ..._labels.map((l) => _LabelRow(label: l)),
              if (_labels.isNotEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 8),
                  child: Text('Las etiquetas las genera ML Kit (en inglés).',
                      style: TextStyle(
                          color: AppColors.textMuted, fontSize: 11)),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabelRow extends StatelessWidget {
  final ImageLabel label;
  const _LabelRow({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label.label,
                  style: const TextStyle(
                      color: AppColors.textPrimary, fontSize: 15)),
              Text('${(label.confidence * 100).round()}%',
                  style: const TextStyle(
                      color: AppColors.accent, fontFamily: 'monospace')),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: label.confidence,
              minHeight: 6,
              backgroundColor: AppColors.bgElevated,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
        ],
      ),
    );
  }
}
