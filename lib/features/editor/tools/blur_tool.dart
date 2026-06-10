import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de Difuminar: aplica un desenfoque gaussiano con el radio elegido.
class BlurToolPanel extends ConsumerStatefulWidget {
  const BlurToolPanel({super.key});

  @override
  ConsumerState<BlurToolPanel> createState() => _BlurToolPanelState();
}

class _BlurToolPanelState extends ConsumerState<BlurToolPanel> {
  double _radius = 5;

  Future<void> _apply() async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(blurImageOp, {
      'bytes': bytes,
      'radius': _radius.round(),
    });
    notifier.setProcessing(false);
    notifier.applyEdit('Difuminado r${_radius.round()}', result);
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Difuminar',
      icon: Icons.blur_on,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Text('Radio', style: TextStyle(color: AppColors.textMuted)),
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
                : (v) => setState(() => _radius = v),
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
