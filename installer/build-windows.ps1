$ErrorActionPreference='Stop'
$root=Resolve-Path (Join-Path $PSScriptRoot '..')
$payload=Join-Path $PSScriptRoot 'payload'
$required=@('postgres\bin\initdb.exe','postgres\bin\pg_ctl.exe','postgres\bin\pg_dump.exe','postgres\bin\pg_restore.exe','postgres\bin\psql.exe','postgres\bin\createdb.exe','node\node.exe','winsw\service.exe')
foreach($item in $required){if(!(Test-Path (Join-Path $payload $item))){throw "Falta $item en installer/payload"}}
Push-Location $root
try{
  npm ci
  npm run typecheck
  npm test
  npm run build
  npm ci --omit=dev
  Push-Location (Join-Path $root 'desktop')
  try{npm install --no-audit --no-fund; npm run build}finally{Pop-Location}
  New-Item -ItemType Directory -Force (Join-Path $payload 'app') | Out-Null
  Copy-Item (Join-Path $root 'desktop\src-tauri\target\release\gestion-iglesia-pro.exe') (Join-Path $payload 'app\gestion-iglesia-pro.exe') -Force
  $iscc=Get-Command ISCC.exe -ErrorAction Stop
  & $iscc.Source (Join-Path $PSScriptRoot 'gestion-iglesia.iss')
  if($LASTEXITCODE -ne 0){throw 'ISCC falló'}
}finally{Pop-Location}
