import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:share_plus/share_plus.dart';
import 'package:path/path.dart' as p;
import '../../core/constants/colors.dart';
import '../../core/utils/save_share.dart';
import '../../shared/widgets/image_viewer.dart';
import 'pdf_provider.dart';

class PdfScreen extends ConsumerWidget {
  const PdfScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(pdfProvider);
    final notifier = ref.read(pdfProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Text('A PDF'),
        actions: [
          if (state.images.isNotEmpty)
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
            // Seleccionar imágenes
            ElevatedButton.icon(
              onPressed: () async {
                final picker = ImagePicker();
                final picked = await picker.pickMultiImage();
                if (picked.isNotEmpty) {
                  notifier.addImages(picked.map((x) => File(x.path)).toList());
                }
              },
              icon: const Icon(Icons.add_photo_alternate),
              label: Text(state.images.isEmpty
                  ? 'Seleccionar imágenes'
                  : 'Agregar más imágenes'),
            ),
            const SizedBox(height: 16),

            if (state.images.isNotEmpty) ...[
              // Lista reordenable
              Text('${state.images.length} imágenes',
                  style: const TextStyle(color: AppColors.textPrimary)),
              const SizedBox(height: 8),
              ReorderableListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: state.images.length,
                onReorderItem: (oldIndex, newIndex) => notifier.reorder(oldIndex, newIndex),
                itemBuilder: (context, index) {
                  return ListTile(
                    key: ValueKey(state.images[index].path),
                    leading: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: Image.file(state.images[index],
                          width: 48, height: 48, fit: BoxFit.cover),
                    ),
                    title: Text(
                      p.basename(state.images[index].path),
                      style: const TextStyle(color: AppColors.textPrimary, fontSize: 14),
                      overflow: TextOverflow.ellipsis,
                    ),
                    trailing: IconButton(
                      icon: const Icon(Icons.close, size: 18, color: AppColors.textMuted),
                      onPressed: () => notifier.removeAt(index),
                    ),
                    tileColor: AppColors.bgElevated,
                  );
                },
              ),
              const SizedBox(height: 16),

              // Orientación
              const Text('Orientación', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PageOrientation.values.map((o) {
                  final labels = {'auto': 'Auto', 'portrait': 'Vertical', 'landscape': 'Horizontal'};
                  final selected = state.orientation == o;
                  return ChoiceChip(
                    label: Text(labels[o.name]!),
                    selected: selected,
                    selectedColor: AppColors.accentDim,
                    backgroundColor: AppColors.bgElevated,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                    ),
                    onSelected: (_) => notifier.setOrientation(o),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),

              // Tamaño
              const Text('Tamaño', style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                children: PageSize.values.map((s) {
                  final labels = {'a4': 'A4', 'letter': 'Carta'};
                  final selected = state.pageSize == s;
                  return ChoiceChip(
                    label: Text(labels[s.name]!),
                    selected: selected,
                    selectedColor: AppColors.accentDim,
                    backgroundColor: AppColors.bgElevated,
                    labelStyle: TextStyle(
                      color: selected ? AppColors.accent : AppColors.textPrimary,
                    ),
                    onSelected: (_) => notifier.setPageSize(s),
                  );
                }).toList(),
              ),
              const SizedBox(height: 16),

              // Nombre
              _FileNameField(
                initialValue: state.fileName,
                onChanged: notifier.setFileName,
              ),
              const SizedBox(height: 16),

              // Generar
              ElevatedButton(
                onPressed: state.isGenerating ? null : () => notifier.generate(),
                child: state.isGenerating
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Generar PDF',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // Resultado
              if (state.resultFile != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.bgElevated,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.success),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.check_circle, color: AppColors.success, size: 48),
                      const SizedBox(height: 8),
                      const Text('PDF generado',
                          style: TextStyle(color: AppColors.textPrimary, fontSize: 16)),

                      // Vista previa de las páginas (toca para ampliar).
                      if (state.previews.isNotEmpty) ...[
                        const SizedBox(height: 12),
                        SizedBox(
                          height: 320,
                          child: ListView.separated(
                            scrollDirection: Axis.horizontal,
                            itemCount: state.previews.length,
                            separatorBuilder: (_, _) =>
                                const SizedBox(width: 8),
                            itemBuilder: (context, i) {
                              final page = state.previews[i];
                              return GestureDetector(
                                onTap: () => FullScreenImageViewer.open(
                                    context, MemoryImage(page)),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border:
                                        Border.all(color: AppColors.border),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  clipBehavior: Clip.antiAlias,
                                  child: Image.memory(page,
                                      height: 320, fit: BoxFit.contain),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          '${state.previews.length} página(s) · toca para ampliar',
                          style: const TextStyle(
                              color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],

                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: () async {
                                final bytes =
                                    await state.resultFile!.readAsBytes();
                                if (context.mounted) {
                                  await SaveShare.downloadBytes(
                                    context,
                                    bytes: bytes,
                                    fileName: '${state.fileName}.pdf',
                                  );
                                }
                              },
                              icon: const Icon(Icons.download),
                              label: const Text('Descargar'),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () {
                                Share.shareXFiles([XFile(state.resultFile!.path)]);
                              },
                              icon: const Icon(Icons.share),
                              label: const Text('Compartir'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.accent,
                                side: const BorderSide(color: AppColors.accent),
                                minimumSize: const Size.fromHeight(48),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Campo del nombre del archivo con su propio controlador persistente: si se
/// recreara en cada rebuild, el cursor saltaría al inicio con cada letra.
class _FileNameField extends StatefulWidget {
  final String initialValue;
  final ValueChanged<String> onChanged;
  const _FileNameField({required this.initialValue, required this.onChanged});

  @override
  State<_FileNameField> createState() => _FileNameFieldState();
}

class _FileNameFieldState extends State<_FileNameField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.initialValue);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return TextField(
      decoration: InputDecoration(
        labelText: 'Nombre del archivo',
        labelStyle: const TextStyle(color: AppColors.textMuted),
        filled: true,
        fillColor: AppColors.bgElevated,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: AppColors.border),
        ),
      ),
      style: const TextStyle(color: AppColors.textPrimary),
      controller: _controller,
      onChanged: widget.onChanged,
    );
  }
}
