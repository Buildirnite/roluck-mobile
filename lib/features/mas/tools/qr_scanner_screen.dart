import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart';
import 'package:share_plus/share_plus.dart';
import '../../../core/constants/colors.dart';
import '../../../shared/widgets/image_picker_zone.dart';

/// Lee códigos QR y de barras de una imagen (on-device, offline).
class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  File? _image;
  bool _isProcessing = false;
  List<Barcode> _codes = [];
  bool _scanned = false;

  Future<void> _scan(File file) async {
    setState(() {
      _image = file;
      _isProcessing = true;
      _scanned = false;
    });
    final scanner = BarcodeScanner();
    try {
      final result = await scanner.processImage(InputImage.fromFile(file));
      setState(() => _codes = result);
    } catch (_) {
      setState(() => _codes = []);
    } finally {
      await scanner.close();
      if (mounted) {
        setState(() {
          _isProcessing = false;
          _scanned = true;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Escáner QR / códigos')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_image == null)
              ImagePickerZone(onImageSelected: _scan)
            else ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.file(_image!, height: 200, fit: BoxFit.cover),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () => setState(() {
                  _image = null;
                  _codes = [];
                  _scanned = false;
                }),
                child: const Text('Escanear otra',
                    style: TextStyle(color: AppColors.accent)),
              ),
              if (_isProcessing)
                const Center(
                    child: CircularProgressIndicator(color: AppColors.accent))
              else if (_scanned && _codes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(16),
                  child: Text('No se detectó ningún código',
                      style: TextStyle(color: AppColors.textMuted)),
                )
              else
                ..._codes.map((c) => _CodeCard(code: c)),
            ],
          ],
        ),
      ),
    );
  }
}

class _CodeCard extends StatelessWidget {
  final Barcode code;
  const _CodeCard({required this.code});

  @override
  Widget build(BuildContext context) {
    final value = code.displayValue ?? code.rawValue ?? '';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bgElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(code.type.name.toUpperCase(),
              style: const TextStyle(color: AppColors.accent, fontSize: 11)),
          const SizedBox(height: 4),
          SelectableText(value,
              style: const TextStyle(
                  color: AppColors.textPrimary, fontFamily: 'monospace')),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Clipboard.setData(ClipboardData(text: value));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Copiado')),
                    );
                  },
                  icon: const Icon(Icons.copy, size: 16),
                  label: const Text('Copiar'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => Share.share(value),
                  icon: const Icon(Icons.share, size: 16),
                  label: const Text('Compartir'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
