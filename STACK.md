# RoLuck Convertidor — Stack y estado del proyecto

> Resumen de todo lo que usa la app, su estado y los pendientes.
> Última actualización: **2026-06-12**
> Para el resumen de funcionalidades y arquitectura actual, ver **README.md**
> (las secciones 4 y 7 de este archivo quedaron como referencia histórica).

App móvil **RoLuck Convertidor** — convertidor/editor de imágenes en Flutter
para Android. Tema oscuro (#0A0A0A) con acento verde lima (#A3E635) y tipografía
monoespaciada para valores numéricos.

---

## 1. Entorno / toolchain

| Componente | Versión |
|---|---|
| Flutter | 3.44.1 (canal stable, 2026-05-29) |
| Dart | 3.12.1 |
| SDK constraint (pubspec) | `^3.12.1` |
| `compileSdk` | **36** (forzado; ver nota) |
| `targetSdk` | `flutter.targetSdkVersion` |
| `minSdk` | 24 (requerido por ML Kit) |
| AGP | 9.0.1 |
| Kotlin | 2.3.20 |
| NDK | 28.2.13676358 |

---

## 2. Configuración Android (ajustes aplicados)

Estos cambios fueron necesarios para que el proyecto compile con el toolchain
actual. Si se clona en limpio, hay que mantenerlos:

- **`android/app/build.gradle.kts`** → `compileSdk = 36` (fijo, no
  `flutter.compileSdkVersion`). Lo exige `flutter_plugin_android_lifecycle`.
- **`android/build.gradle.kts`** → bloque `subprojects { afterEvaluate { … } }`
  que fuerza `compileSdk = 36` en todos los módulos de librería. Necesario
  porque `file_picker` fija un `compileSdk 34` propio que no hereda. Debe ir
  **antes** del bloque `evaluationDependsOn(":app")`.
- **`AndroidManifest.xml`** → registrada la actividad `com.yalantis.ucrop.UCropActivity`
  (requerida por `image_cropper`).
- Permisos: `READ_MEDIA_IMAGES`, `READ_MEDIA_VIDEO`, `WRITE_EXTERNAL_STORAGE`
  (maxSdk 28), `CAMERA`, `INTERNET`.

---

## 3. Dependencias actuales

| Paquete | En uso | Para qué | Última mayor disponible |
|---|---|---|---|
| `go_router` | 14.8.1 | Navegación (5 pestañas) | 17.3.0 ⚠️ breaking |
| `flutter_riverpod` | 2.6.1 | Estado global | 3.3.1 ⚠️ breaking |
| `image_picker` | 1.1.x | Selección de imágenes | al día |
| `image` | 4.3.0 | Procesamiento (rotar, filtros, blur, resize, watermark, GIF…) | 4.9.1 (menor, seguro) |
| `flutter_image_compress` | 2.4.x | Conversión JPEG/PNG/WebP, compresión | al día |
| `image_cropper` | 12.2.1 | Recortar (uCrop nativo) | al día |
| `image_gallery_saver_plus` | 5.0.0 | Guardar en galería | al día |
| `share_plus` | 10.1.4 | Compartir archivos | 13.1.0 ⚠️ breaking |
| `permission_handler` | 11.4.0 | Permisos | 12.0.3 ⚠️ |
| `pdf` + `printing` | 3.11 / 5.13 | Generar PDF | al día |
| `path_provider` | 2.1.x | Archivos temporales | al día |
| `open_file` | 3.5.x | Abrir archivos | al día |
| `archive` | 3.6.x | ZIP para lotes | 4.x disponible |
| `google_mlkit_text_recognition` | 0.14.0 | OCR on-device | 0.15.1 (menor) |
| `exif` | 3.3.0 | Visor EXIF | — |
| `file_picker` | 8.3.7 | Selección de archivos | 11.0.2 ⚠️ |
| `mime`, `path` | — | Utilidades | al día |

> **⚠️ breaking** = subir esa versión mayor rompe la API que usamos hoy
> (requiere migrar código). El proyecto funciona con el set actual; no conviene
> subirlas sin una migración planificada y pruebas.

**Actualizaciones menores seguras** (no rompen): `image` → 4.9.1,
`google_mlkit_text_recognition` → 0.15.1.

---

## 4. Estado de funcionalidades

### Pantalla 1 — Convertir
- ✅ JPEG, PNG, WebP (con `flutter_image_compress`)
- ✅ ** Real AVIF** with `flutter_avif` (`encodeAvif`).

### Pantalla 2 — Editor (modelo no destructivo, deshacer/revertir, badges)
| Herramienta | Estado |
|---|---|
| Recortar | ✅ uCrop nativo |
| Rotar | ✅ 90°/180° |
| Voltear | ✅ horizontal/vertical |
| Filtros | ✅ grises, sepia, invertir, brillo±, contraste±, saturación± |
| Redimensionar | ✅ ancho/alto + proporción + **presets sociales** |
| Marca de agua | ✅ texto, posición, tamaño |
| Difuminar | ✅ gaussiano con radio |
| Anotar | ✅ lienzo de dibujo, colores, grosor, export a resolución original |
| Compresión | ✅ JPEG con calidad |
| Quitar fondo | ⏳ panel informativo (sin paquete aún). Ver §5. |

Todo el procesamiento corre en isolate (`compute`) → UI fluida.
Operaciones en `lib/core/utils/image_ops.dart`.

### Pantalla 3 — Lote
- ✅ Selección múltiple, formato (incl. AVIF real), calidad y **escala**.
- ✅ Procesado en serie con estado por imagen.
- ✅ Exportar: **guardar todas en galería** o **ZIP + compartir** (`archive`).

### Pantalla 4 — A PDF
- ✅ Selección múltiple, orientación/tamaño, generar y compartir.

### Pantalla 5 — Más
- ✅ OCR, Visor EXIF, Base64, Paleta de colores, Dividir en cuadrícula,
  Collage, **GIF animado**.

---

## 5. Pendientes — investigación de paquetes (2026-06-06)

### 5.1 AVIF → ✅ **INTEGRADO** (`flutter_avif` 3.1.0)
- `encodeAvif(inputBytes)` en uso en Convertir y Lote.
- No requiere Rust (binarios precompilados vía `flutter_avif_android`).
- Añadió `flutter_cache_manager`, `http` y otras transitivas.

### 5.2 Quitar fondo → ✅ **INTEGRADO** (`google_mlkit_subject_segmentation` 0.0.3)
- Segmentación de sujeto general (no solo personas), on-device.
- La primera vez descarga el modelo (necesita conexión una vez).
- ⚠️ Crashea en emulador; funciona en dispositivo físico.
- Reglas R8 (`-keep`/`-dontwarn com.google.mlkit`) en
  `android/app/proguard-rules.pro`.

### 5.3 Más paquetes ML Kit integrados después de este análisis
`google_mlkit_barcode_scanning`, `google_mlkit_face_detection`,
`google_mlkit_image_labeling` (commons ^0.11) y `qr_flutter` para generar QR.
El APK release pesa ~98 MB por las libs nativas.

---

## 6. Notas de mantenimiento

- El proyecto está sobre la **última Flutter stable** (3.44.1) y versiones de
  paquetes coherentes entre sí. "Estar al día" aquí significa este conjunto
  estable, no necesariamente el último mayor de cada paquete.
- Antes de subir cualquier paquete marcado **⚠️ breaking**, planificar la
  migración (sobre todo `riverpod` 2→3 y `go_router` 14→17, que cambian APIs
  centrales) y probar en emulador.
- Tras añadir plugins **nativos** (p. ej. `flutter_avif`, recortador, bg
  remover) hay que reiniciar `flutter run` por completo (no basta hot reload) y,
  si hubo plugin viejo, `flutter clean`.

---

## 7. Arquitectura (resumen)

```
lib/
├── main.dart · app.dart · router/app_router.dart
├── core/
│   ├── constants/  (colors, social_presets)
│   ├── theme/      (app_theme)
│   └── utils/      (image_utils, image_ops ← procesamiento, file_utils, color_palette)
├── features/
│   ├── convertir/ · editor/ · lote/ · pdf/ · mas/
│   └── editor/tools/  (10 herramientas) + editor/widgets/
└── shared/  (widgets, providers/app_store)
```
