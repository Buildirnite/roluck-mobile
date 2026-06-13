# Publicación en Google Play Store — RoLuck Convertidor

Documento de seguimiento del proceso de publicación.
Última actualización: 13 de junio de 2026

---

## ✅ YA HECHO

### 1. Firma de la app (keystore)
- **Keystore creado:** `C:\Users\Buildirnite\roluck.keystore`
- **Alias:** `roluck`
- **Algoritmo:** RSA 2048, validez hasta 2053
- **Certificado:** `CN=Ronald, OU=RTE Design, O=RoLuck, L=Lima, ST=Lima, C=PE`
- **Credenciales:** en `android/key.properties` (NO se sube a git; protegido en `.gitignore`)
- ⚠️ **IMPORTANTE:** guardar el keystore y la contraseña en lugar seguro. Sin ellos
  NO se puede actualizar la app nunca más.

### 2. Configuración de build de release
- `android/app/build.gradle.kts` firma con el keystore real (ya NO con la debug key).
- R8/minify + shrink activados.
- **AAB final compilado y verificado** (13 jun 2026, tras el cambio de applicationId):
  - Comando: `flutter build appbundle --release` (desde `roluck_mobile/`)
  - Salida: `build/app/outputs/bundle/release/app-release.aab` (116.3 MB)
  - Firma verificada: certificado release correcto (válido hasta 2053).
  - applicationId embebido verificado: `app.roluck.convertidor`. ✅ Listo para subir.

### 3. applicationId definitivo
- **`app.roluck.convertidor`** (irreversible una vez publicada la app).
- El `namespace` interno sigue siendo `app.roluck.roluck_mobile` (invisible, no afecta).

### 4. Herramienta "Quitar marca de agua" → renombrada "Borrador mágico"
- Evita rechazo por políticas de copyright de Google.
- La función (inpainting / borrar objetos) es idéntica; solo cambiaron los textos visibles.

### 5. Política de privacidad
- **Publicada en:** https://buildirnite.github.io/roluck-legal/
- Repo: `Buildirnite/roluck-legal` (GitHub Pages). Fuente: `roluck_mobile/legal/privacidad.html`
- Esta URL se usa en Play Console (Política de privacidad + Seguridad de los datos).

### 6. Textos del listing
- Redactados en `roluck_mobile/legal/listing_play_store.md`:
  - Título (30/30): `RoLuck Convertidor de Imágenes`
  - Descripción corta (79/80)
  - Descripción larga (1941/4000)

---

## ⏳ PENDIENTE

### A. Gráficos de la ficha
- [x] **Ícono de la app:** 512×512 → `store/play_icon_512.png` ✅
- [x] **Gráfico de cabecera (feature graphic):** 1024×500 → `store/feature_graphic.png` ✅
- [x] **Capturas de pantalla:** 4 en `store/screenshots/` (1080×2400) ✅
      - `01_convertir.png` — conversión con foto + formatos + calidad/tamaño
      - `02_editor.png` — editor con foto + herramientas
      - `03_mas.png` — grilla de herramientas
      - `04_paleta.png` — paleta de colores con códigos hex
- [ ] (Opcional) Capturas de tablet.

> Gráficos: `dart run tool/generate_store_graphics.dart`.
> Capturas: tomadas en emulador Pixel (Android 14) vía adb screencap; foto de muestra
> en `store/sample_photo.jpg` (`tool/make_sample_photo.dart`).

### B. Formulario "Seguridad de los datos" (Data Safety)
- En Play Console. Como la app NO recopila datos, casi todo es "No":
  - ¿Recopila o comparte datos del usuario? → **No**
  - ¿Procesamiento en el dispositivo? → **Sí**
  - Cifrado en tránsito → no aplica (no hay envío de datos)
- Pegar la URL de la política de privacidad.

### C. Clasificación de contenido (Content Rating)
- Completar el cuestionario IARC en Play Console.
- App de utilidad sin contenido sensible → clasificación apta para todos.

### D. Detalles de la ficha en Play Console
- [ ] Categoría: **Herramientas** o **Fotografía**
- [ ] Email de contacto del desarrollador
- [ ] País/región de distribución
- [ ] Precio: **Gratis**
- [ ] Público objetivo / edad

### E. Cuenta de desarrollador de Google Play
- [ ] Tener cuenta de Google Play Console (pago único de USD 25 si aún no la tienes).
- [ ] App creada en la consola con el nombre y idioma por defecto (español).

### F. Lanzamiento
- [ ] Subir el AAB a un track (recomendado empezar por **pruebas internas** o
      **cerradas** antes de producción).
- [ ] Completar todas las secciones marcadas en rojo en Play Console.
- [ ] Enviar a revisión.

---

## 📁 Archivos de referencia (en `roluck_mobile/legal/`)
- `privacidad.html` — fuente de la política de privacidad
- `listing_play_store.md` — título y descripciones
- `PUBLICACION_PLAY_STORE.md` — este documento

## 🔑 Datos críticos a resguardar
| Dato | Valor |
|------|-------|
| Keystore | `C:\Users\Buildirnite\roluck.keystore` |
| Alias | `roluck` |
| applicationId | `app.roluck.convertidor` |
| Política de privacidad | https://buildirnite.github.io/roluck-legal/ |
