import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_action_button.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Efectos: nitidez, viñeta y pixelado.
class EfectosToolPanel extends ConsumerStatefulWidget {
  const EfectosToolPanel({super.key});

  @override
  ConsumerState<EfectosToolPanel> createState() => _EfectosToolPanelState();
}

class _EfectosToolPanelState extends ConsumerState<EfectosToolPanel> {
  double _pixelSize = 12;

  Future<void> _run(String name, Future<Uint8List> Function(Uint8List) op) async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;
    notifier.setProcessing(true);
    final result = await op(bytes);
    notifier.setProcessing(false);
    notifier.applyEdit(name, result);
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Efectos',
      icon: Icons.auto_fix_high,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              ToolActionButton(
                icon: Icons.deblur,
                label: 'Nitidez',
                onTap: isProcessing
                    ? null
                    : () => _run('Nitidez',
                        (b) => compute(sharpenImageOp, b)),
              ),
              ToolActionButton(
                icon: Icons.vignette,
                label: 'Viñeta',
                onTap: isProcessing
                    ? null
                    : () => _run('Viñeta',
                        (b) => compute(vignetteImageOp, b)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Pixelar (bloque)',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text('${_pixelSize.round()} px',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          Slider(
            value: _pixelSize,
            min: 4,
            max: 40,
            divisions: 36,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.bgElevated,
            label: '${_pixelSize.round()}',
            onChanged:
                isProcessing ? null : (v) => setState(() => _pixelSize = v),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing
                  ? null
                  : () => _run(
                        'Pixelado ${_pixelSize.round()}',
                        (b) => compute(pixelateImageOp,
                            {'bytes': b, 'size': _pixelSize.round()}),
                      ),
              icon: const Icon(Icons.grid_on),
              label: const Text('Pixelar'),
            ),
          ),
        ],
      ),
    );
  }
}
