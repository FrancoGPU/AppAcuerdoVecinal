# Historial de Cambios (Changelog)

Todos los cambios relevantes de **AcuerdoVecinal** se documentan en este archivo.

## [1.0.0+1] — Fase 1 MVP Verificada (2026-11)

### Agregado
- Flujo completo de mediación vecinal basado en el Método Harvard en 4 pantallas (`HomeScreen`, `CrearNegociacionScreen`, `MesaNegociacionScreen`, `ActaAcuerdoScreen`) y 9 widgets modulares.
- Base normativa integrada (`reglamento_data.dart`) con 5 categorías vecinales y 6 criterios objetivos (`Arts. 14, 18, 22, 27, 31` y *Criterio de Beneficio Mutuo / Buena Convivencia*).
- Validaciones de narrativa persuasiva ($\ge 15$ caracteres en argumento y $\ge 5$ caracteres en motivo de rechazo) con historial de rondas (`RondaHistorial`).
- Conmutador dinámico de rol (`Dpto. 301` ↔ `Dpto. 402`) y 2 casos semilla demostrativos en `mock_negociaciones.dart`.
- Persistencia local offline JSON mediante `LocalStorageService` (`SharedPreferences`).
- Generador vectorial de Actas de Compromiso A4 (`ActaPdfService`) con puente nativo Android (`MainActivity.kt` vía `MediaStore.Downloads` y `FileProvider`) y exportación Web (`package:web`).
- Suite de `7` pruebas automatizadas en `test/widget_test.dart` (modelos, PDF, reglas Harvard, firma secuencial y layout móvil `360×780`).
- Documentación técnica completa (`README.md`, `docs/`, `CONTRIBUTING.md`) e integración continua en `.github/workflows/flutter_ci.yml`.

### Corregido y Optimizado
- Eliminación de excepción de ciclo de vida `_dependents.isEmpty` refactorizando controladores de diálogos en `StatefulWidget`s dedicados y creando `SelectorCampoModal`.
- Resolución de desbordamientos visuales `RenderFlex` en anchos compactos de teléfono móvil.
- Rediseño del flujo de firma hacia captura individual por rol en `ModalFirmaTactil` aislado sin scroll (`0 px` touch slop), evitando trazos accidentales.
- Reemplazo de `share_plus` y `path_provider_android` por puente Kotlin propio para resolver fallos de exportación PDF bajo ofuscación R8.
- Reducción de peso del instalador Android de `156.0 MB` (Debug) a `19.0 MB` (`arm64-v8a` Release) mediante `--split-per-abi`, R8 (`isMinifyEnabled` / `isShrinkResources`), limpieza de dependencias y tree-shaking de íconos.
