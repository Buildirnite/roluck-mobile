import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Ajustes: brillo, contraste y saturación con sliders y vista previa
/// en vivo (sobre una versión reducida para que sea fluido). Al confirmar se
/// aplica a resolución completa como un único paso del historial.
class AdjustToolPanel extends ConsumerStatefulWidget {
  const AdjustToolPanel({super.key});

  @override
  ConsumerState<AdjustToolPanel> createState() => _AdjustToolPanelState();
}

class _AdjustToolPanelState extends ConsumerState<AdjustToolPanel> {
  double _brightness = 0;
  double _contrast = 0;
  double _saturation = 0;
  double _hue = 0;

  // Base sobre la que se calculan los ajustes (la imagen al abrir el panel) y su
  // versión reducida para la previsualización en vivo.
  Uint8List? _base;
  Uint8List? _baseSmall;

  // Control de concurrencia: solo una previsualización a la vez.
  bool _previewing = false;
  bool _previewDirty = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  @override
  void dispose() {
    // Si se cierra el panel sin aplicar, descartamos la vista previa.
    ref.read(editorProvider.notifier).clearPreview();
    super.dispose();
  }

  Future<void> _init() async {
    _base = ref.read(editorProvider).currentBytes;
    if (_base == null) return;
    final small = await compute(downscalePngOp, {'bytes': _base!, 'maxDim': 720});
    if (mounted) setState(() => _baseSmall = small);
  }

  bool get _changed =>
      _brightness != 0 || _contrast != 0 || _saturation != 0 || _hue != 0;

  Map<String, dynamic> _params(Uint8List bytes) => {
        'bytes': bytes,
        'brightness': _brightness,
        'contrast': _contrast,
        'saturation': _saturation,
        'hue': _hue,
      };

  /// Recalcula la vista previa (sobre la versión reducida), evitando solaparse:
  /// si llega otro cambio mientras procesa, vuelve a calcular al terminar.
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
      if (!_changed) {
        notifier.clearPreview();
      } else {
        final result = await compute(adjustImageOp, _params(small));
        if (!mounted) break; // el panel se cerró mientras se calculaba
        notifier.setPreview(result);
      }
    } while (_previewDirty);
    _previewing = false;
  }

  Future<void> _apply() async {
    final base = _base;
    if (base == null || !_changed) return;
    final notifier = ref.read(editorProvider.notifier);
    notifier.setProcessing(true);
    final result = await compute(adjustImageOp, _params(base));
    notifier.setProcessing(false);
    notifier.applyEdit(_label(), result);
    // Tras aplicar, la nueva base es el resultado; reiniciamos los sliders.
    if (!mounted) return;
    setState(() {
      _brightness = 0;
      _contrast = 0;
      _saturation = 0;
      _hue = 0;
      _base = result;
      _baseSmall = null;
    });
    _init();
  }

  String _label() {
    final parts = <String>[];
    if (_brightness != 0) parts.add('B${_brightness > 0 ? '+' : ''}${_brightness.round()}');
    if (_contrast != 0) parts.add('C${_contrast > 0 ? '+' : ''}${_contrast.round()}');
    if (_saturation != 0) parts.add('S${_saturation > 0 ? '+' : ''}${_saturation.round()}');
    if (_hue != 0) parts.add('T${_hue > 0 ? '+' : ''}${_hue.round()}');
    return 'Ajuste ${parts.join(' ')}';
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;
    final ready = _baseSmall != null;

    return ToolPanelContainer(
      title: 'Ajustes',
      icon: Icons.tune,
      child: !ready
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _AdjustSlider(
                  label: 'Brillo',
                  icon: Icons.brightness_6,
                  value: _brightness,
                  onChanged: (v) {
                    setState(() => _brightness = v);
                    _schedulePreview();
                  },
                ),
                _AdjustSlider(
                  label: 'Contraste',
                  icon: Icons.contrast,
                  value: _contrast,
                  onChanged: (v) {
                    setState(() => _contrast = v);
                    _schedulePreview();
                  },
                ),
                _AdjustSlider(
                  label: 'Saturación',
                  icon: Icons.water_drop,
                  value: _saturation,
                  onChanged: (v) {
                    setState(() => _saturation = v);
                    _schedulePreview();
                  },
                ),
                _AdjustSlider(
                  label: 'Tono',
                  icon: Icons.palette,
                  value: _hue,
                  min: -180,
                  max: 180,
                  onChanged: (v) {
                    setState(() => _hue = v);
                    _schedulePreview();
                  },
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: (isProcessing || !_changed) ? null : _apply,
                    icon: const Icon(Icons.check),
                    label: const Text('Aplicar'),
                  ),
                ),
              ],
            ),
    );
  }
}

class _AdjustSlider extends StatelessWidget {
  final String label;
  final IconData icon;
  final double value;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _AdjustSlider({
    required this.label,
    required this.icon,
    required this.value,
    this.min = -100,
    this.max = 100,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 16, color: AppColors.textMuted),
            const SizedBox(width: 6),
            Text(label, style: const TextStyle(color: AppColors.textMuted)),
            const Spacer(),
            Text(
              '${value > 0 ? '+' : ''}${value.round()}',
              style: const TextStyle(
                color: AppColors.accent,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.bgElevated,
          label: '${value.round()}',
          onChanged: onChanged,
        ),
      ],
    );
  }
}
