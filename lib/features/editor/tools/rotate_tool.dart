import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_action_button.dart';
import '../widgets/tool_panel_container.dart';

/// Panel de la herramienta Rotar: gira la imagen en pasos de 90°.
class RotateToolPanel extends ConsumerWidget {
  const RotateToolPanel({super.key});

  Future<void> _rotate(WidgetRef ref, num degrees) async {
    final notifier = ref.read(editorProvider.notifier);

    final label = degrees == 180
        ? 'Rotado 180°'
        : 'Rotado ${degrees > 0 ? '90° ↻' : '90° ↺'}';

    // Clave de operación e inversa, para que rotaciones opuestas consecutivas
    // se cancelen en el historial (180° es su propia inversa).
    final String opKey, inverseKey;
    if (degrees == 180) {
      opKey = 'rotate:180';
      inverseKey = 'rotate:180';
    } else if (degrees > 0) {
      opKey = 'rotate:90';
      inverseKey = 'rotate:-90';
    } else {
      opKey = 'rotate:-90';
      inverseKey = 'rotate:90';
    }

    // Si esta rotación deshace la anterior, se cancelan sin procesar nada.
    if (notifier.cancelsLastStep(inverseKey)) {
      notifier.discardLastStep();
      return;
    }

    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(rotateImageOp, {
      'bytes': bytes,
      'degrees': degrees,
    });
    notifier.setProcessing(false);

    notifier.applyEdit(label, result, opKey: opKey);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Rotar',
      icon: Icons.rotate_right,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ToolActionButton(
            icon: Icons.rotate_left,
            label: '90° izq.',
            onTap: isProcessing ? null : () => _rotate(ref, -90),
          ),
          ToolActionButton(
            icon: Icons.rotate_right,
            label: '90° der.',
            onTap: isProcessing ? null : () => _rotate(ref, 90),
          ),
          ToolActionButton(
            icon: Icons.flip_camera_android,
            label: '180°',
            onTap: isProcessing ? null : () => _rotate(ref, 180),
          ),
        ],
      ),
    );
  }
}
