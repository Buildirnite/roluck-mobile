import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_subject_segmentation/google_mlkit_subject_segmentation.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Quitar fondo. Usa ML Kit Subject Segmentation (on-device) para
/// detectar el sujeto principal y devolver la imagen con el fondo transparente.
class BgRemoverToolPanel extends ConsumerWidget {
  const BgRemoverToolPanel({super.key});

  Future<void> _removeBackground(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    final messenger = ScaffoldMessenger.of(context);
    notifier.setProcessing(true);

    // Normalizamos la imagen (PNG limpio y acotado a 2048 px) para reducir la
    // probabilidad de que el modelo falle con fotos enormes o mal formadas.
    final prepared = await compute(prepareForSegmentationOp, {
      'bytes': bytes,
      'maxDim': 2048,
    });

    // El segmentador trabaja sobre un archivo; volcamos los bytes a temp.
    final tempFile = await ImageUtils.saveTempFile(prepared, 'png');
    final segmenter = SubjectSegmenter(
      options: SubjectSegmenterOptions(
        enableForegroundBitmap: true,
        enableForegroundConfidenceMask: false,
        enableMultipleSubjects: SubjectResultOptions(
          enableConfidenceMask: false,
          enableSubjectBitmap: false,
        ),
      ),
    );

    try {
      final inputImage = InputImage.fromFilePath(tempFile.path);
      final result = await segmenter.processImage(inputImage);
      final foreground = result.foregroundBitmap;

      if (foreground == null) {
        notifier.setProcessing(false);
        messenger.showSnackBar(
          const SnackBar(
              content: Text('No se detectó un sujeto para recortar')),
        );
        return;
      }

      notifier.setProcessing(false);
      notifier.applyEdit('Sin fondo', foreground, opKey: 'removeBg');
    } catch (e) {
      notifier.setProcessing(false);
      messenger.showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo quitar el fondo. La primera vez necesita conexión '
            'para descargar el modelo. ($e)',
          ),
        ),
      );
    } finally {
      await segmenter.close();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Quitar fondo',
      icon: Icons.auto_fix_high,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Detecta el sujeto principal y deja el fondo transparente. '
            'La primera vez descarga el modelo (necesita conexión una vez); '
            'después funciona sin conexión.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 13),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed:
                  isProcessing ? null : () => _removeBackground(context, ref),
              icon: const Icon(Icons.auto_fix_high),
              label: const Text('Quitar fondo'),
            ),
          ),
        ],
      ),
    );
  }
}
