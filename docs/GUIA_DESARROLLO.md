# Guía de Desarrollo y Compilación

Esta guía reúne los pasos prácticos para que cualquier integrante del equipo configure su entorno local, ejecute pruebas, depure en dispositivo móvil o navegador y genere los instaladores APK optimizados.

---

## 1. Requisitos del Entorno

| Herramienta | Versión / Configuración Verificada |
| :--- | :--- |
| **Flutter SDK** | `3.50.0` (canal estable) |
| **Dart SDK** | `^3.14.0` (incluido con Flutter) |
| **JDK** | Java 17 / JDK 21 (Gradle `jvmTarget = JVM_17`) |
| **Android SDK** | `minSdk = 24`, plataformas Android API 35/36, Command-Line Tools |
| **Python (opcional docs)** | Python 3.12 únicamente si regeneran diagramas auxiliares |

Comprueba que tu entorno está listo ejecutando:

```bash
flutter doctor -v
```

---

## 2. Flujo Diario de Desarrollo

```bash
# Clonar el repositorio
git clone https://github.com/FrancoGPU/AppAcuerdoVecinal.git
cd AppAcuerdoVecinal

# Descargar dependencias definidas en pubspec.yaml
flutter pub get

# Ejecutar en navegador (ideal para iterar diseño rápido)
flutter run -d chrome

# Ejecutar en teléfono Android conectado por USB (Depuración USB activa)
flutter run
```

> **Consejo:** si deseas compartir una build de prueba con compañeros por red local sin compilar APK en cada cambio, también puedes servir la versión web compilada con `flutter build web`.

---

## 3. Análisis Estático y Pruebas Automatizadas

Antes de subir cambios a GitHub, ejecuta siempre los dos comandos que valida también el workflow de CI (`.github/workflows/flutter_ci.yml`):

```bash
flutter analyze
flutter test
```

### Cobertura en `test/widget_test.dart` (`7` pruebas, `567` líneas)
- Serialización JSON *round-trip* de `NegociacionModel`, `CondicionModel`, `RondaHistorial` y `MensajeChatModel`.
- Generación real de documento PDF en `ActaPdfService` incrustando bytes PNG trazados por `SignaturePadController`.
- Siembra inicial, persistencia entre reinicios, control de turnos, rechazo con motivo, contrapropuestas e inmutabilidad tras sellado en `NegociacionProvider`.
- Firma secuencial individual por participante (`registrarFirmaParticipante`).
- *Smoke tests* de UI incluyendo validación responsiva sin desbordamientos en viewport compacto **`360×780 px`**.

---

## 4. Compilación de APK Optimizado para Android

En `android/app/build.gradle.kts`, el perfil `release` tiene activados `isMinifyEnabled = true` e `isShrinkResources = true` junto con ProGuard/R8.

```bash
flutter build apk --release --split-per-abi
```

Los artefactos resultantes se generan en `build/app/outputs/flutter-apk/`:

| Archivo APK | Tamaño Medido | Uso Recomendado |
| :--- | :---: | :--- |
| `app-arm64-v8a-release.apk` | **`19.0 MB`** | Teléfonos Android modernos de 64 bits (principal) |
| `app-armeabi-v7a-release.apk` | `17.1 MB` | Dispositivos Android ARM de 32 bits |
| `app-x86_64-release.apk` | `20.2 MB` | Emuladores x86_64 en PC |

*(Referencia sin optimizar `app-debug.apk`: `156.0 MB`; la optimización logra una reducción de `-87.8 %` en ARM64 y `-99.5 %` en la fuente `MaterialIcons` gracias al tree-shaking automático).*

---

## 5. Solución Rápida de Problemas Comunes

- **Error al compilar Android por licencia o SDK:** ejecuta `flutter doctor --android-licenses` y acepta las licencias.
- **Datos antiguos en caché durante pruebas en móvil:** dentro de la app, abre el menú `⋮` en `HomeScreen` y pulsa **Restaurar datos demo** para reiniciar los 2 casos semilla sin reinstalar el APK.
- **Advertencias de `MaterialApp` o modales en tests:** asegúrate de encapsular `TextEditingController` de diálogos dentro de su propio `StatefulWidget` con `dispose()` y llamar `FocusManager.instance.primaryFocus?.unfocus()` antes de navegar tras enviar un formulario.
