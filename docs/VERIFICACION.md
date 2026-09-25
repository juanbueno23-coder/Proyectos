# Estado verificable · versión 0.1.0

| Capacidad | Implementada | Probada realmente | Pendiente |
|---|---|---|---|
| Interfaz React, TypeScript, Tailwind y Tauri | Sí | Typecheck, Vite y compilación Tauri MSVC en Windows | Prueba visual e interacción manual del escritorio |
| API, autenticación, roles, miembros y auditoría | Sí | 8 pruebas unitarias; humo contra PostgreSQL en Linux y en instalación Windows | Pruebas de interfaz |
| Migraciones 001–004 y persistencia local | Sí | Aplicadas en PostgreSQL 16 temporal; aplicadas en PostgreSQL incluido en instalador Windows | Actualización de instalación existente con datos |
| Programación, historial, finanzas y bosquejos | Sí | Humo con PostgreSQL real, cuentas separadas para aprobación y pago | Revisión funcional con usuarios |
| Respaldo y restauración | Sí | `pg_dump`, SHA-256, `pg_restore` y recuperación del miembro de prueba en Linux y en Windows Server 2022 | Recuperación en otra PC y respaldo externo programado |
| Instalador único Windows x64 | Sí | Compilado con Tauri e Inno Setup; instalación silenciosa en ejecutor Windows, servicios PostgreSQL/API iniciados y salud HTTP | Instalación interactiva, actualización, desinstalación y prueba en Windows 10/11 de usuario |
| WhatsApp | Solo investigación y diseño | Revisión documental | Integración futura bajo mecanismos admitidos |

Evidencia de Windows: [compilación exitosa](https://github.com/juanbueno23-coder/Proyectos/actions/runs/36135308972) y [prueba de instalación exitosa](https://github.com/juanbueno23-coder/Proyectos/actions/runs/36136602336). El ejecutor fue `windows-2022` (Windows Server 2022). Su script `installer/validate-windows.ps1` instaló el `.exe` en una VM descartable, verificó servicios y API, ejecutó `tests/smoke.mjs`, creó respaldo, restauró la base con `installer/restore.ps1`, comprobó el miembro recuperado y la auditoría externa. No se probó abrir la ventana Tauri de forma interactiva.

La [descarga directa de GitHub Releases](https://github.com/juanbueno23-coder/Proyectos/releases/tag/v0.1.0) publica el mismo `.exe`; GitHub informa 268 696 147 bytes y el SHA-256 indicado abajo. Una copia entregada por otro canal resultó truncada a 88 449 024 bytes y provocó «The setup files are corrupted». Descarte esa copia y verifique el hash de la nueva antes de ejecutarla.

Evidencia local: `npm run typecheck`, `npm test` (8/8), `npm run build` y humo con PostgreSQL 16 temporal. El ZIP del artefacto validado coincidió con el SHA-256 publicado por GitHub: `c7688ebb3005a9ca7d6e8f37a5f737605a6eac1aaf62292a563075f0bc19c973`. SHA-256 del `.exe`: `b15d173212136bdfdecb7bbff7a8172d48339acb7f2efc1625ee4a1cc32c260e`.

Para repetir en una VM Windows x64 descartable con Node 24, descargue el artefacto del flujo de compilación y ejecute PowerShell elevado desde la raíz del repositorio:

```powershell
./installer/validate-windows.ps1 -InstallerPath ./installer/Output/GestionIglesiaPro-Setup-0.1.0.exe -DisposableVM
```

No ejecute esta prueba contra una PC con datos existentes. Genera usuarios y datos temporales y realiza una restauración. El uso cotidiano de la aplicación no requiere elevación. Las pruebas de instalación y restauración son evidencia de funcionamiento en el entorno indicado, no sustituyen una prueba interactiva en la PC final.
