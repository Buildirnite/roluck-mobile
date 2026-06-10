import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/constants/social_presets.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Redimensionar: cambia el tamaño en píxeles, con opción de mantener
/// la proporción original.
class ResizeToolPanel extends ConsumerStatefulWidget {
  const ResizeToolPanel({super.key});

  @override
  ConsumerState<ResizeToolPanel> createState() => _ResizeToolPanelState();
}

class _ResizeToolPanelState extends ConsumerState<ResizeToolPanel> {
  final _widthCtrl = TextEditingController();
  final _heightCtrl = TextEditingController();
  bool _lockRatio = true;
  double _ratio = 1; // ancho / alto original
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _loadDimensions();
  }

  Future<void> _loadDimensions() async {
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;
    final dims = await compute(imageDimensionsOp, bytes);
    if (!mounted || dims[0] == 0) return;
    setState(() {
      _widthCtrl.text = '${dims[0]}';
      _heightCtrl.text = '${dims[1]}';
      _ratio = dims[0] / dims[1];
      _loaded = true;
    });
  }

  void _onWidthChanged(String v) {
    if (!_lockRatio) return;
    final w = int.tryParse(v);
    if (w == null || w <= 0) return;
    _heightCtrl.text = '${(w / _ratio).round()}';
  }

  void _onHeightChanged(String v) {
    if (!_lockRatio) return;
    final h = int.tryParse(v);
    if (h == null || h <= 0) return;
    _widthCtrl.text = '${(h * _ratio).round()}';
  }

  void _applyPreset(Size size) {
    setState(() {
      // El preset fija ambas dimensiones, así que desactivamos el bloqueo de
      // proporción para no recalcular y distorsionar el valor elegido.
      _lockRatio = false;
      _widthCtrl.text = '${size.width.toInt()}';
      _heightCtrl.text = '${size.height.toInt()}';
    });
  }

  Future<void> _apply() async {
    final w = int.tryParse(_widthCtrl.text);
    final h = int.tryParse(_heightCtrl.text);
    if (w == null || h == null || w <= 0 || h <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica un ancho y alto válidos')),
      );
      return;
    }
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(resizeImageOp, {
      'bytes': bytes,
      'width': w,
      'height': h,
    });
    notifier.setProcessing(false);
    notifier.applyEdit('Redimensionado $w×$h', result);
  }

  @override
  void dispose() {
    _widthCtrl.dispose();
    _heightCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Redimensionar',
      icon: Icons.aspect_ratio,
      child: !_loaded
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
                    Expanded(
                      child: _NumberField(
                        controller: _widthCtrl,
                        label: 'Ancho (px)',
                        onChanged: _onWidthChanged,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _NumberField(
                        controller: _heightCtrl,
                        label: 'Alto (px)',
                        onChanged: _onHeightChanged,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Checkbox(
                      value: _lockRatio,
                      activeColor: AppColors.accent,
                      onChanged: (v) =>
                          setState(() => _lockRatio = v ?? true),
                    ),
                    const Text('Mantener proporción',
                        style: TextStyle(color: AppColors.textPrimary)),
                  ],
                ),
                const SizedBox(height: 8),
                const Text('Presets de redes sociales',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: socialPresets.entries.map((e) {
                    return ActionChip(
                      label: Text(
                        '${e.key} (${e.value.width.toInt()}×${e.value.height.toInt()})',
                        style: const TextStyle(
                            color: AppColors.textPrimary, fontSize: 12),
                      ),
                      backgroundColor: AppColors.bgElevated,
                      side: const BorderSide(color: AppColors.border),
                      onPressed: () => _applyPreset(e.value),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 12),
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

class _NumberField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  const _NumberField({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
      style: const TextStyle(color: AppColors.textPrimary),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(color: AppColors.textMuted),
        enabledBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.border),
        ),
        focusedBorder: const OutlineInputBorder(
          borderSide: BorderSide(color: AppColors.accent),
        ),
      ),
    );
  }
}
