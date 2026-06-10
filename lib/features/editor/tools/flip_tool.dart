import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_action_button.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de la herramienta Voltear: espeja la imagen horizontal o verticalmente.
class FlipToolPanel extends ConsumerWidget {
  const FlipToolPanel({super.key});

  Future<void> _flip(WidgetRef ref, bool horizontal) async {
    final notifier = ref.read(editorProvider.notifier);

    // Voltear en el mismo eje es su propia inversa: hacerlo dos veces seguidas
    // se cancela en el historial, sin procesar nada.
    final key = horizontal ? 'flip:h' : 'flip:v';
    if (notifier.cancelsLastStep(key)) {
      notifier.discardLastStep();
      return;
    }

    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(flipImageOp, {
      'bytes': bytes,
      'horizontal': horizontal,
    });
    notifier.setProcessing(false);

    notifier.applyEdit(
      horizontal ? 'Volteado ↔' : 'Volteado ↕',
      result,
      opKey: key,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Voltear',
      icon: Icons.flip,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ToolActionButton(
            icon: Icons.swap_horiz,
            label: 'Horizontal',
            onTap: isProcessing ? null : () => _flip(ref, true),
          ),
          ToolActionButton(
            icon: Icons.swap_vert,
            label: 'Vertical',
            onTap: isProcessing ? null : () => _flip(ref, false),
          ),
        ],
      ),
    );
  }
}
