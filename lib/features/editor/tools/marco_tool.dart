import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Marco: añade un borde de color o recorta la imagen en círculo.
class MarcoToolPanel extends ConsumerStatefulWidget {
  const MarcoToolPanel({super.key});

  @override
  ConsumerState<MarcoToolPanel> createState() => _MarcoToolPanelState();
}

class _MarcoToolPanelState extends ConsumerState<MarcoToolPanel> {
  double _width = 24;
  Color _color = Colors.white;

  static const _colors = <String, Color>{
    'Blanco': Colors.white,
    'Negro': Colors.black,
    'Lima': AppColors.accent,
    'Gris': Color(0xFF9E9E9E),
    'Rojo': Color(0xFFE53935),
    'Azul': Color(0xFF2196F3),
  };

  Future<void> _applyBorder() async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;
    notifier.setProcessing(true);
    final result = await compute(borderImageOp, {
      'bytes': bytes,
      'r': (_color.r * 255).round(),
      'g': (_color.g * 255).round(),
      'b': (_color.b * 255).round(),
      'width': _width.round(),
    });
    notifier.setProcessing(false);
    notifier.applyEdit('Borde ${_width.round()}', result);
  }

  Future<void> _circle() async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;
    notifier.setProcessing(true);
    final result = await compute(circleCropOp, bytes);
    notifier.setProcessing(false);
    notifier.applyEdit('Círculo', result);
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Marco',
      icon: Icons.crop_din,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Color del borde',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _colors.entries.map((e) {
              final selected = _color == e.value;
              return ChoiceChip(
                label: Text(e.key),
                selected: selected,
                onSelected: (_) => setState(() => _color = e.value),
                selectedColor: AppColors.accentDim,
                backgroundColor: AppColors.bgElevated,
                avatar: CircleAvatar(backgroundColor: e.value, radius: 8),
                labelStyle: TextStyle(
                    color: selected ? AppColors.accent : AppColors.textPrimary,
                    fontSize: 12),
              );
            }).toList(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Grosor',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              Text('${_width.round()} px',
                  style: const TextStyle(
                      color: AppColors.accent,
                      fontFeatures: [FontFeature.tabularFigures()])),
            ],
          ),
          Slider(
            value: _width,
            min: 4,
            max: 120,
            activeColor: AppColors.accent,
            inactiveColor: AppColors.bgElevated,
            label: '${_width.round()}',
            onChanged: isProcessing ? null : (v) => setState(() => _width = v),
          ),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : _applyBorder,
              icon: const Icon(Icons.check),
              label: const Text('Aplicar borde'),
            ),
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: isProcessing ? null : _circle,
              icon: const Icon(Icons.circle_outlined),
              label: const Text('Recorte circular'),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accent,
                side: const BorderSide(color: AppColors.accent),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
