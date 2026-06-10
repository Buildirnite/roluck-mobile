import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class _ToolEntry {
  final String label;
  final IconData icon;
  final String route;
  const _ToolEntry(this.label, this.icon, this.route);
}

const _tools = [
  _ToolEntry('OCR', Icons.text_fields, '/mas/ocr'),
  _ToolEntry('Visor EXIF', Icons.info_outline, '/mas/exif'),
  _ToolEntry('Base64', Icons.code, '/mas/base64'),
  _ToolEntry('Paleta de colores', Icons.palette, '/mas/paleta'),
  _ToolEntry('Dividir imagen', Icons.grid_view, '/mas/dividir'),
  _ToolEntry('Collage', Icons.auto_awesome_mosaic, '/mas/collage'),
  _ToolEntry('GIF animado', Icons.gif_box, '/mas/gif'),
  _ToolEntry('Comprimir a tamaño', Icons.compress, '/mas/comprimir'),
  _ToolEntry('Limpiar metadatos', Icons.cleaning_services, '/mas/limpiar-exif'),
  _ToolEntry('PDF a imágenes', Icons.collections, '/mas/pdf-a-imagenes'),
  _ToolEntry('Imagen larga', Icons.view_day, '/mas/imagen-larga'),
  _ToolEntry('Marca de agua', Icons.branding_watermark, '/mas/marca-agua-logo'),
  _ToolEntry('Escanear QR', Icons.qr_code_scanner, '/mas/qr-escanear'),
  _ToolEntry('Generar QR', Icons.qr_code_2, '/mas/qr-generar'),
  _ToolEntry('Difuminar caras', Icons.face_retouching_off, '/mas/difuminar-caras'),
  _ToolEntry('Etiquetar imagen', Icons.label, '/mas/etiquetar'),
];

class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más herramientas')),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 1.3,
          ),
          itemCount: _tools.length,
          itemBuilder: (context, index) {
            final tool = _tools[index];
            return GestureDetector(
              onTap: () => context.push(tool.route),
              child: Container(
                decoration: BoxDecoration(
                  color: AppColors.bgElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(tool.icon, size: 32, color: AppColors.accent),
                    const SizedBox(height: 8),
                    Text(
                      tool.label,
                      style: const TextStyle(
                        color: AppColors.textPrimary,
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
