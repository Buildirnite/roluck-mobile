import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/batch_list.dart';
import '../convertir/convertir_provider.dart';
import 'lote_provider.dart';

class LoteScreen extends ConsumerWidget {
  const LoteScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(loteProvider);
    final notifier = ref.read(loteProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Lote'),
        actions: [
          if (state.inputFiles.isNotEmpty)
            IconButton(
              onPressed: () => notifier.clear(),
              icon: const Icon(Icons.delete_outline),
              tooltip: 'Limpiar',
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Botón seleccionar múltiples
            if (state.inputFiles.isEmpty)
              ElevatedButton.icon(
                onPressed: () async {
                  final picker = ImagePicker();
                  final picked = await picker.pickMultiImage();
                  if (picked.isNotEmpty) {
                    notifier.setFiles(picked.map((x) => File(x.path)).toList());
                  }
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Seleccionar imágenes'),
              )
            else ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${state.inputFiles.length} imágenes seleccionadas',
                    style: const TextStyle(
                        color: AppColors.textPrimary, fontSize: 16),
                  ),
                  TextButton.icon(
                    onPressed: state.isProcessing
                        ? null
                        : () async {
                            final picker = ImagePicker();
                            final picked = await picker.pickMultiImage();
                            if (picked.isNotEmpty) {
                              notifier.addFiles(
                                  picked.map((x) => File(x.path)).toList());
                            }
                          },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Añadir'),
                    style: TextButton.styleFrom(
                        foregroundColor: AppColors.accent),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Formato
              const Text('Formato', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: OutputFormat.values.map((f) {
                  final selected = state.format == f;
                  return ChoiceChip(
                    label: Text(f.name.toUpperCase()),
                    selected: selected,
                    selectedColor: AppColors.accentDim,
                    backgroundColor: AppColors.bgElevated,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                    ),
                    onSelected: (_) => notifier.setFormat(f),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Calidad
              if (state.format != OutputFormat.png) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calidad', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    Text('${state.quality}%',
                        style: const TextStyle(color: AppColors.textPrimary, fontFamily: 'monospace')),
                  ],
                ),
                Slider(
                  value: state.quality.toDouble(),
                  min: 1,
                  max: 100,
                  divisions: 99,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.bgElevated,
                  onChanged: (v) => notifier.setQuality(v.round()),
                ),
                const SizedBox(height: 12),
              ],

              // Escala (aplica a todos los formatos)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Escala',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text('${(state.scale * 100).round()}%',
                      style: const TextStyle(
                          color: AppColors.textPrimary, fontFamily: 'monospace')),
                ],
              ),
              Slider(
                value: state.scale,
                min: 0.25,
                max: 1.0,
                divisions: 15,
                activeColor: AppColors.accent,
                inactiveColor: AppColors.bgElevated,
                label: '${(state.scale * 100).round()}%',
                onChanged: state.isProcessing
                    ? null
                    : (v) => notifier.setScale(v),
              ),
              const SizedBox(height: 12),

              // Lista de items (con ✕ para quitar los que siguen en cola)
              BatchList(
                items: state.items,
                onRemove:
                    state.isProcessing ? null : (i) => notifier.removeAt(i),
              ),
              const SizedBox(height: 16),

              // Botón procesar
              ElevatedButton(
                onPressed: state.isProcessing ? null : () => notifier.processAll(),
                child: state.isProcessing
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Procesar todo',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),

              // Resultados: guardar en galería o exportar ZIP
              if (state.results.isNotEmpty && !state.isProcessing) ...[
                const SizedBox(height: 16),
                Text('${state.results.length} imágenes listas',
                    style: const TextStyle(color: AppColors.success, fontSize: 14)),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final n = await notifier.saveAllToGallery();
                          messenger.showSnackBar(
                            SnackBar(content: Text('$n imágenes guardadas en galería')),
                          );
                        },
                        icon: const Icon(Icons.save),
                        label: const Text('Guardar'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () async {
                          final zip = await notifier.exportZip();
                          if (zip != null) {
                            await Share.shareXFiles([XFile(zip.path)]);
                          }
                        },
                        icon: const Icon(Icons.folder_zip),
                        label: const Text('ZIP'),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}
