import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_action_button.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Efectos: nitidez, viñeta y pixelado. El pixelado tiene vista previa
/// en vivo (sobre una versión reducida, escalando el tamaño del bloque).
class EfectosToolPanel extends ConsumerStatefulWidget {
  const EfectosToolPanel({super.key});

  @override
  ConsumerState<EfectosToolPanel> createState() => _EfectosToolPanelState();
}

class _EfectosToolPanelState extends ConsumerState<EfectosToolPanel> {
  double _pixelSize = 12;

  // Imagen base al abrir el panel y su versión reducida para la previa.
  Uint8List? _base;
  Uint8List? _baseSmall;
  // Factor (lado reducido / lado completo) para escalar el tamaño de bloque.
  double _previewScale = 1;

  // Control de concurrencia de la previa.
  bool _previewing = false;
  bool _previewDirty = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    ref.read(editorProvider.notifier).clearPreview();
    super.dispose();
  }

  Future<void> _init() async {
    _base = ref.read(editorProvider).currentBytes;
    if (_base == null) return;
    final dims = await compute(imageDimensionsOp, _base!);
    final small =
        await compute(downscalePngOp, {'bytes': _base!, 'maxDim': 720});
    final smallDims = await compute(imageDimensionsOp, small);
    if (!mounted) return;
    final longest = max(dims[0], dims[1]);
    final smallLongest = max(smallDims[0], smallDims[1]);
    setState(() {
      _baseSmall = small;
      _previewScale = longest == 0 ? 1 : smallLongest / longest;
    });
  }

  /// Previa del pixelado sobre la versión reducida, sin solaparse.
  Future<void> _schedulePixelPreview() async {
    final small = _baseSmall;
    if (small == null) return;
    if (_previewing) {
      _previewDirty = true;
      return;
    }
    _previewing = true;
    final notifier = ref.read(editorProvider.notifier);
    do {
      _previewDirty = false;
      final size = max(2, (_pixelSize * _previewScale).round());
      final result =
          await compute(pixelateImageOp, {'bytes': small, 'size': size});
      if (!mounted) break;
      notifier.setPreview(result);
    } while (_previewDirty);
    _previewing = false;
  }

  Future<void> _run(String name, Future<Uint8List> Function(Uint8List) op) async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;
    notifier.setProcessing(true);
    final result = await op(bytes);
    notifier.setProcessing(false);
    notifier.applyEdit(name, result);
    // La imagen actual cambió: la siguiente previa debe partir del resultado.
    if (!mounted) return;
    setState(() => _baseSmall = null);
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;
    final ready = _baseSmall != null;

    return ToolPanelContainer(
      title: 'Efectos',
      icon: Icons.grain,
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
            onChanged: (isProcessing || !ready)
                ? null
                : (v) {
                    setState(() => _pixelSize = v);
                    _schedulePixelPreview();
                  },
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: (isProcessing || !ready)
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
