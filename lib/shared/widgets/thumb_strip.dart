import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

/// Tira horizontal de miniaturas reordenables: mantener pulsada una miniatura
/// y arrastrarla cambia el orden; la ✕ quita esa imagen. Cada miniatura
/// muestra su número de orden.
class ReorderableThumbStrip extends StatelessWidget {
  final List<File> images;

  /// Recibe los índices ya normalizados (el elemento en [oldIndex] debe
  /// insertarse en [newIndex]).
  final void Function(int oldIndex, int newIndex) onReorder;
  final void Function(int index)? onRemove;

  const ReorderableThumbStrip({
    super.key,
    required this.images,
    required this.onReorder,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 84,
      child: ReorderableListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: images.length,
        // onReorderItem ya entrega newIndex ajustado tras quitar el elemento.
        onReorderItem: onReorder,
        proxyDecorator: (child, index, animation) => Material(
          color: Colors.transparent,
          child: child,
        ),
        itemBuilder: (context, i) => Padding(
          key: ValueKey('${images[i].path}#$i'),
          padding: const EdgeInsets.only(right: 8),
          child: Stack(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.file(images[i],
                    width: 76, height: 76, fit: BoxFit.cover),
              ),
              // Número de orden.
              Positioned(
                left: 4,
                bottom: 4,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${i + 1}',
                    style: const TextStyle(
                      color: AppColors.accent,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              if (onRemove != null)
                Positioned(
                  right: 2,
                  top: 2,
                  child: InkWell(
                    onTap: () => onRemove!(i),
                    customBorder: const CircleBorder(),
                    child: Container(
                      padding: const EdgeInsets.all(3),
                      decoration: const BoxDecoration(
                        color: Colors.black54,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.close,
                          size: 14, color: Colors.white),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
