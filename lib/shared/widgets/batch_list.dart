import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

enum BatchItemStatus { queued, processing, done, error }

class BatchItem {
  final String name;
  final BatchItemStatus status;
  final String? errorMessage;
  // Ruta del archivo para mostrar su miniatura (opcional).
  final String? path;

  const BatchItem(
      {required this.name, required this.status, this.errorMessage, this.path});
}

class BatchList extends StatelessWidget {
  final List<BatchItem> items;
  // Si se pasa, los ítems en cola muestran una ✕ para quitarlos de la lista.
  final void Function(int index)? onRemove;

  const BatchList({super.key, required this.items, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 4),
      itemBuilder: (context, index) {
        final item = items[index];
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          decoration: BoxDecoration(
            color: AppColors.bgElevated,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              if (item.path != null) ...[
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.file(File(item.path!),
                      width: 36, height: 36, fit: BoxFit.cover),
                ),
                const SizedBox(width: 10),
              ],
              _statusIcon(item.status),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.name,
                  style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Text(
                _statusLabel(item.status),
                style: TextStyle(
                  color: _statusColor(item.status),
                  fontSize: 12,
                ),
              ),
              if (onRemove != null && item.status == BatchItemStatus.queued)
                Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child: InkWell(
                    onTap: () => onRemove!(index),
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.close,
                          size: 16, color: AppColors.textMuted),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _statusIcon(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.queued:
        return const Icon(Icons.hourglass_empty, size: 18, color: AppColors.textMuted);
      case BatchItemStatus.processing:
        return const SizedBox(
          width: 18,
          height: 18,
          child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.accent),
        );
      case BatchItemStatus.done:
        return const Icon(Icons.check_circle, size: 18, color: AppColors.success);
      case BatchItemStatus.error:
        return const Icon(Icons.error, size: 18, color: AppColors.error);
    }
  }

  String _statusLabel(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.queued:
        return 'En cola';
      case BatchItemStatus.processing:
        return 'Procesando';
      case BatchItemStatus.done:
        return 'Listo';
      case BatchItemStatus.error:
        return 'Error';
    }
  }

  Color _statusColor(BatchItemStatus status) {
    switch (status) {
      case BatchItemStatus.queued:
        return AppColors.textMuted;
      case BatchItemStatus.processing:
        return AppColors.accent;
      case BatchItemStatus.done:
        return AppColors.success;
      case BatchItemStatus.error:
        return AppColors.error;
    }
  }
}
