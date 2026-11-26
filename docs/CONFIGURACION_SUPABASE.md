# Guía de Configuración: Supabase, Mediador Gemini IA y GitHub Pages

Esta guía explica cómo activar el modo en la nube (tiempo real entre 2 celulares y la web) y publicar **AcuerdoVecinal** en GitHub Pages sin exponer secretos en el repositorio.

> **Nota para exposición en clase:** Si en el aula no hubiera conexión o aún no configuras las credenciales, la app incluye **Modo Demo Local** completamente funcional desde el dispositivo.

---

## 1. Crear proyecto gratuito en Supabase

1. Ingresa a [supabase.com](https://supabase.com) e inicia sesión con GitHub.
2. Haz clic en **New Project**, elige un nombre (ej. `acuerdo-vecinal`) y una contraseña segura para PostgreSQL.
3. En **Authentication → Providers → Email**, para agilizar el registro en vivo durante la demostración en clase, desactiva temporalmente **Confirm email** y guarda cambios.
4. Copia tus credenciales en **Project Settings → API**:
   - **Project URL** (`https://xxxxx.supabase.co`)
   - **anon public key** (`eyJ...`)

---

## 2. Crear tablas, roles, RPCs y políticas RLS

1. En el panel izquierdo de Supabase entra a **SQL Editor**.
2. Crea una nueva consulta (**New query**), pega el contenido completo de [`supabase/migrations/001_initial_schema.sql`](../supabase/migrations/001_initial_schema.sql) y presiona **Run**.
3. Verifica en **Table Editor** que existan las 5 tablas:
   - `condominios`
   - `perfiles` (`vecino` y `administrador`)
   - `reglamento_articulos`
   - `negociaciones`
   - `mensajes_mediador`

---

## 3. Activar la Edge Function `mediador-ia` con Gemini

La API key de Gemini **nunca** se guarda en Flutter; vive en Supabase Edge Functions:

1. Obtén una API key gratuita en [Google AI Studio](https://aistudio.google.com/).
2. Con Supabase CLI desde la raíz del repositorio:

```bash
supabase login
supabase link --project-ref TU_PROJECT_REF
supabase secrets set GEMINI_API_KEY=tu_api_key_de_gemini
supabase functions deploy mediador-ia
```

Si la Edge Function aún no está desplegada o falla la red, la app activa automáticamente un **Asistente Harvard Local** usando el reglamento vivo del condominio.

---

## 4. Publicar la Web en GitHub Pages (automático)

1. En tu repositorio de GitHub (`FrancoGPU/AppAcuerdoVecinal`) ve a **Settings → Secrets and variables → Actions** y agrega:
   - `SUPABASE_URL`
   - `SUPABASE_ANON_KEY`
2. Ve a **Settings → Pages → Build and deployment → Source** y selecciona **GitHub Actions**.
3. Cada `push` a `main` ejecutará [`.github/workflows/deploy_web.yml`](../.github/workflows/deploy_web.yml) y publicará la app en:
   `https://francogpu.github.io/AppAcuerdoVecinal/`

---

## 5. Compilar APK o ejecutar localmente con nube

```bash
# Ejecutar en Chrome / Web local conectado a Supabase
flutter run -d web-server --web-port 8080 \
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY

# Compilar APK optimizado para entregar/instalar en 2 celulares
flutter build apk --release --split-per-abi \
  --dart-define=SUPABASE_URL=https://TU_PROYECTO.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=TU_ANON_KEY
```

También puedes ingresar `URL` y `Anon Key` directamente dentro de la app desde el icono de engranaje (**Configurar nube**) en la pantalla de inicio de sesión.
