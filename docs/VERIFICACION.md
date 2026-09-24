# Estado verificable · primera entrega

| Capacidad | Implementada | Probada realmente aquí | Pendiente |
|---|---|---|---|
| UI React, TypeScript, Tailwind | Sí | Typecheck, compilación Vite y página HTTP 200 | Navegación real en Windows/Tauri |
| API y validaciones | Sí | Arranque del proceso, compilación; 8 pruebas unitarias y humo PostgreSQL/API | Pruebas de interfaz en Windows |
| Migraciones PostgreSQL | Archivos y ejecutor | Migraciones 001–003 aplicadas y reejecutadas en PostgreSQL 16 temporal; usuarios preservados | Actualización real de binarios Windows |
| Primer administrador, roles, miembros, auditoría | API y UI | Humo `tests/smoke.mjs` con base real | Pruebas de interfaz |
| Programación semanal, alternancia, temas, invitaciones y versiones | API y UI | Humo con PostgreSQL: dos publicaciones, versión anterior inmutable y alternancia manual | Prueba visual en Windows |
| Contraseñas y sesiones | Argon2id, tokens 8 h | Humo PostgreSQL/API | Prueba en Windows |
| Respaldo | `pg_dump`, `pg_restore --list`, SHA-256 | Dump real, inspección, SHA-256 y prueba de manipulación | Automatizar respaldo externo |
| Restauración | Script PowerShell, código de 5 min, copia previa | Dump restaurado en segunda base y sobre la base original con `--clean --if-exists --exit-on-error`; datos comprobados; script Windows solo inspeccionado | Ensayo de script Windows con base desechable |
| Tauri | Configuración y fuente Rust | No compilado; Rust ausente | Compilar Windows MSVC |
| Instalador único | Receta Inno Setup, WinSW, PostgreSQL, Node | No compilado ni probado | Obtener binarios, compilar y probar instalación/actualización/desinstalación Windows |
| WhatsApp | Investigación técnica | Consulta a documentación oficial | Validar cuenta/grupo y, si procede, proveedor |

Comandos ejecutados aquí: `npm run typecheck`, `npm test` (8/8), `npm run build` (API y Vite). Se usó PostgreSQL 16 temporal con binarios locales y `pg_dump`/`pg_restore` 16.15, todo en una sesión aislada; la migración, el humo de API, el respaldo y una restauración en una segunda base pasaron. La interfaz Vite respondió HTTP 200. También se ejecutó `pg_restore --clean --if-exists --no-owner --exit-on-error` sobre la base temporal original y se comprobó la recuperación. No se probó interacción visual, Tauri ni Windows. El script PowerShell de restauración y el instalador Windows no se ejecutaron aquí. No hay datos reales. **No utilizar la receta de instalador directamente en producción sin probarla en una VM Windows y verificar restauración.**

Prueba siguiente en Windows: instalar prerequisitos, ejecutar `installer/build-windows.ps1`, ejecutar setup en VM desechable, comprobar servicios `Get-Service GestionIglesia*`, API `Invoke-RestMethod http://127.0.0.1:4317/health`, ejecutar `node tests/smoke.mjs` contra base temporal nueva, restaurar con `restore.ps1` después de modificar miembros, verificar la recuperación, actualizar a una versión nueva y confirmar preservación de datos y configuración.

Para validación Windows reproducible, use una **VM x64 nueva y descartable** con los prerrequisitos de compilación, compile con `installer/build-windows.ps1` y ejecute PowerShell elevado: `./installer/validate-windows.ps1 -InstallerPath ./installer/Output/GestionIglesiaPro-Setup-0.1.0.exe -DisposableVM`. Este guion se preparó pero aún no se ejecutó en Windows. Crea credenciales de prueba, restaura el respaldo generado y verifica la auditoría externa en `ProgramData\GestionIglesiaPro\restore-audit.jsonl`.

**Ampliación:** migración 004 aplicada en PostgreSQL 16 temporal. Se verificó con tres cuentas de prueba la separación de registro, aprobación y pago de un gasto; se registró un ingreso y se comprobó el saldo de caja, presupuesto y bosquejo. La interfaz compiló. El flujo `.github/workflows/windows-installer.yml` y la preparación de dependencias se escribieron, pero no se ejecutaron en GitHub ni en Windows; no hay `.exe` generado.
