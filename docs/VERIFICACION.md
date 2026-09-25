# Verificación de la revisión 0.1.1

| Capacidad | Estado | Evidencia | Pendiente |
|---|---|---|---|
| Miembros y familias | Implementados: IDs de familia existentes, alta automática transaccional, ficha y mensajes de validación | Typecheck, compilación, pruebas de esquema | Humo PostgreSQL y prueba visual Windows de 0.1.1 |
| Programación y responsable | Solo miembro activo para participaciones nuevas y edición; directorio propio para quienes programan | Typecheck, prueba del esquema; humo preparado | Humo PostgreSQL y prueba visual Windows |
| WhatsApp individual | Enlace oficial con texto y teléfono del miembro, solo al pulsar | Compilación y revisión de código | Envío real requiere confirmación en WhatsApp; no hay acuse automático |
| Panel inicial | Indicadores de miembros, familias y acceso rápido | Compilación | Prueba visual Windows |
| Instalador 0.1.1 | Receta Inno Setup con PostgreSQL local, servicio y migración 005 | Compilación pendiente en GitHub Actions | Instalación, restauración y actualización en Windows |

La versión 0.1.0 anterior se compiló y pasó instalación, API, CRUD, respaldo y restauración en una VM Windows Server 2022 (ejecuciones Actions 36135308972 y 36136602336). Esa prueba **no certifica los cambios de 0.1.1**. Para este cambio, `npm run typecheck`, `npm test` (10/10) y `npm run build` pasaron en Linux. No hay binarios PostgreSQL ni Windows en este entorno; el humo de API y la migración nueva se ejecutarán en el flujo Windows.

El instalador deja datos y respaldos en ProgramData y hace un respaldo previo a la actualización del servicio. Para compilar localmente: `powershell -File installer/build-windows.ps1`. Para validar en VM nueva descartable: `./installer/validate-windows.ps1 -InstallerPath ./installer/Output/GestionIglesiaPro-Setup-0.1.1.exe -DisposableVM`. La ruta de actualización con datos existentes sigue pendiente de ensayo real.
