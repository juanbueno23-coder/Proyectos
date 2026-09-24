param(
 [Parameter(Mandatory=$true)][string]$PostgresZipUrl,
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$PostgresSha256,
 [Parameter(Mandatory=$true)][string]$WinSWUrl,
 [Parameter(Mandatory=$true)][ValidatePattern('^[a-fA-F0-9]{64}$')][string]$WinSWSha256,
 [string]$NodeVersion='v24.21.0'
)
$ErrorActionPreference='Stop';$ProgressPreference='SilentlyContinue'
$dest=Join-Path $PSScriptRoot 'payload';$temp=Join-Path $env:TEMP ('iglesia-payload-'+[guid]::NewGuid().ToString('N'))
New-Item -ItemType Directory -Force $temp,(Join-Path $dest 'postgres'),(Join-Path $dest 'winsw'),(Join-Path $dest 'node') | Out-Null
function FetchChecked([string]$url,[string]$output,[string]$expected){Invoke-WebRequest -Uri $url -OutFile $output -UseBasicParsing; $actual=(Get-FileHash -Algorithm SHA256 $output).Hash;if($actual -ine $expected){Remove-Item $output -Force;throw "SHA-256 incorrecto en $url"}}
try{
 if($PostgresZipUrl -notmatch '^https://(www\.)?enterprisedb\.com/|^https://get\.enterprisedb\.com/'){throw 'URL PostgreSQL debe provenir de EnterpriseDB'}
 if($WinSWUrl -notmatch '^https://github\.com/winsw/winsw/releases/download/'){throw 'URL WinSW debe provenir del repositorio oficial'}
 $pgZip=Join-Path $temp 'postgres.zip';FetchChecked $PostgresZipUrl $pgZip $PostgresSha256
 $unpack=Join-Path $temp 'postgres-unpacked';Expand-Archive $pgZip $unpack
 $bin=Get-ChildItem $unpack -Directory -Recurse | Where-Object { $_.Name -eq 'bin' -and (Test-Path (Join-Path $_.FullName 'initdb.exe')) } | Select-Object -First 1
 if(!$bin){throw 'ZIP PostgreSQL sin bin/initdb.exe'}
 Copy-Item (Join-Path $bin.Parent.FullName '*') (Join-Path $dest 'postgres') -Recurse -Force
 FetchChecked $WinSWUrl (Join-Path $dest 'winsw/service.exe') $WinSWSha256
 $nodeName="node-$NodeVersion-win-x64.zip";$nodeBase="https://nodejs.org/dist/$NodeVersion"
 $manifest=Invoke-RestMethod "$nodeBase/SHASUMS256.txt"
 $line=($manifest -split "`n" | Where-Object {$_ -match [regex]::Escape($nodeName)+'$'} | Select-Object -First 1)
 if(!$line -or $line -notmatch '^([a-f0-9]{64})\s+'){throw 'No se encontró checksum de Node en su manifest oficial'}
 $nodeZip=Join-Path $temp $nodeName;FetchChecked "$nodeBase/$nodeName" $nodeZip $Matches[1]
 $nodeOut=Join-Path $temp 'node';Expand-Archive $nodeZip $nodeOut
 $nodeExe=Get-ChildItem $nodeOut -Recurse -File -Filter node.exe | Select-Object -First 1
 if(!$nodeExe){throw 'Falta node.exe en el ZIP'}
 Copy-Item $nodeExe.FullName (Join-Path $dest 'node/node.exe') -Force
 Write-Host 'Binarios Windows descargados con SHA-256 verificado en installer/payload.'
}finally{Remove-Item $temp -Recurse -Force -ErrorAction SilentlyContinue}
