import 'package:flutter/material.dart';
import '../../../core/constants/colors.dart';

/// Botón de acción cuadrado (icono + etiqueta) usado por los paneles de
/// herramientas del editor. Se deshabilita visualmente cuando `onTap` es null.
class ToolActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback? onTap;

  const ToolActionButton({
    super.key,
    required this.icon,
    required this.label,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.bgElevated,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 24,
                color: enabled ? AppColors.accent : AppColors.textMuted),
            const SizedBox(height: 6),
            Text(label,
                style: TextStyle(
                  fontSize: 12,
                  color: enabled ? AppColors.textPrimary : AppColors.textMuted,
                )),
          ],
        ),
      ),
    );
  }
}
