# CONTEXTO DEL PROYECTO — RoLuck Convertidor

> Documento maestro para retomar el proyecto en cualquier momento.
> Última actualización: 13 de junio de 2026.
> Idioma de trabajo: **español** (el usuario solo habla español).

---

## 1. ¿Qué es la app?

**RoLuck Convertidor de Imágenes** — app móvil **Android** hecha en **Flutter**.
Es un "todo en uno" para imágenes: convertir formatos, editar, comprimir y ~17
herramientas extra. **Todo el procesamiento es on-device** (sin servidores, sin
recopilar datos): ese es su gran diferenciador de privacidad.

- Proyecto **nuevo desde cero** (no es port del web roluck.app, solo comparte la
  identidad visual).
- Carpeta del proyecto: `roluck_mobile/`.
- Identidad visual: tema **oscuro** (#0A0A0A), acento **verde lima** (#A3E635),
  números en monoespaciado. Logo: una llama (logo "ROLUCK / HERRAMIENTAS DE IMAGEN").

## 2. ¿Para qué sirve? (funcionalidades)

Navegación con **5 pestañas** (go_router + ShellRoute) + rutas fuera del shell
para las herramientas de "Más":

- **Convertir** — JPEG/PNG/WebP/AVIF, calidad y escala. AVIF real con flutter_avif.
- **Editor** — historial con deshacer/rehacer, preview en vivo, comparar con
  original. Herramientas: recortar (uCrop), **quitar fondo** (ML Kit Subject
  Segmentation), rotar, voltear, filtros, ajustes (brillo/contraste/saturación/
  tono), efectos (nitidez/viñeta/pixelar), marco, redimensionar, marca de agua,
  difuminar, anotar, comprimir.
- **Lote** — procesar varias imágenes.
- **A PDF** — crear PDF desde fotos (con vista previa).
- **Más** (~17 herramientas) — OCR, Visor EXIF, Base64, Paleta de colores,
  Dividir, Collage, GIF, Comprimir a tamaño, Limpiar EXIF, PDF→imágenes, Imagen
  larga, Marca de agua con logo, Escanear QR, Generar QR, Difuminar caras,
  Etiquetar imagen, **Borrador mágico** (borrar objetos / inpainting).

Todos los resultados tienen **Guardar + Compartir** y **visor a pantalla completa
con zoom**.

## 3. Arquitectura y stack

- **Estado:** Riverpod (un StateNotifier por feature).
- **Estructura:** `features/` por pantalla, `core/` (theme, constants, utils),
  `shared/widgets/`, `router/`.
- **Operaciones pesadas de imagen:** en isolates con `compute` (`core/utils/image_ops.dart`).
- **ML on-device:** Google ML Kit (text_recognition, subject_segmentation,
  barcode_scanning, face_detection, image_labeling). Reglas R8 en
  `android/app/proguard-rules.pro`.
- **Selección de imágenes:** `image_picker` (usa el **Photo Picker del sistema**,
  sin permisos de medios).
- **Android:** compileSdk 36, **targetSdk 36**, minSdk 24. JVM 17.
- El AAB release pesa ~116 MB (por libs nativas de ML Kit).

### Fixes de build conocidos
- `flutter_avif_android` requiere forzar **JVM 17** en todas las libs y borrar una
  clase Java duplicada — resuelto en `android/build.gradle.kts`
  (bloque `subprojects { afterEvaluate { ... } }`).

### Comandos
- Analizar: `flutter analyze`
- Correr (emulador/dispositivo): `flutter run` (hot reload con `r`/`R`).
  El usuario corre desde la terminal de VS Code contra el emulador de Android Studio.
- AAB release: `flutter build appbundle --release` (desde `roluck_mobile/`, ~3-6 min).
- Quitar fondo (ML Kit) **crashea en emulador**, funciona en dispositivo físico.

---

## 4. Estado de PUBLICACIÓN en Play Store

### ✅ Listo (todo lo generable desde el PC)
- **Firma:** keystore propio en `C:\Users\Buildirnite\roluck.keystore`
  (alias `roluck`, contraseña `Roluck@2025`, válido hasta 2053). Config en
  `android/key.properties` (ignorado en git) + `android/app/build.gradle.kts`.
- **AAB final** firmado y verificado (applicationId `app.roluck.convertidor`).
- **applicationId definitivo:** `app.roluck.convertidor` (irreversible).
- **Política de privacidad publicada:** https://buildirnite.github.io/roluck-legal/
  (repo `Buildirnite/roluck-legal`, GitHub Pages; fuente `legal/privacidad.html`).
- **Textos del listing:** `legal/listing_play_store.md` (título 30, corta 79/80,
  larga 1941/4000).
- **Gráficos:** `store/play_icon_512.png` (512×512), `store/feature_graphic.png`
  (1024×500), 4 capturas en `store/screenshots/`.
- **Cumplimiento de permisos:** quitados READ_MEDIA_IMAGES/VIDEO (se usa Photo
  Picker), READ_EXTERNAL_STORAGE capado a ≤32, quitada dep `permission_handler`.
- "Quitar marca de agua" → renombrada **"Borrador mágico"** (políticas copyright).

### ⏳ Pendiente (en Play Console, requiere la cuenta del usuario)
- El usuario **ya pagó** la cuenta de desarrollador (USD 25); **verificación de
  identidad pendiente** (~2 días).
- Completar ficha y formularios: Data Safety (= "No recopila datos"), clasificación
  de contenido, público objetivo, política de privacidad (pegar URL).
- Subir el AAB nuevo + gráficos + capturas.
- ⚠️ **MURO PARA PRODUCCIÓN:** cuenta personal creada tras 13-nov-2023 → exige
  **prueba cerrada con ≥12 testers reales opted-in durante 14 días** antes de
  solicitar acceso a producción. (NO emuladores ni cuentas falsas.)
  El cuello de botella es conseguir 12 testers, no el código.

### Requisitos Play verificados (jun 2026)
- Target API mínimo: **35** hoy, **36** desde 31-ago-2026 → la app (36) cumple ambos.
- Política de Permisos de Fotos y Video: cumplida vía Photo Picker.

### Monetización (futura, "misión" del usuario)
- Recomendado: **Google Play Billing** (compra "Pro" o suscripción) para no romper
  la narrativa de privacidad. **Evitar anuncios** (los SDK recopilan datos →
  obligaría a cambiar Data Safety y la política).

---

## 5. ¿Dónde nos quedamos? (último estado)

Acabamos de **verificar el cumplimiento de políticas con datos reales de jun 2026**
(búsqueda web), limpiar los permisos del manifiesto, recompilar el AAB y actualizar
la guía con el requisito de los 12 testers/14 días.

**Próximo paso natural:** mientras se verifica la cuenta, organizar los **12 testers**
(reclutamiento + mensaje de invitación + mini-guía de qué deben hacer). Luego, ya en
Play Console, seguir `legal/GUIA_PLAY_CONSOLE.md` paso a paso.

---

## 6. Documentos de referencia
- `legal/PUBLICACION_PLAY_STORE.md` — seguimiento + análisis de cumplimiento.
- `legal/GUIA_PLAY_CONSOLE.md` — guía paso a paso de Play Console (incl. 12 testers).
- `legal/listing_play_store.md` — título y descripciones.
- `legal/privacidad.html` — fuente de la política de privacidad.

## 7. Datos críticos a resguardar
| Dato | Valor |
|------|-------|
| Keystore | `C:\Users\Buildirnite\roluck.keystore` |
| Alias / contraseña | `roluck` / `Roluck@2025` |
| applicationId | `app.roluck.convertidor` (permanente) |
| Política de privacidad | https://buildirnite.github.io/roluck-legal/ |
| Repos GitHub | `Buildirnite/roluck-mobile` (app), `Buildirnite/roluck-legal` (política) |

> ⚠️ Si se pierde el keystore o su contraseña, NO se puede actualizar la app nunca más.
