import 'package:flutter/material.dart';
import '../../core/constants/colors.dart';

enum BatchItemStatus { queued, processing, done, error }

class BatchItem {
  final String name;
  final BatchItemStatus status;
  final String? errorMessage;

  const BatchItem({required this.name, required this.status, this.errorMessage});
}

class BatchList extends StatelessWidget {
  final List<BatchItem> items;

  const BatchList({super.key, required this.items});

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
