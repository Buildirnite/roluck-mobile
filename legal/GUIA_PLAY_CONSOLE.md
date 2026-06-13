# Guía paso a paso — Subir RoLuck a Google Play Console

Guía para completar la publicación desde la consola web. Todo el material que se
prepara desde el PC ya está listo (ver `PUBLICACION_PLAY_STORE.md`). Esta guía
cubre solo lo que se hace en https://play.google.com/console

> ⚠️ REQUISITO CLAVE (verificado jun 2026): las cuentas **personales** creadas
> después del **13 nov 2023** NO pueden publicar directamente en producción.
> Antes deben completar una **PRUEBA CERRADA con ≥12 testers reales, opted-in,
> durante 14 días continuos**, y luego solicitar acceso a producción.
> - Cuentas de **organización** (entidad legal) están exentas.
> - NO uses emuladores ni cuentas falsas como testers → riesgo de suspensión.
> - La verificación de identidad del desarrollador es un proceso paralelo (~2 días).
>
> Por eso el flujo real es: Pruebas internas (para ti) → **Prueba cerrada (12
> testers / 14 días)** → solicitar producción → Producción.

---

## PASO 0 — Cuenta de desarrollador (una sola vez)
1. Entra a https://play.google.com/console y inicia sesión con tu cuenta Google.
2. Paga la cuota única de **USD 25**.
3. Completa tu perfil de desarrollador (nombre, dirección, teléfono). Google puede
   pedir verificación de identidad; puede tardar 1–2 días.

---

## PASO 1 — Crear la app
1. En el panel, **Crear app**.
2. Datos:
   - **Nombre de la app:** `RoLuck Convertidor de Imágenes`
   - **Idioma predeterminado:** Español (es) o Español (Latinoamérica)
   - **Tipo:** App
   - **Gratis o de pago:** Gratis
3. Acepta las declaraciones y crea la app.

---

## PASO 2 — Configuración inicial (panel "Configura tu app")
La consola te muestra una lista de tareas. Se completan en cualquier orden, pero
todas deben quedar en verde antes de poder publicar.

### 2.1 Acceso a la app
- Si la app NO requiere login (es el caso) → marca:
  **"Toda la funcionalidad está disponible sin restricciones de acceso especiales"**.

### 2.2 Anuncios
- ¿La app contiene anuncios? → **No**.

### 2.3 Clasificación de contenido (IARC)
1. Inicia el cuestionario.
2. Email de contacto: `ronald212212@gmail.com`
3. Categoría: **Utilidad, productividad, comunicación u otro**.
4. Responde **No** a todas las preguntas sobre violencia, contenido sexual,
   lenguaje, drogas, apuestas, etc. (la app no tiene nada de eso).
5. Envía → obtendrás clasificación apta para todos los públicos.

### 2.4 Público objetivo y contenido
- **Grupo de edad objetivo:** marca 18+ o 13+ según prefieras. (Si marcas que NO
  está dirigida a niños, evitas requisitos extra de la "Families Policy".)
- ¿Atrae a menores de forma no intencionada? → **No**.

### 2.5 App de noticias
- ¿Es una app de noticias? → **No**.

### 2.6 Seguridad de los datos (MUY IMPORTANTE)
Como la app procesa todo en el dispositivo y no recopila datos:
1. **¿Tu app recopila o comparte datos del usuario?** → **No**.
   *(La app no envía imágenes ni datos a servidores. El acceso a galería/cámara
   es para procesar localmente, lo cual NO cuenta como "recopilación".)*
2. ¿Procesa datos efímeramente / en el dispositivo? → puedes indicar que sí.
3. ¿Datos cifrados en tránsito? → no aplica (no hay envío).
4. ¿El usuario puede pedir que se eliminen sus datos? → no aplica (no se guardan).
5. Pega la URL de la política: **https://buildirnite.github.io/roluck-legal/**

### 2.7 Política de privacidad
- En **Política de la app → Política de privacidad**, pega:
  **https://buildirnite.github.io/roluck-legal/**

### 2.8 App gubernamental / financiera / salud → No (según corresponda).

---

## PASO 3 — Ficha de Play Store (Store listing)
En **Crecimiento → Presencia en la tienda → Ficha de Play Store principal**:

- **Nombre de la app (30):** `RoLuck Convertidor de Imágenes`
- **Descripción breve (80):**
  `Convierte, edita y comprime imágenes sin conexión: JPEG, PNG, WebP, AVIF y más.`
