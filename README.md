# RoLuck Convertidor

App Android de **conversión y edición de imágenes**, hecha en Flutter. Todo el
procesamiento es **on-device y offline** (sin servidores). Identidad visual de
roluck.app: tema oscuro `#0A0A0A`, acento verde lima `#A3E635` y tipografía
monoespaciada para valores numéricos.

> Última actualización: **2026-06-12** · Estado: funcional, probado en emulador
> y dispositivo físico.

---

## Funcionalidades

La app se organiza en **5 pestañas** (barra inferior):

### 1 · Convertir
Conversión de formato con vista previa y comparación de pesos.
- Formatos: **JPEG, PNG, WebP y AVIF real** (`flutter_avif`, libavif on-device).
- Calidad (1–100%) y escala de tamaño (25–100%).
- Manejo de errores visible (no se cuelga si la conversión falla).

### 2 · Editor
Editor **no destructivo** con historial de pasos: cada edición es un chip que
se puede deshacer/rehacer, tocar para saltar a ese punto, o quitar con ✕.
Operaciones inversas consecutivas (rotar ±90°, voltear dos veces, invertir) se
cancelan solas sin procesar. **Mantener pulsada la imagen compara con el
original.**

| Herramienta | Detalles |
|---|---|
| Recortar | uCrop nativo, presets de proporción (1:1, 4:3, 3:2, 16:9) |
| Quitar fondo | ML Kit Subject Segmentation (⚠️ crashea en emulador, OK en físico) |
| Rotar / Voltear | 90°/180°, espejo H/V |
| Filtros | **Miniaturas en vivo**: Auto (normalizar), Grises, Sepia, Invertir |
| Ajustes | Brillo/contraste/saturación/tono con sliders y **preview en vivo** |
| Efectos | Nitidez, viñeta, pixelar (**preview en vivo**) |
| Marco | Borde de 6 colores + recorte circular |
| Redimensionar | Píxeles con proporción bloqueada + presets de redes sociales |
| Marca de agua | Texto con posición, tamaño y **opacidad** |
| Difuminar | Gaussiano con **preview en vivo** (radio escalado) |
| Anotar | Lienzo de dibujo a pantalla completa |
| Compresión | JPEG con calidad y **estimación de peso en vivo** ("≈ X KB") |

Las previews en vivo se calculan sobre una versión reducida (720 px) en un
isolate; al aplicar se procesa a resolución completa.

### 3 · Lote
- Conversión múltiple (mismos formatos que Convertir, incl. AVIF) con calidad y escala.
- Lista con **miniaturas** y estado por imagen; ✕ para quitar de la cola; "Añadir" suma sin reemplazar.
- Exportar: guardar todas en galería (tolerante a fallos) o **ZIP + compartir**.

### 4 · A PDF
- Varias imágenes → un PDF: lista **reordenable**, orientación, tamaño (A4/Carta), nombre del archivo.
- Vista previa de páginas rasterizadas; descargar (ubicación a elegir) o compartir.

### 5 · Más (17 herramientas en 4 secciones)

| Sección | Herramientas |
|---|---|
| **Analizar** | OCR (extraer texto), Visor EXIF, Paleta de colores (cuentagotas + copiar todos), Etiquetar imagen (ML Kit), Escanear QR/códigos |
| **Crear** | Collage (columnas, espaciado, fondo, reordenar), GIF animado (cuadros reordenables, velocidad), Imagen larga (unir capturas V/H), Generar QR |
| **Transformar** | Comprimir a tamaño (presets + búsqueda binaria de calidad), Dividir imagen (cuadrícula con líneas de corte en vivo, soporta 1×N), Marca de agua con logo, **Quitar marca de agua** (inpainting por interpolación, zonas dibujadas con el dedo), PDF a imágenes (DPI ajustable), Base64 |
| **Privacidad** | Difuminar caras (detección automática ML Kit), Limpiar metadatos EXIF |

**Patrones comunes a todas las herramientas:** todo resultado tiene Guardar +
Compartir; visor a pantalla completa con zoom (pellizco/doble-tap); selector
Galería/Cámara; botón "Otra imagen" sin salir de la pantalla; las listas
múltiples permiten añadir, quitar y reordenar.

---

## Arquitectura

```
lib/
├── main.dart · app.dart
├── router/app_router.dart        ← go_router: ShellRoute (5 pestañas) +
│                                    rutas fuera del shell para "Más"
├── core/
│   ├── constants/                (colors, social_presets)
│   ├── theme/                    (app_theme)
│   └── utils/
│       ├── image_ops.dart        ← TODAS las operaciones de imagen (puras,
│       │                            serializables, corren en isolate vía compute)
│       ├── image_utils.dart      (compresión nativa, archivos temp, formato de tamaños)
│       ├── save_share.dart       (guardar con diálogo + compartir)
│       └── pick_image.dart       (hoja Galería/Cámara)
├── features/                     ← una carpeta por pantalla
│   ├── convertir/ · lote/ · pdf/ (pantalla + StateNotifier de Riverpod)
│   ├── editor/                   (provider con historial + tools/ + widgets/)
│   └── mas/                      (grid de secciones + tools/ — 17 pantallas)
└── shared/widgets/               (image_picker_zone, result_card, image_viewer,
                                   batch_list, thumb_strip, main_shell)
```

Reglas del diseño:
- **Estado:** un `StateNotifier` por feature (Riverpod 2). Las pantallas de
  "Más" usan `setState` local (no necesitan estado global).
- **Procesamiento pesado siempre en isolate** (`compute` + funciones de
  `image_ops.dart`) para no congelar la UI. Las operaciones encadenan en PNG
  (sin pérdida); el formato final lo decide la herramienta de salida.
- **ML Kit on-device:** OCR, segmentación de sujeto (quitar fondo), códigos de
  barras, detección de caras, etiquetado. La primera vez cada modelo necesita
  conexión para descargarse; después funciona offline.

---

## Stack y build

- Flutter 3.44.x · Dart 3.12 · minSdk 24 (ML Kit) · compileSdk 36.
- Detalle completo de dependencias, versiones y ajustes de Gradle: ver **STACK.md**.
- Reglas R8/ProGuard para ML Kit en `android/app/proguard-rules.pro`.
- Ícono generado con `tool/generate_app_icon.dart` + `flutter_launcher_icons`.

### Comandos

```bash
flutter run               # con el emulador de Android Studio encendido
                          # r = hot reload · R = hot restart · q = salir
flutter analyze           # debe quedar en 0 issues
flutter build apk --debug # verificación de build
```

### Notas conocidas
- **Quitar fondo crashea en el emulador** (limitación de ML Kit Subject
  Segmentation); funciona en dispositivo físico.
- El APK release pesa **~98 MB** por las libs nativas de ML Kit/AVIF.
- Firma con **debug key** → Play Protect avisa al instalar por sideload
  (pendiente: firma de release propia).
- Warning de Gradle sobre plugins con KGP (`flutter_image_compress`,
  `image_gallery_saver_plus`, `share_plus`): inofensivo hoy; se resolverá
  cuando esos plugins publiquen versiones migradas a Built-in Kotlin.
- "Quitar marca de agua" usa interpolación del borde (sin IA): excelente en
  fondos uniformes, se nota en texturas complejas. Posible mejora futura:
  modelo de inpainting on-device (LaMa/TFLite, +decenas de MB).

---

## Ideas pendientes (no implementadas)

- Recibir imágenes compartidas desde otras apps (intent-filter SEND/SEND_MULTIPLE).
- Firma de release propia (keystore) para distribución.
- Inpainting con IA para Quitar marca de agua.
