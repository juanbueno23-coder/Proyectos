#define AppName "Gestión Iglesia Pro"
#define AppVersion "0.1.0"
[Setup]
AppId={{3B96D92D-AC14-4A95-B21F-0D9B8B735C20}
AppName={#AppName}
AppVersion={#AppVersion}
DefaultDirName={autopf}\GestionIglesiaPro
ArchitecturesAllowed=x64
ArchitecturesInstallIn64BitMode=x64
DefaultGroupName=Gestión Iglesia Pro
PrivilegesRequired=admin
OutputBaseFilename=GestionIglesiaPro-Setup-0.1.0
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
[Files]
Source: "payload\app\gestion-iglesia-pro.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "payload\node\node.exe"; DestDir: "{app}\runtime"; Flags: ignoreversion
Source: "payload\winsw\service.exe"; DestDir: "{app}\service"; Flags: ignoreversion
Source: "payload\postgres\*"; DestDir: "{app}\postgres"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\api\dist\*"; DestDir: "{app}\api\dist"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\api\package.json"; DestDir: "{app}\api"; Flags: ignoreversion
Source: "..\node_modules\*"; DestDir: "{app}\api\node_modules"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "..\api\migrations\*"; DestDir: "{app}\api\migrations"; Flags: recursesubdirs createallsubdirs ignoreversion
Source: "service.xml"; DestDir: "{app}\service"; Flags: ignoreversion
Source: "install.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
Source: "restore.ps1"; DestDir: "{app}\scripts"; Flags: ignoreversion
[Icons]
Name: "{group}\Gestión Iglesia Pro"; Filename: "{app}\gestion-iglesia-pro.exe"
Name: "{autodesktop}\Gestión Iglesia Pro"; Filename: "{app}\gestion-iglesia-pro.exe"
[Code]
function PrepareToInstall(var NeedsRestart: Boolean): String;
var ResultCode: Integer;
begin
  Result := '';
  Exec('sc.exe', 'stop GestionIglesiaAPI', '', SW_HIDE, ewWaitUntilTerminated, ResultCode);
end;
procedure CurStepChanged(CurStep: TSetupStep);
var ResultCode: Integer;
begin
  if CurStep = ssPostInstall then begin
    if not Exec('powershell.exe', '-NoProfile -ExecutionPolicy Bypass -File "' + ExpandConstant('{app}\scripts\install.ps1') + '" -AppDir "' + ExpandConstant('{app}') + '"', '', SW_HIDE, ewWaitUntilTerminated, ResultCode) or (ResultCode <> 0) then
      RaiseException('Instalación de servicios o migración fallida. Consulte el registro y conserve ProgramData.');
  end;
end;
[UninstallRun]
Filename: "{commonappdata}\GestionIglesiaPro\service.exe"; Parameters: "stop"; Flags: runhidden
Filename: "{commonappdata}\GestionIglesiaPro\service.exe"; Parameters: "uninstall"; Flags: runhidden
; Base de datos y respaldos en ProgramData: el desinstalador NO los borra.
