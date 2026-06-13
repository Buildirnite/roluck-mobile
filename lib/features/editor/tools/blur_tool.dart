import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Difuminar: desenfoque gaussiano con vista previa en vivo (sobre una
/// versión reducida, escalando el radio para que el resultado se parezca al
/// definitivo). Al aplicar se procesa a resolución completa.
class BlurToolPanel extends ConsumerStatefulWidget {
  const BlurToolPanel({super.key});

  @override
  ConsumerState<BlurToolPanel> createState() => _BlurToolPanelState();
}

class _BlurToolPanelState extends ConsumerState<BlurToolPanel> {
  double _radius = 5;

  // Imagen base al abrir el panel y su versión reducida para la previa.
  Uint8List? _base;
  Uint8List? _baseSmall;
  // Factor (lado reducido / lado completo) para escalar el radio en la previa.
  double _previewScale = 1;

  // Control de concurrencia: una sola previsualización a la vez.
  bool _previewing = false;
  bool _previewDirty = false;

  @override
  void initState() {
    super.initState();
    _init(previewNow: true);
  }

  @override
  void dispose() {
    ref.read(editorProvider.notifier).clearPreview();
    super.dispose();
  }

  Future<void> _init({bool previewNow = false}) async {
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
    if (previewNow) _schedulePreview();
  }

  /// Recalcula la previa sobre la versión reducida sin solaparse: si llega otro
  /// cambio mientras procesa, vuelve a calcular al terminar.
  Future<void> _schedulePreview() async {
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
      final r = (_radius * _previewScale).round().clamp(1, 60);
      final result = await compute(blurImageOp, {'bytes': small, 'radius': r});
      if (!mounted) break;
      notifier.setPreview(result);
    } while (_previewDirty);
    _previewing = false;
  }

  Future<void> _apply() async {
    final base = _base;
    if (base == null) return;
    final notifier = ref.read(editorProvider.notifier);
    notifier.setProcessing(true);
    final result = await compute(blurImageOp, {
      'bytes': base,
      'radius': _radius.round(),
    });
    notifier.setProcessing(false);
    notifier.applyEdit('Difuminado r${_radius.round()}', result);
    // La nueva base es el resultado; la siguiente previa parte de ahí.
    if (!mounted) return;
    setState(() {
      _base = result;
      _baseSmall = null;
    });
    _init();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;
    final ready = _baseSmall != null;

    return ToolPanelContainer(
      title: 'Difuminar',
      icon: Icons.blur_on,
      child: !ready
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Text('Radio',
                        style: TextStyle(color: AppColors.textMuted)),
                    const Spacer(),
                    Text('${_radius.round()} px',
                        style: const TextStyle(
                          color: AppColors.accent,
                          fontFeatures: [FontFeature.tabularFigures()],
                        )),
                  ],
                ),
                Slider(
                  value: _radius,
                  min: 1,
                  max: 30,
                  divisions: 29,
                  activeColor: AppColors.accent,
                  label: '${_radius.round()}',
                  onChanged: isProcessing
                      ? null
                      : (v) {
                          setState(() => _radius = v);
                          _schedulePreview();
                        },
                ),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: isProcessing ? null : _apply,
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
    );
  }
}