- **Descripción completa (4000):** copiar de `listing_play_store.md`.
- **Ícono (512×512):** subir `store/play_icon_512.png`
- **Gráfico de cabecera (1024×500):** subir `store/feature_graphic.png`
- **Capturas de teléfono (mín. 2):** subir las 4 de `store/screenshots/`
  (`01_convertir.png`, `02_editor.png`, `03_mas.png`, `04_paleta.png`)

### Categorización
- **Categoría de la app:** Herramientas (o Fotografía)
- **Etiquetas:** elige las relacionadas con foto/imagen/utilidad.
- **Datos de contacto:** email `ronald212212@gmail.com` (web y teléfono opcionales).

---

## PASO 4 — Subir el AAB (release)
En **Probar y lanzar → Pruebas → Pruebas internas** (recomendado para empezar):
1. **Crear una versión nueva** (Create new release).
2. **Firma de la app por Google Play:** acéptala cuando lo proponga (Google
   guarda una clave de firma de app; tú subes con tu clave de subida = tu keystore).
   ⚠️ Tu keystore `roluck.keystore` es la **clave de subida**. Guárdala siempre.
3. **Sube el archivo:**
   `roluck_mobile/build/app/outputs/bundle/release/app-release.aab`
4. **Nombre de la versión:** `1.0.0` (ya viene del pubspec: `1.0.0+1`).
5. **Notas de la versión:** p. ej. "Primera versión: convertir, editar y
   herramientas de imagen."
6. Guardar y revisar.

### Añadir testers (solo para pruebas internas)
- Crea una lista de correos (tu propio Gmail) en la pestaña de testers.
- Comparte el enlace de prueba que te da la consola, ábrelo en tu teléfono e
  instala desde Play.

---

## PASO 5 — Prueba cerrada OBLIGATORIA (12 testers / 14 días)
Requisito para cuentas personales creadas tras el 13 nov 2023 (tu caso).
1. Ve a **Probar y lanzar → Pruebas → Pruebas cerradas → Crear track** (o usa
   el de "Closed testing" por defecto).
2. Sube el mismo AAB (o promueve el de pruebas internas).
3. En **Testers**, crea una lista con **al menos 12 correos** de personas reales
   que tengan un teléfono Android con su cuenta Google. Todos deben **aceptar la
   invitación (opt-in)** desde el enlace e **instalar la app**.
4. Mantén la prueba activa **14 días continuos** con esos 12+ testers.
   - ⚠️ No uses emuladores ni cuentas falsas → riesgo de suspensión permanente.
   - Consejo: pide a familiares/amigos, o únete a grupos de intercambio de testers.
5. Cumplidos los 14 días, la consola habilitará **"Solicitar acceso a producción"**.

> En paralelo: completa la **verificación de identidad** del desarrollador
> (~2 días hábiles) si Google la pide. Ambos procesos deben terminar antes de
> llegar a producción.

---

## PASO 6 — Solicitar producción y lanzar
1. Pulsa **Solicitar acceso a producción** y completa el breve cuestionario sobre
   tu prueba cerrada.
2. Tras la aprobación, ve a **Producción → Crear versión**.
3. **Promueve** la versión desde pruebas (no hay que volver a subir el AAB).
4. Selecciona países/regiones de distribución.
5. Asegúrate de que TODO el panel esté en verde → **Revisar** → **Iniciar
   lanzamiento**. Google hace una revisión final (de horas a varios días).

---

## Checklist rápido de archivos a subir
| Qué | Archivo |
|-----|---------|
| AAB | `build/app/outputs/bundle/release/app-release.aab` |
| Ícono 512 | `store/play_icon_512.png` |
| Cabecera 1024×500 | `store/feature_graphic.png` |
| Capturas | `store/screenshots/01..04_*.png` |
| Política privacidad (URL) | https://buildirnite.github.io/roluck-legal/ |
| Textos | `legal/listing_play_store.md` |

## Recordatorios críticos
- ⚠️ **Nunca pierdas** `C:\Users\Buildirnite\roluck.keystore` ni su contraseña.
- El `applicationId` `app.roluck.convertidor` es permanente.
- Si cambias el código, sube el número de versión en `pubspec.yaml`
  (`1.0.0+1` → `1.0.1+2`, etc.) antes de recompilar el AAB.
