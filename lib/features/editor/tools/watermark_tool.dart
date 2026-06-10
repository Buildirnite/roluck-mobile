import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Marca de agua: estampa un texto en la posición y tamaño elegidos.
class WatermarkToolPanel extends ConsumerStatefulWidget {
  const WatermarkToolPanel({super.key});

  @override
  ConsumerState<WatermarkToolPanel> createState() => _WatermarkToolPanelState();
}

class _WatermarkToolPanelState extends ConsumerState<WatermarkToolPanel> {
  final _textCtrl = TextEditingController(text: 'RoLuck');
  String _position = 'bottomRight';
  String _size = 'm';

  static const _positions = {
    'topLeft': 'Sup. izq.',
    'topRight': 'Sup. der.',
    'center': 'Centro',
    'bottomLeft': 'Inf. izq.',
    'bottomRight': 'Inf. der.',
  };

  static const _sizes = {'s': 'S', 'm': 'M', 'l': 'L'};

  Future<void> _apply() async {
    final text = _textCtrl.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el texto de la marca de agua')),
      );
      return;
    }
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(watermarkImageOp, {
      'bytes': bytes,
      'text': text,
      'position': _position,
      'size': _size,
    });
    notifier.setProcessing(false);
    notifier.applyEdit('Marca de agua', result);
  }

  @override
  void dispose() {
    _textCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Marca de agua',
      icon: Icons.branding_watermark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: _textCtrl,
            style: const TextStyle(color: AppColors.textPrimary),
            decoration: const InputDecoration(
              labelText: 'Texto',
              labelStyle: TextStyle(color: AppColors.textMuted),
              enabledBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderSide: BorderSide(color: AppColors.accent),
              ),
            ),
          ),
          const SizedBox(height: 12),
          const Text('Posición',
              style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            children: _positions.entries.map((e) {
              final selected = _position == e.key;
              return ChoiceChip(
                label: Text(e.value),
                selected: selected,
                onSelected: (_) => setState(() => _position = e.key),
                labelStyle: TextStyle(
                  color: selected ? AppColors.bgPrimary : AppColors.textPrimary,
                  fontSize: 12,
                ),
                selectedColor: AppColors.accent,
                backgroundColor: AppColors.bgElevated,
                side: const BorderSide(color: AppColors.border),
              );
            }).toList(),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text('Tamaño',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(width: 12),
              ..._sizes.entries.map((e) {
                final selected = _size == e.key;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _size = e.key),
                    labelStyle: TextStyle(
                      color:
                          selected ? AppColors.bgPrimary : AppColors.textPrimary,
                    ),
                    selectedColor: AppColors.accent,
                    backgroundColor: AppColors.bgElevated,
                    side: const BorderSide(color: AppColors.border),
                  ),
                );
              }),
            ],
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: isProcessing ? null : _apply,
              icon: const Icon(Icons.check),
              label: const Text('Aplicar marca de agua'),
            ),
          ),
        ],
      ),
    );
  }
}
