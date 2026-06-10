import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../editor_provider.dart';
import '../widgets/tool_panel_container.dart';

/// Cómo se comporta un filtro al repetirlo:
/// - [accumulate]: cada toque suma efecto (brillo, contraste, saturación).
/// - [idempotent]: repetirlo no cambia nada (grises, sepia) → se ignora.
/// - [selfInverse]: aplicarlo dos veces vuelve al original (invertir) → cancela.
enum _FilterKind { accumulate, idempotent, selfInverse }

class _Filter {
  final String id;
  final String label;
  final IconData icon;
  final _FilterKind kind;
  const _Filter(this.id, this.label, this.icon,
      {this.kind = _FilterKind.accumulate});
}

const _filters = [
  _Filter('grayscale', 'Grises', Icons.gradient, kind: _FilterKind.idempotent),
  _Filter('sepia', 'Sepia', Icons.filter_vintage, kind: _FilterKind.idempotent),
  _Filter('invert', 'Invertir', Icons.invert_colors,
      kind: _FilterKind.selfInverse),
];

/// Panel de Filtros: efectos de color de un toque. Grises/Sepia no se repiten
/// (idempotentes) e Invertir se cancela a sí mismo. Brillo, contraste y
/// saturación están ahora en la herramienta Ajustes (con sliders).
class FilterToolPanel extends ConsumerWidget {
  const FilterToolPanel({super.key});

  Future<void> _apply(BuildContext context, WidgetRef ref, _Filter f) async {
    final notifier = ref.read(editorProvider.notifier);
    final opKey = 'filter:${f.id}';

    // Invertir es su propia inversa: aplicarlo justo después se cancela.
    if (f.kind == _FilterKind.selfInverse && notifier.cancelsLastStep(opKey)) {
      notifier.discardLastStep();
      return;
    }

    // Grises/Sepia: si el último paso ya fue este mismo filtro, repetirlo no
    // cambia la imagen; evitamos pasos inútiles en el historial.
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
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isProcessing = ref.watch(editorProvider).isProcessing;

    return ToolPanelContainer(
      title: 'Filtros',
      icon: Icons.tune,
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: _filters.map((f) {
          return ActionChip(
            avatar: Icon(f.icon, size: 16, color: AppColors.accent),
            label: Text(f.label),
            labelStyle: const TextStyle(color: AppColors.textPrimary, fontSize: 13),
            backgroundColor: AppColors.bgElevated,
            side: const BorderSide(color: AppColors.border),
            onPressed: isProcessing ? null : () => _apply(context, ref, f),
          );
        }).toList(),
      ),
    );
  }
}
