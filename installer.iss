#ifndef AppVersion
  #define AppVersion "1.0.0"
#endif

[Setup]
AppId={{2A52E47E-BF07-4DFE-9DB5-613592C13201}
AppName=Self-Check-In
AppVersion={#AppVersion}
AppPublisher=Andrew van der Westhuizen
VersionInfoCompany=Andrew van der Westhuizen
VersionInfoCopyright=Copyright (c) 2026 Andrew van der Westhuizen
VersionInfoVersion={#AppVersion}
AppMutex=Local\ThoughtCapture
DefaultDirName={localappdata}\Programs\Self-Check-In
DefaultGroupName=Self-Check-In
UsePreviousGroup=no
PrivilegesRequired=lowest
ArchitecturesAllowed=x64compatible
ArchitecturesInstallIn64BitMode=x64compatible
MinVersion=10.0
OutputDir=dist
OutputBaseFilename=Self-Check-In-{#AppVersion}-windows-x64-setup
SetupIconFile=check-in.ico
UninstallDisplayIcon={app}\Self-Check-In.exe
Compression=lzma2
SolidCompression=yes
WizardStyle=modern
CloseApplications=no
CloseApplicationsFilter=Self-Check-In.exe,ThoughtCapture.exe
RestartApplications=no
DisableProgramGroupPage=yes

[Tasks]
Name: "startup"; Description: "Start Self-Check-In when I sign in"; Flags: unchecked

[InstallDelete]
Type: files; Name: "{app}\ThoughtCapture.exe"
Type: files; Name: "{userprograms}\Thought Capture\Thought Capture.lnk"
Type: dirifempty; Name: "{userprograms}\Thought Capture"

[Files]
Source: "dist\Self-Check-In.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\build-info.json"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\AutoHotkey-license.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\LICENSE"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\ICON-LICENSE.txt"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\THIRD-PARTY.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\README.md"; DestDir: "{app}"; Flags: ignoreversion
Source: "dist\journal.ahk"; DestDir: "{app}\source"; Flags: ignoreversion
Source: "dist\journal-core.ahk"; DestDir: "{app}\source"; Flags: ignoreversion
Source: "dist\check-in.ico"; DestDir: "{app}\source"; Flags: ignoreversion
Source: "dist\check-in.svg"; DestDir: "{app}\source"; Flags: ignoreversion

[Icons]
Name: "{group}\Self-Check-In"; Filename: "{app}\Self-Check-In.exe"

[Registry]
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueName: "ThoughtCapture"; Flags: deletevalue
Root: HKCU; Subkey: "Software\Microsoft\Windows\CurrentVersion\Run"; ValueType: string; ValueName: "Self-Check-In"; ValueData: """{app}\Self-Check-In.exe"""; Tasks: startup; Flags: uninsdeletevalue

[Run]
Filename: "{app}\Self-Check-In.exe"; Description: "Launch Self-Check-In"; Flags: nowait postinstall skipifsilent

[UninstallRun]
Filename: "{sys}\reg.exe"; Parameters: "delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v ThoughtCapture /f"; Flags: runhidden; RunOnceId: "RemoveThoughtCaptureStartup"
Filename: "{sys}\reg.exe"; Parameters: "delete HKCU\Software\Microsoft\Windows\CurrentVersion\Run /v Self-Check-In /f"; Flags: runhidden; RunOnceId: "RemoveSelfCheckInStartup"

[Code]
procedure InitializeWizard();
var
  ExistingStartup: String;
begin
  if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'Self-Check-In', ExistingStartup) and (ExistingStartup <> '') then
    WizardSelectTasks('startup')
  else if RegQueryStringValue(HKCU, 'Software\Microsoft\Windows\CurrentVersion\Run', 'ThoughtCapture', ExistingStartup) and (ExistingStartup <> '') then
    WizardSelectTasks('startup');
end;