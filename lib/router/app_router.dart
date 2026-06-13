import 'package:go_router/go_router.dart';
import '../shared/widgets/main_shell.dart';
import '../features/convertir/convertir_screen.dart';
import '../features/editor/editor_screen.dart';
import '../features/lote/lote_screen.dart';
import '../features/pdf/pdf_screen.dart';
import '../features/mas/mas_screen.dart';
import '../features/mas/tools/ocr_screen.dart';
import '../features/mas/tools/exif_screen.dart';
import '../features/mas/tools/base64_screen.dart';
import '../features/mas/tools/paleta_screen.dart';
import '../features/mas/tools/dividir_screen.dart';
import '../features/mas/tools/collage_screen.dart';
import '../features/mas/tools/gif_screen.dart';
import '../features/mas/tools/comprimir_screen.dart';
import '../features/mas/tools/limpiar_exif_screen.dart';
import '../features/mas/tools/pdf_a_imagenes_screen.dart';
import '../features/mas/tools/imagen_larga_screen.dart';
import '../features/mas/tools/marca_agua_logo_screen.dart';
import '../features/mas/tools/quitar_marca_screen.dart';
import '../features/mas/tools/qr_scanner_screen.dart';
import '../features/mas/tools/qr_generator_screen.dart';
import '../features/mas/tools/difuminar_caras_screen.dart';
import '../features/mas/tools/etiquetar_screen.dart';

final appRouter = GoRouter(
  initialLocation: '/',
  routes: [
    ShellRoute(
      builder: (context, state, child) => MainShell(child: child),
      routes: [
        GoRoute(path: '/', builder: (c, s) => const ConvertirScreen()),
        GoRoute(path: '/editor', builder: (c, s) => const EditorScreen()),
        GoRoute(path: '/lote', builder: (c, s) => const LoteScreen()),
        GoRoute(path: '/pdf', builder: (c, s) => const PdfScreen()),
        GoRoute(path: '/mas', builder: (c, s) => const MasScreen()),
      ],
    ),
    // Rutas fuera del shell (sin bottom nav)
    GoRoute(path: '/mas/ocr', builder: (c, s) => const OcrScreen()),
    GoRoute(path: '/mas/exif', builder: (c, s) => const ExifScreen()),
    GoRoute(path: '/mas/base64', builder: (c, s) => const Base64Screen()),
    GoRoute(path: '/mas/paleta', builder: (c, s) => const PaletaScreen()),
    GoRoute(path: '/mas/dividir', builder: (c, s) => const DividirScreen()),
    GoRoute(path: '/mas/collage', builder: (c, s) => const CollageScreen()),
    GoRoute(path: '/mas/gif', builder: (c, s) => const GifScreen()),
    GoRoute(path: '/mas/comprimir', builder: (c, s) => const ComprimirScreen()),
    GoRoute(path: '/mas/limpiar-exif', builder: (c, s) => const LimpiarExifScreen()),
    GoRoute(path: '/mas/pdf-a-imagenes', builder: (c, s) => const PdfAImagenesScreen()),
    GoRoute(path: '/mas/imagen-larga', builder: (c, s) => const ImagenLargaScreen()),
    GoRoute(path: '/mas/marca-agua-logo', builder: (c, s) => const MarcaAguaLogoScreen()),
    GoRoute(path: '/mas/quitar-marca', builder: (c, s) => const QuitarMarcaScreen()),
    GoRoute(path: '/mas/qr-escanear', builder: (c, s) => const QrScannerScreen()),
    GoRoute(path: '/mas/qr-generar', builder: (c, s) => const QrGeneratorScreen()),
    GoRoute(path: '/mas/difuminar-caras', builder: (c, s) => const DifuminarCarasScreen()),
    GoRoute(path: '/mas/etiquetar', builder: (c, s) => const EtiquetarScreen()),
  ],
);
