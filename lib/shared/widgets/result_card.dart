import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_avif/flutter_avif.dart';
import 'package:share_plus/share_plus.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/image_utils.dart';
import 'image_viewer.dart';

class ResultCard extends StatelessWidget {
  final File file;
  final int originalSize;
  final int resultSize;

  const ResultCard({
    super.key,
    required this.file,
    required this.originalSize,
    required this.resultSize,
  });

  @override
  Widget build(BuildContext context) {
    final savings = ImageUtils.calculateSavings(originalSize, resultSize);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Flutter no decodifica AVIF de forma nativa: para .avif usamos el
          // widget AvifImage de flutter_avif; el resto va por ImageProvider.
          if (file.path.toLowerCase().endsWith('.avif'))
            GestureDetector(
              onTap: () => FullScreenImageViewer.openWidget(
                context,
                AvifImage.file(file, fit: BoxFit.contain),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Stack(
                  children: [
                    AvifImage.file(
                      file,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                    Positioned(
                      right: 8,
                      bottom: 8,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: Colors.black54,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.zoom_in,
                            color: Colors.white, size: 18),
                      ),
                    ),
                  ],
                ),
              ),
            )
          else
            ZoomableImage(
              image: FileImage(file),
              height: 200,
              width: double.infinity,
              borderRadius: BorderRadius.circular(8),
            ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Original: ${ImageUtils.formatFileSize(originalSize)}',
                style: const TextStyle(color: AppColors.textMuted, fontFamily: 'monospace'),
              ),
              Text(
                'Resultado: ${ImageUtils.formatFileSize(resultSize)}',
                style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace'),
              ),
            ],
          ),
          if (savings > 0) ...[
            const SizedBox(height: 4),
            Text(
              '${savings.toStringAsFixed(1)}% más liviano',
              style: const TextStyle(color: AppColors.success, fontFamily: 'monospace'),
            ),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () async {
                    await ImageGallerySaverPlus.saveFile(file.path);
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guardado en galería')),
                      );
                    }
                  },
                  icon: const Icon(Icons.save_alt),
                  label: const Text('Guardar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Share.shareXFiles([XFile(file.path)]);
                  },
                  icon: const Icon(Icons.share),
                  label: const Text('Compartir'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.accent,
                    side: const BorderSide(color: AppColors.accent),
                    minimumSize: const Size.fromHeight(52),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
