import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/colors.dart';
import '../../shared/widgets/image_picker_zone.dart';
import '../../shared/widgets/result_card.dart';
import 'convertir_provider.dart';

class ConvertirScreen extends ConsumerWidget {
  const ConvertirScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(convertirProvider);
    final notifier = ref.read(convertirProvider.notifier);

    return Scaffold(
      appBar: AppBar(title: const Text('Convertir')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (state.inputFile == null)
              ImagePickerZone(onImageSelected: (file) => notifier.setInput(file))
            else ...[
              // Preview
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(
                  state.inputFile!,
                  height: 200,
                  width: double.infinity,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => notifier.setInput(state.inputFile!),
                  child: const Text('Cambiar imagen',
                      style: TextStyle(color: AppColors.accent)),
                ),
              ),
              const SizedBox(height: 12),

              // Selector de formato
              const Text('Formato de salida',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
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

              // Slider de calidad (oculto si PNG)
              if (state.format != OutputFormat.png) ...[
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Calidad',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                    Text(
                      '${state.quality}%',
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontFamily: 'monospace',
                      ),
                    ),
                  ],
                ),
                Slider(
                  value: state.quality.toDouble(),
                  min: 0,
                  max: 100,
                  divisions: 100,
                  activeColor: AppColors.accent,
                  inactiveColor: AppColors.bgElevated,
                  onChanged: (v) => notifier.setQuality(v.round()),
                ),
                const SizedBox(height: 12),
              ],

              // Tamaño (escala). 100% conserva la resolución original.
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Tamaño',
                      style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
                  Text(
                    '${(state.scale * 100).round()}%',
                    style: const TextStyle(
                      color: AppColors.textPrimary,
                      fontFamily: 'monospace',
                    ),
                  ),
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
                onChanged: state.isConverting
                    ? null
                    : (v) => notifier.setScale(v),
              ),
              const SizedBox(height: 12),

              // Botón convertir
              ElevatedButton(
                onPressed: state.isConverting ? null : () => notifier.convert(),
                child: state.isConverting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Convertir',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const SizedBox(height: 16),

              // Resultado
              if (state.resultFile != null)
                ResultCard(
                  file: state.resultFile!,
                  originalSize: state.originalSize ?? 0,
                  resultSize: state.resultSize ?? 0,
                ),
            ],
          ],
        ),
      ),
    );
  }
}
