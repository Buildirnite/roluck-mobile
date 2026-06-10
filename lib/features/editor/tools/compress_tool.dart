import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Compresión: recodifica la imagen como JPEG con la calidad elegida
/// para reducir el tamaño del archivo.
class CompressToolPanel extends ConsumerStatefulWidget {
  const CompressToolPanel({super.key});

  @override
  ConsumerState<CompressToolPanel> createState() => _CompressToolPanelState();
}

class _CompressToolPanelState extends ConsumerState<CompressToolPanel> {
  double _quality = 80;

  Future<void> _apply() async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(compressImageOp, {
      'bytes': bytes,
      'quality': _quality.round(),
    });
    notifier.setProcessing(false);
    notifier.applyEdit(
      'JPEG ${_quality.round()}% · ${ImageUtils.formatFileSize(result.length)}',
      result,
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(editorProvider);
    final isProcessing = state.isProcessing;
    final currentSize = state.currentBytes?.length ?? 0;

    return ToolPanelContainer(
      title: 'Compresión',
      icon: Icons.compress,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tamaño actual: ${ImageUtils.formatFileSize(currentSize)}',
              style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 8),
          Row(
            children: [
              const Text('Calidad', style: TextStyle(color: AppColors.textMuted)),
              const Spacer(),
              Text('${_quality.round()}%',
                  style: const TextStyle(
                    color: AppColors.accent,
                    fontFeatures: [FontFeature.tabularFigures()],
                  )),
            ],
          ),
          Slider(
            value: _quality,
            min: 10,
            max: 100,
            divisions: 18,
            activeColor: AppColors.accent,
            label: '${_quality.round()}%',
            onChanged:
                isProcessing ? null : (v) => setState(() => _quality = v),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : _apply,
              icon: const Icon(Icons.check),
              label: const Text('Comprimir a JPEG'),
            ),
          ),
        ],
      ),
    );
  }
}
