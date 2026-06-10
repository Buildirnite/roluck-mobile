import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';
import 'annotate_canvas_screen.dart';

/// Panel de Anotar: abre un lienzo a pantalla completa para dibujar sobre la
/// imagen y devuelve el resultado rasterizado.
class AnnotateToolPanel extends ConsumerWidget {
  const AnnotateToolPanel({super.key});

  Future<void> _open(BuildContext context, WidgetRef ref) async {
    final notifier = ref.read(editorProvider.notifier);
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    final result = await Navigator.of(context).push<Uint8List?>(
      MaterialPageRoute(
        builder: (_) => AnnotateCanvasScreen(imageBytes: bytes),
      ),
    );

    if (result != null) {
      notifier.applyEdit('Anotado', result);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Anotar',
      icon: Icons.draw,
      child: SizedBox(
        width: double.infinity,
        child: FilledButton.icon(
          onPressed: isProcessing ? null : () => _open(context, ref),
          icon: const Icon(Icons.draw),
          label: const Text('Abrir lienzo de dibujo'),
        ),
      ),
    );
  }
}
