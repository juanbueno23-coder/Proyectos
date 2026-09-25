# Gestión Iglesia Pro · Iglesia Roca de Salvación

Primera entrega instalable para Windows x64. El instalador `GestionIglesiaPro-Setup-0.1.0.exe` contiene Tauri, servicio API, Node y PostgreSQL; funciona localmente sin Internet durante el uso administrativo. Fue compilado y sometido a instalación, operaciones y restauración en una máquina desechable con Windows Server 2022. Consulte [estado de verificación](docs/VERIFICACION.md) antes de usar datos reales.

## Arquitectura

- Tauri 2 envuelve la interfaz React, TypeScript y Tailwind; solo accede a la API local `127.0.0.1:4317`.
- Node/Express es un proceso separado diseñado para WinSW como servicio Windows. PostgreSQL local usa el puerto `54339` y registra su propio servicio. La API y PostgreSQL escuchan solo en localhost inicialmente.
- `api/src/domain.ts` contiene validación; `api/src/server.ts` define casos de uso, autenticación y permisos; `api/src/db.ts` encapsula el acceso; `api/migrations` contiene el esquema. Separación suficiente para primera versión; extraer casos de uso del router en la próxima iteración.
- `ProgramData\GestionIglesiaPro` conserva PostgreSQL, credenciales de servicio, respaldos y solicitud de restauración; binarios están en Program Files. ACL restringe ProgramData a SYSTEM y Administrators. La UI no recibe la contraseña PostgreSQL.
- Claves Argon2id, tokens aleatorios de 256 bits almacenados como SHA-256 en PostgreSQL; expiran tras 8 horas, viven en sessionStorage y se invalidan al cerrar sesión. La instalación solo crea administrador si no existe ningún usuario.
- Un rol protegido Administrador recibe todos los permisos. Roles personalizados y usuarios pueden gestionarse desde la UI. La desactivación y cambio de contraseña invalidan sesiones. No se puede desactivar el último administrador.
- Auditoría de altas, modificaciones, bajas, login, restauraciones solicitadas y respaldos. Es un registro operativo, todavía no un registro a prueba de administradores con acceso directo a PostgreSQL.

## Desarrollo con PostgreSQL

Requisitos: Node 24, npm, PostgreSQL 15+ con `pg_dump`/`pg_restore` en PATH. Cree una base temporal `iglesia` y usuario propio, sin datos reales. Configure `DATABASE_URL` y `IGLESIA_DATA_DIR`; nunca incorpore el secreto al repositorio.

```bash
npm ci
export DATABASE_URL='postgres://usuario:clave@127.0.0.1:5432/iglesia'
export IGLESIA_DATA_DIR="$PWD/.local-data"
npm run migrate -w api
npm run dev -w api
# En otra terminal: npm run dev -w web
```

Abra `http://127.0.0.1:5173`, complete la configuración inicial y cree el administrador. La contraseña debe tener al menos 12 caracteres. Luego ejecute `node tests/smoke.mjs` **solo con una base temporal vacía** y API arrancada; crea y elimina registros de prueba y genera respaldo. Para verificar recuperación, cree otra base vacía, restaure allí el `.dump` con `pg_restore --no-owner --exit-on-error --dbname=<URL_DE_LA_BASE_NUEVA> <ARCHIVO.dump>` y ejecute `RESTORED_DATABASE_URL=<URL_DE_LA_BASE_NUEVA> node tests/verify-restored.mjs`. El cliente Tauri requiere Rust y `npm install` en `desktop`; ejecute `npm run dev` allí con Vite iniciado.

## Windows: construir instalador único

Requisitos de compilación: Windows x64, Node 24, Rust estable con target MSVC, Visual Studio C++ Build Tools, WebView2, Inno Setup 6. Reúna binarios Windows x64 confiables de PostgreSQL (distribución ZIP con `bin` y dependencias), Node y WinSW, **compruebe sus hashes oficiales y licencias** y colóquelos en `installer/payload/postgres`, `node/node.exe`, `winsw/service.exe`. Ejecute `powershell -File installer/build-windows.ps1`. Produce `installer/Output/GestionIglesiaPro-Setup-0.1.0.exe` si el build y el empaquetado terminan correctamente. No se incluyen binarios de terceros en el repositorio.

