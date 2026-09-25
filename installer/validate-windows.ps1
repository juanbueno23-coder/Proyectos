# Ejecutar solo en una VM Windows x64 descartable, PowerShell elevado y Node instalado.
param([Parameter(Mandatory=$true)][string]$InstallerPath,[switch]$DisposableVM)
$ErrorActionPreference='Stop'
if(-not $DisposableVM){throw 'Requiere -DisposableVM: crea un administrador de prueba y restaura datos.'}
$root=Resolve-Path (Join-Path $PSScriptRoot '..')
$appDir=Join-Path $env:ProgramFiles 'GestionIglesiaPro'
$data=Join-Path $env:ProgramData 'GestionIglesiaPro'
if(Test-Path $data){throw 'La VM ya contiene datos. Use una VM nueva para evitar sobrescrituras.'}
$installer=Resolve-Path $InstallerPath
$logDir=if($env:RUNNER_TEMP){$env:RUNNER_TEMP}else{$env:TEMP}
$log=Join-Path $logDir 'iglesia-installer.log'
$p=Start-Process -FilePath $installer -ArgumentList @('/VERYSILENT','/SUPPRESSMSGBOXES','/NORESTART',('/LOG='+ $log)) -Wait -PassThru
if($p.ExitCode -ne 0){throw "Instalador falló ($($p.ExitCode)); revise el registro en TEMP"}
$services=@('GestionIglesiaPostgres','GestionIglesiaAPI')
foreach($s in $services){
  $current=$null
  for($attempt=0;$attempt -lt 20;$attempt++){
    $current=Get-Service $s -ErrorAction SilentlyContinue
    if($current -and $current.Status -eq 'Running'){break}
    Start-Sleep -Seconds 1
  }
  if(!$current -or $current.Status -ne 'Running'){
    Write-Host "Diagnóstico: directorio de aplicación=$(Test-Path $appDir), directorio de datos=$(Test-Path $data), registro=$(Test-Path $log)"
    foreach($name in @('install-error.log','initdb.log')){
      $detail=Join-Path $data $name
      if(Test-Path $detail){Write-Host "Registro $name";Get-Content $detail -Tail 30}
    }
    if(Test-Path $log){Get-Content $log -Tail 90}
    throw "Servicio $s no iniciado"
  }
}
$base='http://127.0.0.1:4317'
if(-not (Invoke-RestMethod "$base/health").ok){throw 'API sin salud'}
if((Invoke-RestMethod "$base/setup/status").initialized){throw 'La instalación no está vacía'}
Push-Location $root
try{
  npm ci
  $env:IGLESIA_SMOKE_PASSWORD=[guid]::NewGuid().ToString('N')+[guid]::NewGuid().ToString('N')+'Aa1!'
  & node (Join-Path $root 'tests/smoke.mjs')
  if($LASTEXITCODE -ne 0){throw 'Prueba de humo falló'}
}finally{Pop-Location}
$backup=Get-ChildItem (Join-Path $data 'backups') -Filter 'respaldo-*.dump' | Sort-Object LastWriteTime -Descending | Select-Object -First 1
if(!$backup){throw 'No se generó respaldo'}
$login=Invoke-RestMethod "$base/auth/login" -Method Post -ContentType 'application/json' -Body (@{username='prueba_admin';password=$env:IGLESIA_SMOKE_PASSWORD} | ConvertTo-Json -Compress)
$headers=@{Authorization="Bearer $($login.token)"}
$request=Invoke-RestMethod "$base/api/backups/$($backup.Name)/restore-request" -Method Post -Headers $headers
& (Join-Path $appDir 'scripts/restore.ps1') -Name $backup.Name -Code $request.code -AppDir $appDir
if((Get-Service 'GestionIglesiaAPI').Status -ne 'Running'){throw 'API no volvió a iniciar'}
$env:RESTORED_DATABASE_URL=(Get-Content (Join-Path $data 'database-url.txt') -Raw).Trim()
Push-Location $root
try{& node (Join-Path $root 'tests/verify-restored.mjs');if($LASTEXITCODE -ne 0){throw 'Datos no recuperados'}}finally{Pop-Location}
if(!(Select-String -Path (Join-Path $data 'restore-audit.jsonl') -Pattern 'restore_completed' -Quiet)){throw 'Falta auditoría externa de restauración'}
Write-Host 'VM validada: instalación, servicios, API, CRUD, permisos, respaldo, restauración y auditoría.'
Remove-Item Env:\IGLESIA_SMOKE_PASSWORD -ErrorAction SilentlyContinue
