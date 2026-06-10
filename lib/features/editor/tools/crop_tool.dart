import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_cropper/image_cropper.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_utils.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Recortar: abre el recortador nativo (uCrop) sobre la imagen actual.
class CropToolPanel extends ConsumerWidget {
  const CropToolPanel({super.key});

  Future<void> _crop(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    // El recortador trabaja sobre un archivo, así que volcamos los bytes a temp.
    final tempFile = await ImageUtils.saveTempFile(bytes, 'png');

    final cropped = await ImageCropper().cropImage(
      sourcePath: tempFile.path,
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Recortar',
          toolbarColor: AppColors.bgPrimary,
          toolbarWidgetColor: AppColors.textPrimary,
          backgroundColor: AppColors.bgPrimary,
          activeControlsWidgetColor: AppColors.accent,
          cropFrameColor: AppColors.accent,
          cropGridColor: AppColors.border,
          statusBarLight: false,
          initAspectRatio: CropAspectRatioPreset.original,
          lockAspectRatio: false,
        ),
      ],
    );

    if (cropped == null) {
      notifier.setProcessing(false);
      return;
    }

    final result = await File(cropped.path).readAsBytes();
    notifier.setProcessing(false);
    notifier.applyEdit('Recortado', result);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Recortar',
      icon: Icons.crop,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isProcessing ? null : () => _crop(context, ref),
          icon: const Icon(Icons.crop),
          label: const Text('Abrir recortador'),
        ),
      ),
    );
  }
}
