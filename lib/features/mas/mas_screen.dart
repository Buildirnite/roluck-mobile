import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/colors.dart';

class _ToolEntry {
  final String label;
  final String subtitle;
  final IconData icon;
  final String route;
  const _ToolEntry(this.label, this.subtitle, this.icon, this.route);
}

class _ToolSection {
  final String title;
  final List<_ToolEntry> tools;
  const _ToolSection(this.title, this.tools);
}

// Herramientas agrupadas por lo que hacen, para que la cuadrícula sea fácil
// de escanear: leer información, crear algo nuevo, transformar o proteger.
const _sections = [
  _ToolSection('Analizar', [
    _ToolEntry('OCR', 'Extraer texto', Icons.text_fields, '/mas/ocr'),
    _ToolEntry('Visor EXIF', 'Ver metadatos', Icons.info_outline, '/mas/exif'),
    _ToolEntry('Paleta de colores', 'Colores dominantes', Icons.palette,
        '/mas/paleta'),
    _ToolEntry('Etiquetar imagen', 'Detectar contenido', Icons.label,
        '/mas/etiquetar'),
    _ToolEntry('Escanear QR', 'Leer códigos', Icons.qr_code_scanner,
        '/mas/qr-escanear'),
  ]),
  _ToolSection('Crear', [
    _ToolEntry('Collage', 'Unir en cuadrícula', Icons.auto_awesome_mosaic,
        '/mas/collage'),
    _ToolEntry('GIF animado', 'Animar varias fotos', Icons.gif_box,
        '/mas/gif'),
    _ToolEntry('Imagen larga', 'Unir capturas', Icons.view_day,
        '/mas/imagen-larga'),
    _ToolEntry('Generar QR', 'Crear códigos', Icons.qr_code_2,
        '/mas/qr-generar'),
  ]),
  _ToolSection('Transformar', [
    _ToolEntry('Comprimir a tamaño', 'Llegar a un peso fijo', Icons.compress,
        '/mas/comprimir'),
    _ToolEntry('Dividir imagen', 'Cortar en partes', Icons.grid_view,
        '/mas/dividir'),
    _ToolEntry('Marca de agua', 'Estampar tu logo', Icons.branding_watermark,
        '/mas/marca-agua-logo'),
    _ToolEntry('Borrador mágico', 'Borrar objetos no deseados', Icons.healing,
        '/mas/quitar-marca'),
    _ToolEntry('PDF a imágenes', 'Extraer páginas', Icons.collections,
        '/mas/pdf-a-imagenes'),
    _ToolEntry('Base64', 'Imagen a texto y volver', Icons.code,
        '/mas/base64'),
  ]),
  _ToolSection('Privacidad', [
    _ToolEntry('Difuminar caras', 'Tapar rostros', Icons.face_retouching_off,
        '/mas/difuminar-caras'),
    _ToolEntry('Limpiar metadatos', 'Quitar datos EXIF',
        Icons.cleaning_services, '/mas/limpiar-exif'),
  ]),
];

class MasScreen extends StatelessWidget {
  const MasScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Más herramientas')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          for (final section in _sections) ...[
            Padding(
              padding: const EdgeInsets.only(bottom: 10, top: 6),
              child: Text(
                section.title.toUpperCase(),
                style: const TextStyle(
                  color: AppColors.textMuted,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.5,
              ),
              itemCount: section.tools.length,
              itemBuilder: (context, index) {
                final tool = section.tools[index];
                return GestureDetector(
                  onTap: () => context.push(tool.route),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    decoration: BoxDecoration(
                      color: AppColors.bgElevated,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.border),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(tool.icon, size: 28, color: AppColors.accent),
                        const SizedBox(height: 8),
                        Text(
                          tool.label,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 14,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tool.subtitle,
                          style: const TextStyle(
                            color: AppColors.textMuted,
                            fontSize: 11,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}
