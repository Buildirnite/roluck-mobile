import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Cómo se comporta un filtro al repetirlo:
/// - [idempotent]: repetirlo no cambia nada (grises, sepia, auto) → se ignora.
/// - [selfInverse]: aplicarlo dos veces vuelve al original (invertir) → cancela.
enum _FilterKind { idempotent, selfInverse }

class _Filter {
  final String id;
  final String label;
  final _FilterKind kind;
  const _Filter(this.id, this.label, {this.kind = _FilterKind.idempotent});
}

const _filters = [
  _Filter('normalize', 'Auto'),
  _Filter('grayscale', 'Grises'),
  _Filter('sepia', 'Sepia'),
  _Filter('invert', 'Invertir', kind: _FilterKind.selfInverse),
];

/// Panel de Filtros: cada filtro se muestra como una miniatura de la imagen
/// actual con el filtro ya aplicado, para elegir viendo el resultado.
class FilterToolPanel extends ConsumerStatefulWidget {
  const FilterToolPanel({super.key});

  @override
  ConsumerState<FilterToolPanel> createState() => _FilterToolPanelState();
}

class _FilterToolPanelState extends ConsumerState<FilterToolPanel> {
  Map<String, Uint8List>? _thumbs;

  @override
  void initState() {
    super.initState();
    _buildThumbs();
  }

  Future<void> _buildThumbs() async {
    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;
    final small = await compute(downscalePngOp, {'bytes': bytes, 'maxDim': 200});
    final thumbs = <String, Uint8List>{};
    for (final f in _filters) {
      thumbs[f.id] =
          await compute(filterImageOp, {'bytes': small, 'filter': f.id});
    }
    if (mounted) setState(() => _thumbs = thumbs);
  }

  Future<void> _apply(_Filter f) async {
    final notifier = ref.read(editorProvider.notifier);
    final opKey = 'filter:${f.id}';

    // Invertir es su propia inversa: aplicarlo justo después se cancela.
    if (f.kind == _FilterKind.selfInverse && notifier.cancelsLastStep(opKey)) {
      notifier.discardLastStep();
      setState(() => _thumbs = null);
      _buildThumbs();
      return;
    }

    // Idempotentes: si el último paso ya fue este filtro, repetirlo no cambia
    // la imagen; evitamos pasos inútiles en el historial.
    if (f.kind == _FilterKind.idempotent &&
        ref.read(editorProvider).lastOpKey == opKey) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${f.label} ya está aplicado')),
      );
      return;
    }

    final bytes = ref.read(editorProvider).currentBytes;
    if (bytes == null) return;

    notifier.setProcessing(true);
    final result = await compute(filterImageOp, {
      'bytes': bytes,
      'filter': f.id,
    });
    notifier.setProcessing(false);
    notifier.applyEdit(f.label, result, opKey: opKey);

    // La imagen actual cambió: regenerar las miniaturas sobre el resultado.
    if (!mounted) return;
    setState(() => _thumbs = null);
    _buildThumbs();
  }

  @override
  Widget build(BuildContext context) {
    final isProcessing = ref.watch(editorProvider).isProcessing;
    final thumbs = _thumbs;

    return ToolPanelContainer(
      title: 'Filtros',
      icon: Icons.auto_awesome,
      child: thumbs == null
          ? const Padding(
              padding: EdgeInsets.symmetric(vertical: 12),
              child: Center(
                  child: CircularProgressIndicator(color: AppColors.accent)),
            )
          : SizedBox(
              height: 96,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 12),
                itemBuilder: (context, i) {
                  final f = _filters[i];
                  final thumb = thumbs[f.id];
                  return GestureDetector(
                    onTap: isProcessing ? null : () => _apply(f),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: thumb == null
                              ? const SizedBox(width: 72, height: 72)
                              : Image.memory(thumb,
                                  width: 72, height: 72, fit: BoxFit.cover),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          f.label,
                          style: const TextStyle(
                              color: AppColors.textPrimary, fontSize: 12),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
    );
  }
}
