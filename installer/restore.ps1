param([Parameter(Mandatory=$true)][string]$Name,[Parameter(Mandatory=$true)][string]$Code,[Parameter(Mandatory=$true)][string]$AppDir)
$ErrorActionPreference='Stop'
$data=Join-Path $env:ProgramData 'GestionIglesiaPro'
if($Name -notmatch '^respaldo-\d{4}-\d{2}-\d{2}T\d{2}-\d{2}-\d{2}-[a-f0-9]{8}\.dump$'){throw 'Nombre inválido'}
$file=Join-Path (Join-Path $data 'backups') $Name
$reqFile=Join-Path $data 'restore-request.json'
if(!(Test-Path $reqFile)){throw 'Solicite primero la restauración desde la aplicación'}
$req=Get-Content $reqFile -Raw | ConvertFrom-Json
$recoveryLog=Join-Path $data 'restore-audit.jsonl'
$hasher=[Security.Cryptography.SHA256]::Create()
try {$hash=[BitConverter]::ToString($hasher.ComputeHash([Text.Encoding]::UTF8.GetBytes($Code))).Replace('-','').ToLowerInvariant()} finally {$hasher.Dispose()}
if($req.name -ne $Name -or $req.code_hash -ne $hash -or [datetime]$req.expires -lt [datetime]::UtcNow){throw 'Solicitud inválida o vencida'}
Remove-Item $reqFile
if(!(Test-Path $file) -or !(Test-Path "$file.sha256")){throw 'Respaldo inexistente'}
$actual=(Get-FileHash -Algorithm SHA256 $file).Hash.ToLowerInvariant()
if($actual -ne (Get-Content "$file.sha256" -Raw).Trim()){throw 'SHA-256 no coincide'}
$pgBin=Join-Path $AppDir 'postgres\bin'
& "$pgBin\pg_restore.exe" --list $file | Out-Null
if($LASTEXITCODE -ne 0){throw 'El archivo no es un respaldo PostgreSQL válido'}
$url=(Get-Content (Join-Path $data 'database-url.txt') -Raw).Trim()
$before=Join-Path (Join-Path $data 'backups') ('previo-restauracion-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.dump')
& "$pgBin\pg_dump.exe" --format=custom --file=$before $url
if($LASTEXITCODE -ne 0){throw 'No se pudo proteger la base actual; cancelado'}
(Get-FileHash -Algorithm SHA256 $before).Hash.ToLowerInvariant() | Set-Content "$before.sha256"
Stop-Service GestionIglesiaAPI -ErrorAction Stop
try{
  & "$pgBin\pg_restore.exe" --clean --if-exists --no-owner --exit-on-error --dbname=$url $file
  if($LASTEXITCODE -ne 0){throw "Restauración falló. Respaldo previo: $before. No se reinicia el servicio para evitar trabajar con datos parciales."}
  $env:DATABASE_URL=$url
  & (Join-Path $AppDir 'runtime\node.exe') (Join-Path $AppDir 'api\dist\migrate.js')
  if($LASTEXITCODE -ne 0){throw 'Migraciones posteriores fallaron; servicio detenido'}
  Start-Service GestionIglesiaAPI
  [pscustomobject]@{time=(Get-Date).ToUniversalTime().ToString('o');action='restore_completed';file=$Name;sha256=$actual;actor=$req.actor} | ConvertTo-Json -Compress | Add-Content -Encoding UTF8 $recoveryLog
  Write-Host 'Restauración completada. Revise miembros y auditoría.'
}catch{
  [pscustomobject]@{time=(Get-Date).ToUniversalTime().ToString('o');action='restore_failed';file=$Name;sha256=$actual;actor=$req.actor;reason=$_.Exception.Message} | ConvertTo-Json -Compress | Add-Content -Encoding UTF8 $recoveryLog
  Write-Error $_;throw
}
