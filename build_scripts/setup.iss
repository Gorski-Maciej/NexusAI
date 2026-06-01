; =============================================================================
;  NexusAI_Setup.iss — Inno Setup Script for NexusAI
; =============================================================================
;  This script creates a Windows installer that:
;    1. Installs the PyInstaller-bundled NexusAI .exe to %ProgramFiles%\NexusAI
;    2. Creates Desktop and Start Menu shortcuts
;    3. Adds uninstaller entry in "Programs and Features"
;    4. Stores runtime data (models, databases) in %APPDATA%\NexusAI
;
;  Inno Setup: https://jrsoftware.org/isdl.php
; =============================================================================

#define MyAppName "NexusAI"
#define MyAppVersion "1.0.0"
#define MyAppPublisher "NexusAI Team"
#define MyAppURL "https://nexusai.app"
#define MyAppExeName "NexusAI.exe"

[Setup]
; NOTE: The value of AppId uniquely identifies this application. Do not use the
; same AppId value in installers for other applications.
AppId={{B7A9F2C1-3D4E-5F6A-7B8C-9D0E1F2A3B4C}
AppName={#MyAppName}
AppVersion={#MyAppVersion}
AppPublisher={#MyAppPublisher}
AppPublisherURL={#MyAppURL}
AppSupportURL={#MyAppURL}
AppUpdatesURL={#MyAppURL}
DefaultDirName={autopf}\{#MyAppName}
DefaultGroupName={#MyAppName}
AllowNoIcons=yes
; Allow non-admin install — app stores data in %APPDATA%
PrivilegesRequired=lowest
PrivilegesRequiredOverridesAllowed=dialog
; Output
OutputDir=..\dist
OutputBaseFilename=NexusAI_Setup
; Icon
SetupIconFile=..\assets\icon.ico
; Compression
Compression=lzma2/ultra
SolidCompression=yes
; Windows versions supported
MinVersion=10.0
; Do not restart after install
UninstallRestartComputer=no
; Show language selection
ShowLanguageDialog=yes

[Languages]
Name: "english"; MessagesFile: "compiler:Default.isl"
Name: "polish"; MessagesFile: "compiler:Languages\Polish.isl"

[Messages]
English.WelcomeLabel1=Welcome to NexusAI Setup
English.WelcomeLabel2=This will install NexusAI %1 on your computer.%n%nNexusAI is an AI-powered accounting system that runs entirely locally.%n%nAI models will be downloaded on first launch (approx. 3 GB). You will need an internet connection for the initial setup.
Polish.WelcomeLabel1=Witamy w instalatorze NexusAI
Polish.WelcomeLabel2=Ten program zainstaluje NexusAI %1 na Twoim komputerze.%n%nNexusAI to system księgowy z AI działający w całości lokalnie.%n%nModele AI zostaną pobrane przy pierwszym uruchomieniu (ok. 3 GB). Do inicjalizacji potrzebne jest połączenie z internetem.
English.DiskSpaceMBLabel=At least %1 MB of free disk space is required for the application.%n%nAdditional %2 MB is recommended for AI model files (downloaded on first launch).
Polish.DiskSpaceMBLabel=Wymagane jest co najmniej %1 MB wolnego miejsca dla aplikacji.%n%nDodatkowe %2 MB jest zalecane dla plików modeli AI (pobieranych przy pierwszym uruchomieniu).
English.FinishedLabel=Setup has finished installing NexusAI.%n%nOn first launch, AI models will be downloaded automatically. This may take a few minutes.
Polish.FinishedLabel=Instalacja NexusAI została zakończona.%n%nPrzy pierwszym uruchomieniu modele AI zostaną pobrane automatycznie. Może to potrwać kilka minut.

[Tasks]
Name: "desktopicon"; Description: "Create a &desktop shortcut"; GroupDescription: "Additional shortcuts:"
Name: "startup"; Description: "Launch NexusAI when Windows starts (recommended for background updates)"; GroupDescription: "Startup options:"; Flags: unchecked

[Files]
; Main application bundle (PyInstaller output)
Source: "..\dist\NexusAI\NexusAI.exe"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\dist\NexusAI\*"; DestDir: "{app}"; Flags: ignoreversion recursesubdirs createallsubdirs

; Configuration files
Source: "..\config\*.env"; DestDir: "{app}\config"; Flags: ignoreversion
Source: "..\config\models_manifest.json"; DestDir: "{app}\config"; Flags: ignoreversion

; Alembic migrations
Source: "..\alembic.ini"; DestDir: "{app}"; Flags: ignoreversion
Source: "..\migrations\*"; DestDir: "{app}\migrations"; Flags: ignoreversion recursesubdirs

; Placeholder models directory
Source: "..\models\.gitkeep"; DestDir: "{app}\models"; Flags: ignoreversion skipifsourcedoesntexist

; README
Source: "..\README.md"; DestDir: "{app}"; Flags: ignoreversion isreadme

; NOTE: Don't use "Flags: ignoreversion" on any shared system files

[Dirs]
; Create runtime data directories in %APPDATA%
Name: "{userappdata}\NexusAI"; Permissions: users-modify
Name: "{userappdata}\NexusAI\models"; Permissions: users-modify
Name: "{userappdata}\NexusAI\app_data"; Permissions: users-modify
Name: "{userappdata}\NexusAI\app_data\uploads"; Permissions: users-modify
Name: "{userappdata}\NexusAI\logs"; Permissions: users-modify

[Icons]
Name: "{group}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"
Name: "{group}\{#MyAppName} (CLI)"; Filename: "{app}\NexusAI_CLI.exe"; WorkingDir: "{app}"
Name: "{group}\Uninstall {#MyAppName}"; Filename: "{uninstallexe}"
Name: "{autodesktop}\{#MyAppName}"; Filename: "{app}\{#MyAppExeName}"; WorkingDir: "{app}"; Tasks: desktopicon

[Run]
; Launch the app after installation (with checkbox)
Filename: "{app}\{#MyAppExeName}"; Description: "Launch NexusAI"; Flags: postinstall nowait skipifsilent shellexec; WorkingDir: "{app}"

[UninstallRun]
; Clean up runtime data (optional)
Filename: "{cmd}"; Parameters: "/c rmdir /s /q ""{userappdata}\NexusAI"""; Flags: runhidden

[Code]
{ Custom page to show disk space requirements with model files }
function InitializeSetup: Boolean;
begin
  Result := True;
end;

procedure CurStepChanged(CurStep: TSetupStep);
begin
  if CurStep = ssPostInstall then
  begin
    { Create the .seeded marker to avoid auto-seed on first run }
    { The first-run model download check will happen when the app starts }
  end;
end;
