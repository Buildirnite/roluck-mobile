import 'dart:io';
import 'package:flutter/material.dart';
import 'package:exif/exif.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_picker_zone.dart';
import '../../../shared/widgets/metadata_card.dart';

class ExifScreen extends StatefulWidget {
  const ExifScreen({super.key});

  @override
  State<ExifScreen> createState() => _ExifScreenState();
}

class _ExifScreenState extends State<ExifScreen> {
  File? _image;
  Map<String, IfdTag>? _exifData;
  bool _isLoading = false;

  Future<void> _loadExif(File file) async {
    setState(() {
      _image = file;
      _isLoading = true;
    });

    final bytes = await file.readAsBytes();
    final data = await readExifFromBytes(bytes);

    setState(() {
      _exifData = data;
      _isLoading = false;
    });
  }

  String _exifAsText() {
    final data = _exifData;
    if (data == null || data.isEmpty) return '';
    return data.entries.map((e) => '${e.key}: ${e.value}').join('\n');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Visor EXIF')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null)
              ImagePickerZone(onImageSelected: _loadExif)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 150, fit: BoxFit.cover),
              ),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => setState(() {
                          _image = null;
                          _exifData = null;
                        }),
                child: const Text('Otra imagen',
                    style: TextStyle(color: AppColors.accent)),
              ),
              const SizedBox(height: 4),
              if (_isLoading)
                const Center(child: CircularProgressIndicator(color: AppColors.accent))
              else if (_exifData != null) ...[
                if (_exifData!.isEmpty)
                  const Text('No se encontraron datos EXIF',
                      style: TextStyle(color: AppColors.textMuted))
                else ...[
                  ..._exifData!.entries.map(
                    (e) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: MetadataCard(label: e.key, value: e.value.toString()),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => SaveShare.downloadText(
                            context,
                            text: _exifAsText(),
                            fileName: 'exif.txt',
                          ),
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Descargar'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => SaveShare.shareText(_exifAsText()),
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
