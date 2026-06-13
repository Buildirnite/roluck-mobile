import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/colors.dart';
import '../editor_provider.dart';

class _ToolItem {
  final EditorTool tool;
  final IconData icon;
  final String label;
  const _ToolItem(this.tool, this.icon, this.label);
}

const _tools = [
  _ToolItem(EditorTool.crop, Icons.crop, 'Recortar'),
  _ToolItem(EditorTool.removeBg, Icons.auto_fix_high, 'Quitar fondo'),
  _ToolItem(EditorTool.rotate, Icons.rotate_right, 'Rotar'),
  _ToolItem(EditorTool.flip, Icons.flip, 'Voltear'),
  _ToolItem(EditorTool.filters, Icons.auto_awesome, 'Filtros'),
  _ToolItem(EditorTool.adjust, Icons.tune, 'Ajustes'),
  _ToolItem(EditorTool.effects, Icons.grain, 'Efectos'),
  _ToolItem(EditorTool.frame, Icons.crop_din, 'Marco'),
  _ToolItem(EditorTool.resize, Icons.aspect_ratio, 'Redimensionar'),
  _ToolItem(EditorTool.watermark, Icons.branding_watermark, 'Marca de agua'),
  _ToolItem(EditorTool.blur, Icons.blur_on, 'Difuminar'),
  _ToolItem(EditorTool.annotate, Icons.draw, 'Anotar'),
  _ToolItem(EditorTool.compress, Icons.compress, 'Compresión'),
];

class ToolPalette extends ConsumerWidget {
  const ToolPalette({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeTool = ref.watch(editorProvider).activeTool;
    final notifier = ref.read(editorProvider.notifier);

    return SizedBox(
      height: 48,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _tools.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, index) {
          final t = _tools[index];
          final isActive = activeTool == t.tool;
          return GestureDetector(
            onTap: () => notifier.setActiveTool(t.tool),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: isActive ? AppColors.accentDim : AppColors.bgElevated,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isActive ? AppColors.accent : AppColors.border,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(t.icon, size: 18,
                      color: isActive ? AppColors.accent : AppColors.textPrimary),
                  const SizedBox(width: 6),
                  Text(t.label,
                      style: TextStyle(
                        fontSize: 13,
                        color: isActive ? AppColors.accent : AppColors.textPrimary,
                      )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