Ejecute el instalador como administrador una sola vez. Durante la instalación genera una clave aleatoria PostgreSQL, crea base y servicios, aplica migraciones e instala accesos directos. El uso cotidiano se realiza sin elevación. En una actualización, el código detiene el servicio, conserva `ProgramData`, aplica migraciones, registra nuevamente el servicio y lo arranca. **La instalación nueva y la restauración pasaron en Windows Server 2022; aún falta probar actualización y desinstalación en un equipo Windows existente.** Antes de actualizar datos reales, haga respaldo externo. La desinstalación conserva `ProgramData` deliberadamente.

## Operación y recuperación

El administrador crea usuarios y asigna roles. Secretaría edita miembros; Consulta solo lee. Una lista vacía después de instalar puede indicar base recién creada: revise la instalación antes de introducir datos. El registro de servicio se ubica junto a `ProgramData\GestionIglesiaPro\service.exe`; errores de la API se dirigen al registro del servicio.

Respaldos: botón **Crear respaldo**; `pg_dump --format=custom` crea archivo `.dump`, `pg_restore --list` verifica la estructura y se almacena SHA-256. Copie `.dump` y `.sha256` a una unidad externa protegida. La comprobación de estructura no sustituye una restauración de ensayo. El resultado de restauraciones se anota además en `restore-audit.jsonl` fuera de la base, ya que la restauración sustituye las filas de auditoría almacenadas en ella.

Restauración: seleccione respaldo y **Preparar restauración**; se emite un código válido por 5 minutos. Abra PowerShell elevado y ejecute:

```powershell
& 'C:\Program Files\GestionIglesiaPro\scripts\restore.ps1' -Name 'respaldo-AAAA-MM-DDTHH-MM-SS-1234abcd.dump' -Code '<código mostrado>' -AppDir 'C:\Program Files\GestionIglesiaPro'
```

El script verifica el SHA-256, inspecciona el dump, crea un respaldo previo, detiene API, restaura con `--exit-on-error`, reaplica migraciones y reinicia API. Si falla la restauración, deja el servicio detenido y conserva el respaldo previo. No cierre la PC durante esta operación. La contraseña del PostgreSQL local se mantiene en archivo solo administradores/SYSTEM; para la restauración se requiere elevación.

## Alcance y continuación

No se migran hojas, registros ni macros del antiguo prototipo Excel/VBA. [Fases siguientes](docs/FASES.md), [WhatsApp](docs/WHATSAPP.md) y [verificación](docs/VERIFICACION.md) describen pendientes y riesgos.

### Ejecutor Windows en GitHub Actions

El flujo `.github/workflows/windows-installer.yml` compila el instalador en `windows-2022` al actualizar `main` y también se puede iniciar manualmente desde **Actions → Construir instalador Windows → Run workflow**. Usa archivos alojados en los sitios oficiales de EDB y WinSW, calcula sus hashes en el ejecutor y comprueba que el segundo download coincida; esta comprobación detecta cambios entre descargas, pero **no constituye una verificación independiente del origen**. Al iniciarlo manualmente puede indicar los SHA-256 obtenidos por otro canal para comprobar el origen además de la integridad. Node se comprueba contra el manifiesto oficial. Si termina correctamente, descargue el artefacto `GestionIglesiaPro-Setup-Windows-x64` en la página de la ejecución; allí estará `GestionIglesiaPro-Setup-0.1.0.exe`. El flujo no publica una versión ni instala el programa en su PC. Verifique el resultado de la ejecución y pruebe instalación, alta del administrador y restauración en una PC Windows de ensayo antes de usar datos reales.
