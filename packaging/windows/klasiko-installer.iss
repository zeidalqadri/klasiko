; Klasiko PDF Converter - Inno Setup Installer Script
; Creates a professional Windows installer with file associations and PATH integration
;
; Requirements:
;   - Inno Setup 6.0 or higher (https://jrsoftware.org/isinfo.php)
;   - Built klasiko.exe in dist/ directory
;
; Build with: iscc klasiko-installer.iss
; Or use: .\packaging\windows\create-installer.ps1

#define MyAppName "Klasiko PDF Converter"
#define MyAppVersion "2.1.1"
#define MyAppPublisher "Klasiko"
#define MyAppURL "https://github.com/yourusername/klasiko"
#define MyAppExeName "klasiko.exe"
#define MyAppGUIExeName "klasiko-gui.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application.
; Do not use the same AppId value in installers for other applications.
AppId={{A7B8C9D0-E1F2-3456-7890-ABCDEF123456}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\Klasiko
DefaultGroupName=Klasiko PDF Converter
; Uncomment the following line to run in non administrative install mode (install for current user only.)
;PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
OutputDir=..\..\dist
OutputBaseFilename=Klasiko-{#MyAppVersion}-Windows-Setup
SetupIconFile=klasiko.ico
Compression=lzma2/max
SolidCompression=yes
WizardStyle=modern
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
UninstallDisplayIcon={app}\{#MyAppExeName}
UninstallDisplayName={#MyAppName} {#MyAppVersion}
VersionInfoVersion={#MyAppVersion}
VersionInfoCompany={#MyAppPublisher}
VersionInfoDescription={#MyAppName} Setup
VersionInfoProductName={#MyAppName}
VersionInfoProductVersion={#MyAppVersion}

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"

[Tasks]
Name: "desktopicon"; Description: "{cm:CreateDesktopIcon}"; GroupDescription: "{cm:AdditionalIcons}"; Flags: unchecked
Name: "addtopath"; Description: "Add to PATH environment variable (recommended)"; GroupDescription: "System Integration:"; Flags: checkedonce
Name: "associatemd"; Description: "Associate .md files with Klasiko (right-click 'Convert to PDF')"; GroupDescription: "File Associations:"; Flags: unchecked

[Files]
Source: "dist\{#MyAppExeName}"; DestDir: "{app}"; Flags: ignoreversion
; Uncomment if you build a separate GUI executable
; Source: "..\..\dist\{#MyAppGUIExeName}"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\..\CHANGELOG-v2.1.md"; DestDir: "{app}"; Flags: ignoreversion isreadme
Source: "..\..\THEME-GUIDE.md"; DestDir: "{app}"; Flags: ignoreversion
; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Icons]
Name: "{group}\Klasiko PDF Converter (Command Line)"; Filename: "cmd.exe"; Parameters: "/K cd /d ""{userdesktop}"" && ""{app}\{#MyAppExeName}"" --help"; IconFilename: "{app}\{#MyAppExeName}"; Comment: "Open Klasiko in command prompt"
; Uncomment if you have a GUI version
; Name: "{group}\Klasiko PDF Converter (GUI)"; Filename: "{app}\{#MyAppGUIExeName}"; IconFilename: "{app}\{#MyAppGUIExeName}"; Comment: "Launch Klasiko GUI"
Name: "{group}\{cm:UninstallProgram,{#MyAppName}}"; Filename: "{uninstallexe}"
Name: "{group}\README"; Filename: "{app}\README.md"
Name: "{autodesktop}\Klasiko PDF Converter"; Filename: "cmd.exe"; Parameters: "/K cd /d ""{userdesktop}"" && ""{app}\{#MyAppExeName}"" --help"; IconFilename: "{app}\{#MyAppExeName}"; Tasks: desktopicon; Comment: "Open Klasiko in command prompt"

[Registry]
; Add to PATH environment variable
Root: HKLM; Subkey: "SYSTEM\CurrentControlSet\Control\Session Manager\Environment"; ValueType: expandsz; ValueName: "Path"; ValueData: "{olddata};{app}"; Tasks: addtopath; Check: NeedsAddPath('{app}')

; File association for .md files - Add context menu entry
Root: HKCR; Subkey: ".md\shell\ConvertToPDF"; ValueType: string; ValueData: "Convert to PDF with Klasiko"; Tasks: associatemd
Root: HKCR; Subkey: ".md\shell\ConvertToPDF\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Tasks: associatemd
Root: HKCR; Subkey: ".markdown\shell\ConvertToPDF"; ValueType: string; ValueData: "Convert to PDF with Klasiko"; Tasks: associatemd
Root: HKCR; Subkey: ".markdown\shell\ConvertToPDF\command"; ValueType: string; ValueData: """{app}\{#MyAppExeName}"" ""%1"""; Tasks: associatemd

[Code]
function NeedsAddPath(Param: string): boolean;
var
  OrigPath: string;
  ParamExpanded: string;
begin
  ParamExpanded := ExpandConstant(Param);
  if not RegQueryStringValue(HKEY_LOCAL_MACHINE,
    'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
    'Path', OrigPath)
  then begin
    Result := True;
    exit;
  end;
  Result := Pos(';' + Uppercase(ParamExpanded) + ';', ';' + Uppercase(OrigPath) + ';') = 0;
  if Result = True then
     Result := Pos(';' + Uppercase(ParamExpanded) + '\;', ';' + Uppercase(OrigPath) + ';') = 0;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    // Broadcast environment change message
    if IsTaskSelected('addtopath') then
    begin
      RegQueryStringValue(HKEY_LOCAL_MACHINE,
        'SYSTEM\CurrentControlSet\Control\Session Manager\Environment',
        'Path', '');
    end;
  end;
end;

[Run]
Filename: "cmd.exe"; Parameters: "/K cd /d ""{userdesktop}"" && ""{app}\{#MyAppExeName}"" --help"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}} (Command Line)"; Flags: nowait postinstall skipifsilent
; Uncomment if you have a GUI version
; Filename: "{app}\{#MyAppGUIExeName}"; Description: "{cm:LaunchProgram,{#StringChange(MyAppName, '&', '&&')}} (GUI)"; Flags: nowait postinstall skipifsilent unchecked

[UninstallDelete]
Type: filesandordirs; Name: "{app}"
