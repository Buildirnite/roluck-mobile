import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image_gallery_saver_plus/image_gallery_saver_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../core/utils/image_ops.dart';
import '../../../core/utils/image_utils.dart';
import '../../../core/utils/save_share.dart';
import '../../../shared/widgets/image_viewer.dart';

/// Estampa un logo/imagen como marca de agua sobre otra imagen, con posición,
/// tamaño y opacidad ajustables.
class MarcaAguaLogoScreen extends StatefulWidget {
  const MarcaAguaLogoScreen({super.key});

  @override
  State<MarcaAguaLogoScreen> createState() => _MarcaAguaLogoScreenState();
}

class _MarcaAguaLogoScreenState extends State<MarcaAguaLogoScreen> {
  File? _base;
  File? _logo;
  String _position = 'bottomRight';
  double _scale = 25; // % del ancho
  double _opacity = 80; // %
  bool _isProcessing = false;
  Uint8List? _result;

  static const _positions = {
    'topLeft': 'Sup. izq.',
    'topRight': 'Sup. der.',
    'center': 'Centro',
    'bottomLeft': 'Inf. izq.',
    'bottomRight': 'Inf. der.',
  };

  Future<File?> _pick() async {
    final picked =
        await ImagePicker().pickImage(source: ImageSource.gallery);
    return picked == null ? null : File(picked.path);
  }

  Future<void> _apply() async {
    final base = _base, logo = _logo;
    if (base == null || logo == null) return;
    setState(() => _isProcessing = true);
    final result = await compute(watermarkLogoOp, {
      'base': await base.readAsBytes(),
      'logo': await logo.readAsBytes(),
      'position': _position,
      'scale': _scale / 100.0,
      'opacity': _opacity / 100.0,
    });
    setState(() {
      _result = result;
      _isProcessing = false;
    });
  }

  Future<void> _save() async {
    if (_result == null) return;
    final messenger = ScaffoldMessenger.of(context);
    final file = await ImageUtils.saveTempFile(_result!, 'png');
    await ImageGallerySaverPlus.saveFile(file.path);
    if (mounted) {
      messenger.showSnackBar(
          const SnackBar(content: Text('Guardado en galería')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Marca de agua (logo)')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await _pick();
                      if (f != null) setState(() => _base = f);
                    },
                    icon: const Icon(Icons.image),
                    label: Text(_base == null ? 'Imagen' : '✓ Imagen'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final f = await _pick();
                      if (f != null) setState(() => _logo = f);
                    },
                    icon: const Icon(Icons.branding_watermark),
                    label: Text(_logo == null ? 'Logo' : '✓ Logo'),
                  ),
                ),
              ],
            ),
            if (_base != null) ...[
              const SizedBox(height: 12),
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_base!, height: 160, fit: BoxFit.cover),
              ),
            ],
            if (_base != null && _logo != null) ...[
              const SizedBox(height: 16),
              const Text('Posición',
                  style: TextStyle(color: AppColors.textMuted, fontSize: 13)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 8,
                children: _positions.entries.map((e) {
                  final selected = _position == e.key;
                  return ChoiceChip(
                    label: Text(e.value),
                    selected: selected,
                    onSelected: (_) => setState(() => _position = e.key),
                    selectedColor: AppColors.accentDim,
                    backgroundColor: AppColors.bgElevated,
                    labelStyle: TextStyle(
                        color: selected
                            ? AppColors.accent
                            : AppColors.textPrimary,
                        fontSize: 12),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              _LabeledSlider(
                label: 'Tamaño',
                value: _scale,
                suffix: '%',
                min: 5,
                max: 80,
                onChanged: (v) => setState(() => _scale = v),
              ),
              _LabeledSlider(
                label: 'Opacidad',
                value: _opacity,
                suffix: '%',
                min: 10,
                max: 100,
                onChanged: (v) => setState(() => _opacity = v),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: _isProcessing ? null : _apply,
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Aplicar marca de agua'),
              ),
            ],
            if (_result != null) ...[
              const SizedBox(height: 16),
              ZoomableImage(image: MemoryImage(_result!), fit: BoxFit.contain),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _save,
                      icon: const Icon(Icons.save),
                      label: const Text('Guardar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => SaveShare.shareBytes(
                          bytes: _result!, fileName: 'marca_agua.png'),
                      icon: const Icon(Icons.share),
                      label: const Text('Compartir'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _LabeledSlider extends StatelessWidget {
  final String label;
  final double value;
  final String suffix;
  final double min;
  final double max;
  final ValueChanged<double> onChanged;

  const _LabeledSlider({
    required this.label,
    required this.value,
    required this.suffix,
    required this.min,
    required this.max,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13)),
            Text('${value.round()}$suffix',
                style: const TextStyle(
                    color: AppColors.textPrimary, fontFamily: 'monospace')),
          ],
        ),
        Slider(
          value: value,
          min: min,
          max: max,
          activeColor: AppColors.accent,
          inactiveColor: AppColors.bgElevated,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
