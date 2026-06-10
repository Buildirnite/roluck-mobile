import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../core/constants/colors.dart';
import '../../core/utils/image_utils.dart';
import '../../core/utils/save_share.dart';
import '../../shared/widgets/image_picker_zone.dart';
import '../../shared/widgets/image_viewer.dart';
import 'editor_provider.dart';
import 'widgets/tool_palette.dart';
import 'tools/adjust_tool.dart';
import 'tools/efectos_tool.dart';
import 'tools/marco_tool.dart';
import 'tools/rotate_tool.dart';
import 'tools/flip_tool.dart';
import 'tools/filter_tool.dart';
import 'tools/resize_tool.dart';
import 'tools/blur_tool.dart';
import 'tools/compress_tool.dart';
import 'tools/watermark_tool.dart';
import 'tools/crop_tool.dart';
import 'tools/annotate_tool.dart';
import 'tools/bg_remover_tool.dart';

class EditorScreen extends ConsumerWidget {
  const EditorScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(editorProvider);
    final notifier = ref.read(editorProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editor'),
        actions: [
          if (state.canUndo)
            IconButton(
              onPressed: () => notifier.undo(),
              icon: const Icon(Icons.undo),
              tooltip: 'Deshacer',
            ),
          if (state.canRedo)
            IconButton(
              onPressed: () => notifier.redo(),
              icon: const Icon(Icons.redo),
              tooltip: 'Rehacer',
            ),
          if (state.steps.isNotEmpty)
            IconButton(
              onPressed: () => notifier.resetToOriginal(),
              icon: const Icon(Icons.restart_alt),
              tooltip: 'Revertir al original',
            ),
          if (state.currentBytes != null) ...[
            IconButton(
              onPressed: () async {
                final messenger = ScaffoldMessenger.of(context);
                final file =
                    await ImageUtils.saveTempFile(state.currentBytes!, 'png');
                await ImageGallerySaverPlus.saveFile(file.path);
                messenger.showSnackBar(
                  const SnackBar(content: Text('Guardado en galería')),
                );
              },
              icon: const Icon(Icons.save_alt),
              tooltip: 'Guardar',
            ),
            IconButton(
              onPressed: () => SaveShare.shareBytes(
                bytes: state.currentBytes!,
                fileName: 'roluck_editado.png',
              ),
              icon: const Icon(Icons.share),
              tooltip: 'Compartir',
            ),
          ],
        ],
      ),
      body: state.inputFile == null
          ? Padding(
              padding: const EdgeInsets.all(16),
              child: ImagePickerZone(
                onImageSelected: (file) => notifier.setInput(file),
              ),
            )
          : Column(
              children: [
                // Preview
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        if (state.displayBytes != null)
                          GestureDetector(
                            onTap: () => FullScreenImageViewer.open(
                              context,
                              MemoryImage(state.displayBytes!),
                            ),
                            // Mantener pulsado compara con el original.
                            onLongPressStart: state.canCompare
                                ? (_) => notifier.setComparing(true)
                                : null,
                            onLongPressEnd: state.canCompare
                                ? (_) => notifier.setComparing(false)
                                : null,
                            child: Image.memory(
                              state.displayBytes!,
                              fit: BoxFit.contain,
                              gaplessPlayback: true,
                            ),
                          )
                        else
                          const Center(
                              child: CircularProgressIndicator(
                                  color: AppColors.accent)),
                        if (state.isProcessing)
                          Container(
                            color: Colors.black54,
                            child: const Center(
                                child: CircularProgressIndicator(
                                    color: AppColors.accent)),
                          ),
                        if (state.currentBytes != null && !state.isProcessing)
                          Positioned(
                            right: 8,
                            bottom: 8,
                            child: IgnorePointer(
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
                          ),
                        // Indicador al comparar con el original.
                        if (state.comparing)
                          Positioned(
                            left: 8,
                            top: 8,
                            child: IgnorePointer(
                              child: Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.accent,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: const Text('ORIGINAL',
                                    style: TextStyle(
                                        color: Colors.black,
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold)),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Historial de ediciones: una sola fila con scroll horizontal.
                // Cada chip se puede tocar para saltar a ese punto (adelante /
                // atrás) y tiene una ✕ para quitar ese paso. Los pasos deshechos
                // se ven atenuados (disponibles para rehacer).
                if (state.steps.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 4, 8, 0),
                    child: Row(
                      children: [
                        // Posición actual / total de pasos.
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: AppColors.accent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${state.cursor}/${state.steps.length}',
                            style: const TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: SizedBox(
                            height: 34,
                            child: ListView.separated(
                              scrollDirection: Axis.horizontal,
                              padding: const EdgeInsets.only(right: 8),
                              itemCount: state.steps.length,
                              separatorBuilder: (_, _) =>
                                  const SizedBox(width: 6),
                              itemBuilder: (context, i) {
                                final step = state.steps[i];
                                final active = i < state.cursor;
                                return GestureDetector(
                                  onTap: () => notifier.jumpTo(i + 1),
                                  child: Container(
                                    padding: const EdgeInsets.only(left: 12),
                                    decoration: BoxDecoration(
                                      color: active
                                          ? AppColors.accentDim
                                          : Colors.transparent,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(
                                        color: active
                                            ? AppColors.accent
                                            : AppColors.border,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          step.name,
                                          style: TextStyle(
                                            color: active
                                                ? AppColors.textPrimary
                                                : AppColors.textMuted,
                                            fontSize: 11,
                                          ),
                                        ),
                                        InkWell(
                                          onTap: () => notifier.removeStep(i),
                                          customBorder: const CircleBorder(),
                                          child: Padding(
                                            padding: const EdgeInsets.all(5),
                                            child: Icon(
                                              Icons.close,
                                              size: 14,
                                              color: active
                                                  ? AppColors.textPrimary
                                                  : AppColors.textMuted,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Paleta de herramientas
                const ToolPalette(),
                const SizedBox(height: 8),
                // Panel de la herramienta activa (con scroll y altura acotada
                // para que el teclado no provoque overflow en los paneles altos)
                if (state.activeTool != null)
                  ConstrainedBox(
                    constraints: BoxConstraints(
                      maxHeight: MediaQuery.of(context).size.height * 0.45,
                    ),
                    child: SingleChildScrollView(
                      child: _buildToolPanel(state.activeTool!),
                    ),
                  ),
              ],
            ),
    );
  }

  Widget _buildToolPanel(EditorTool tool) {
    switch (tool) {
      case EditorTool.crop:
        return const CropToolPanel();
      case EditorTool.removeBg:
        return const BgRemoverToolPanel();
      case EditorTool.rotate:
        return const RotateToolPanel();
      case EditorTool.flip:
        return const FlipToolPanel();
      case EditorTool.filters:
        return const FilterToolPanel();
      case EditorTool.adjust:
        return const AdjustToolPanel();
      case EditorTool.effects:
        return const EfectosToolPanel();
      case EditorTool.frame:
        return const MarcoToolPanel();
      case EditorTool.resize:
        return const ResizeToolPanel();
      case EditorTool.watermark:
        return const WatermarkToolPanel();
      case EditorTool.blur:
        return const BlurToolPanel();
      case EditorTool.annotate:
        return const AnnotateToolPanel();
      case EditorTool.compress:
        return const CompressToolPanel();
    }
  }
}
