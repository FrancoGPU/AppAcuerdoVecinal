# Guía de Contribución — AcuerdoVecinal

Gracias por colaborar en **AcuerdoVecinal**. Para mantener el código limpio y facilitar el trabajo paralelo de los integrantes del equipo, sigue estas pautas simples.

## 1. Flujo de Ramas

- **`main`:** rama principal siempre estable y compilable. No hagas *push* directo con código sin probar.
- Crea una rama descriptiva por tarea desde `main`:
  - `feat/<nombre-corto>` para nuevas funcionalidades (por ejemplo, `feat/integracion-gemini-fase2`).
  - `fix/<nombre-corto>` para corrección de errores (`fix/ajuste-scroll-firma`).
  - `docs/<nombre-corto>` para mejoras de documentación (`docs/actualizar-manual`).

## 2. Convención de Commits

Utilizamos **Conventional Commits**:

- `feat: ...` — nueva funcionalidad para el usuario.
- `fix: ...` — corrección de un error.
- `docs: ...` — cambios en `README.md`, `docs/` o comentarios.
- `refactor: ...` — reestructuración interna sin cambiar comportamiento externo.
- `test: ...` — nuevos tests o ajustes en `test/widget_test.dart`.
- `chore: ...` — tareas de configuración, CI o dependencias.

Ejemplo:
```bash
git commit -m "feat: add AI mediator prompt builder for negotiation table"
```

## 3. Lista de Verificación antes de Abrir un Pull Request

1. Ejecutar `flutter analyze` y confirmar **`No issues found!`**.
2. Ejecutar `flutter test` y confirmar que las **`7` pruebas** (y cualquier prueba nueva) pasan en verde.
3. Si tocaste pantallas o widgets, verificar en un ancho móvil compacto (`360×780`) que no existan errores `RenderFlex overflow`.
4. No subir archivos compilados (`build/`, `.dart_tool/`), cachés locales ni entregables pesados (`*.docx`, `*.pptx`, `*.zip`).
