param([Parameter(Mandatory=$true)][string]$AppDir)
$ErrorActionPreference='Stop'
trap {
  $safe=($_.Exception.Message -replace 'postgres(?:ql)?://[^\s]+','[URL DE BASE OMITIDA]')
  $diagnostic=Join-Path $env:ProgramData 'GestionIglesiaPro\install-error.log'
  try {Add-Content -Path $diagnostic -Value "$(Get-Date -Format o) línea $($_.InvocationInfo.ScriptLineNumber): $safe"} catch {}
  exit 1
}
$data=Join-Path $env:ProgramData 'GestionIglesiaPro'
$pgData=Join-Path $data 'postgres'
$pgBin=Join-Path $AppDir 'postgres\bin'
$service=Join-Path $data 'service.exe'
$node=Join-Path $AppDir 'runtime\node.exe'
$pwdFile=Join-Path $data 'pg-password.tmp'
$config=Join-Path $data 'database-url.txt'
New-Item -ItemType Directory -Force $data,(Join-Path $data 'backups') | Out-Null
$userSid=[Security.Principal.WindowsIdentity]::GetCurrent().User.Value
icacls $data /inheritance:r /grant:r '*S-1-5-18:(OI)(CI)F' '*S-1-5-32-544:(OI)(CI)F' "*$($userSid):(OI)(CI)F" | Out-Null
if($LASTEXITCODE -ne 0){throw 'No se pudieron proteger los datos locales'}
if(!(Test-Path $pgData)){
  $bytes=New-Object byte[] 32
  $rng=[System.Security.Cryptography.RandomNumberGenerator]::Create()
  try {$rng.GetBytes($bytes)} finally {$rng.Dispose()}
  $plain=[BitConverter]::ToString($bytes).Replace('-','').ToLowerInvariant()
  [System.IO.File]::WriteAllText($pwdFile,$plain)
  try {
    & "$pgBin\initdb.exe" -D $pgData -U iglesia -A scram-sha-256 --pwfile=$pwdFile --encoding=UTF8 --locale=C 2>&1 | Out-File (Join-Path $data 'initdb.log')
    if($LASTEXITCODE -ne 0){throw 'initdb falló'}
    Add-Content (Join-Path $pgData 'postgresql.conf') "`nlisten_addresses = '127.0.0.1'`nport = 54339`n"
    & "$pgBin\pg_ctl.exe" register -N GestionIglesiaPostgres -D $pgData -S auto
    if($LASTEXITCODE -ne 0){throw 'No se pudo registrar PostgreSQL'}
    Start-Service GestionIglesiaPostgres
    $env:PGPASSWORD=$plain
    & "$pgBin\createdb.exe" -h 127.0.0.1 -p 54339 -U iglesia iglesia
    if($LASTEXITCODE -ne 0){throw 'No se pudo crear la base de datos'}
    $url='postgres://iglesia:'+ $plain +'@127.0.0.1:54339/iglesia'
    [System.IO.File]::WriteAllText($config,$url)
  } finally {Remove-Item $pwdFile -ErrorAction SilentlyContinue;Remove-Item Env:\PGPASSWORD -ErrorAction SilentlyContinue}
}
if(!(Test-Path $config)){throw 'Falta configuración existente; no se generará una base vacía sobre datos previos'}
$url=[System.IO.File]::ReadAllText($config).Trim()
$env:DATABASE_URL=$url
$env:IGLESIA_DATA_DIR=$data
if(Get-Service GestionIglesiaAPI -ErrorAction SilentlyContinue){
  $before=Join-Path (Join-Path $data 'backups') ('previo-actualizacion-'+(Get-Date -Format 'yyyyMMdd-HHmmss')+'.dump')
  & "$pgBin\pg_dump.exe" --format=custom --file=$before $url
  if($LASTEXITCODE -ne 0){throw 'Fallo el respaldo antes de actualizar; instalación cancelada'}
  (Get-FileHash -Algorithm SHA256 $before).Hash.ToLowerInvariant() | Set-Content "$before.sha256"
  & $service stop
  & $service uninstall
  if($LASTEXITCODE -ne 0){throw 'No se pudo retirar el servicio anterior'}
}
Copy-Item (Join-Path $AppDir 'service\service.exe') $service -Force
Push-Location (Join-Path $AppDir 'api')
try{& $node (Join-Path $AppDir 'api\dist\migrate.js');if($LASTEXITCODE -ne 0){throw 'Migración falló'}}finally{Pop-Location}
$xml=[System.IO.File]::ReadAllText((Join-Path $AppDir 'service\service.xml')).Replace('%DATABASE_URL%',[System.Security.SecurityElement]::Escape($url)).Replace('%BASE%',[System.Security.SecurityElement]::Escape($AppDir)).Replace('%DATA%',[System.Security.SecurityElement]::Escape($data))
[System.IO.File]::WriteAllText((Join-Path $data 'service.xml'),$xml)
& $service install;if($LASTEXITCODE -ne 0){throw 'No se pudo instalar el servicio'}
& $service start;if($LASTEXITCODE -ne 0){throw 'No se pudo iniciar el servicio'}
$ready=$false
for($attempt=0;$attempt -lt 30;$attempt++){
  try {
    $response=Invoke-RestMethod 'http://127.0.0.1:4317/health' -TimeoutSec 2
    if($response.ok){$ready=$true;break}
  }catch{}
  Start-Sleep -Seconds 1
}
if(!$ready){throw 'El servicio API se registró pero no respondió en 30 segundos; revise service.err.log'}
