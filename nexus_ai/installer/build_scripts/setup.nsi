; =============================================================================
;  NexusAI_Setup.nsi — NSIS Installer Script
; =============================================================================
;  Nullsoft Scriptable Install System (NSIS) script for NexusAI.
;
;  Features:
;    - Welcome page with license agreement
;    - Custom install directory selection (default: %ProgramFiles%\NexusAI)
;    - Start Menu and Desktop shortcuts
;    - Registry uninstall entry
;    - Runtime data stored in %APPDATA%\NexusAI
;    - Optional launch on Windows startup
;    - Uninstaller support
;
;  To compile:
;    1. Install NSIS from: https://nsis.sourceforge.io/Download
;    2. Right-click this file -> "Compile NSIS Script"
;    3. OR: makensis build_scripts\setup.nsi
; =============================================================================

; ── Header files ─────────────────────────────────────────────────────────────
!include "MUI2.nsh"
!include "FileFunc.nsh"
!include "LogicLib.nsh"

; ── Application metadata ─────────────────────────────────────────────────────
!define PRODUCT_NAME "NexusAI"
!define PRODUCT_VERSION "2.0.0"
!define PRODUCT_PUBLISHER "NexusAI Team"
!define PRODUCT_WEB_SITE "https://nexusai.app"
!define PRODUCT_DIR "$PROGRAMFILES\${PRODUCT_NAME}"
!define PRODUCT_UNINSTALL_KEY "Software\Microsoft\Windows\CurrentVersion\Uninstall\${PRODUCT_NAME}"
!define PRODUCT_STARTMENU_FOLDER "NexusAI"

; ── Installer properties ────────────────────────────────────────────────────
Name "${PRODUCT_NAME} ${PRODUCT_VERSION}"
OutFile "..\dist\NexusAI_Setup_${PRODUCT_VERSION}.exe"
InstallDir "${PRODUCT_DIR}"
InstallDirRegKey HKLM "${PRODUCT_UNINSTALL_KEY}" "InstallLocation"
RequestExecutionLevel admin  ; Requires admin for %ProgramFiles% install
BrandingText "NexusAI Installer"

; ── Compression ──────────────────────────────────────────────────────────────
SetCompressor /SOLID lzma
SetCompressorDictSize 64

; ── Version info ─────────────────────────────────────────────────────────────
VIProductVersion "${PRODUCT_VERSION}.0"
VIAddVersionKey "ProductName" "${PRODUCT_NAME}"
VIAddVersionKey "FileVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "ProductVersion" "${PRODUCT_VERSION}"
VIAddVersionKey "CompanyName" "${PRODUCT_PUBLISHER}"
VIAddVersionKey "LegalCopyright" "© 2026 ${PRODUCT_PUBLISHER}"
VIAddVersionKey "FileDescription" "${PRODUCT_NAME} — AI-Powered Accounting System"

; ── Interface settings ───────────────────────────────────────────────────────
!define MUI_ABORTWARNING
!define MUI_ICON "..\assets\nexus.ico"
!define MUI_UNICON "..\assets\nexus.ico"
!define MUI_WELCOMEPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_TITLE_3LINES
!define MUI_FINISHPAGE_RUN "$INSTDIR\${PRODUCT_NAME}.exe"
!define MUI_FINISHPAGE_RUN_TEXT "Launch ${PRODUCT_NAME}"
!define MUI_FINISHPAGE_SHOWREADME ""
!define MUI_FINISHPAGE_LINK "Visit NexusAI Website"
!define MUI_FINISHPAGE_LINK_LOCATION "${PRODUCT_WEB_SITE}"

; ── Language files ───────────────────────────────────────────────────────────
!insertmacro MUI_LANGUAGE "English"
!insertmacro MUI_LANGUAGE "Polish"

; ── Custom pages ─────────────────────────────────────────────────────────────
!insertmacro MUI_PAGE_WELCOME
!insertmacro MUI_PAGE_LICENSE "..\LICENSE.txt"
; If LICENSE.txt does not exist, create an empty one before compilation
!insertmacro MUI_PAGE_DIRECTORY
!insertmacro MUI_PAGE_COMPONENTS
!insertmacro MUI_PAGE_INSTFILES
!insertmacro MUI_PAGE_FINISH

!insertmacro MUI_UNPAGE_CONFIRM
!insertmacro MUI_UNPAGE_INSTFILES

; ── Reserve files ────────────────────────────────────────────────────────────
ReserveFile "..\assets\nexus.ico"

; ── Sections ─────────────────────────────────────────────────────────────────

Section "NexusAI (required)" SecCore
    SectionIn RO
    SetOutPath "$INSTDIR"

    ; ── Copy main application — Nuitka onefile .exe ──────────────────────
    ; Nuitka kompiluje całość do pojedynczego pliku dist\NexusAI.exe
    File "..\dist\NexusAI.exe"

    ; ── Copy config files ────────────────────────────────────────────────
    SetOutPath "$INSTDIR\config"
    File "..\config\dev.toml"
    File "..\config\prod.toml"
    File "..\config\models_manifest.json"
    File "..\config\version.json"

    ; ── Copy migrations ──────────────────────────────────────────────────
    SetOutPath "$INSTDIR"
    File "..\alembic.ini"
    SetOutPath "$INSTDIR\migrations"
    File /r "..\migrations\*.*"

    ; ── Create runtime data directories ──────────────────────────────────
    CreateDirectory "$APPDATA\${PRODUCT_NAME}"
    CreateDirectory "$APPDATA\${PRODUCT_NAME}\models"
    CreateDirectory "$APPDATA\${PRODUCT_NAME}\app_data"
    CreateDirectory "$APPDATA\${PRODUCT_NAME}\app_data\uploads"
    CreateDirectory "$APPDATA\${PRODUCT_NAME}\logs"

    ; ── Write uninstaller ────────────────────────────────────────────────
    WriteUninstaller "$INSTDIR\Uninstall.exe"

    ; ── Registry: uninstall info ─────────────────────────────────────────
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "DisplayName" "${PRODUCT_NAME}"
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "UninstallString" "$INSTDIR\Uninstall.exe"
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "DisplayIcon" "$INSTDIR\${PRODUCT_NAME}.exe"
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "DisplayVersion" "${PRODUCT_VERSION}"
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "Publisher" "${PRODUCT_PUBLISHER}"
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "URLInfoAbout" "${PRODUCT_WEB_SITE}"
    WriteRegStr HKLM "${PRODUCT_UNINSTALL_KEY}" "InstallLocation" "$INSTDIR"
    WriteRegDWORD HKLM "${PRODUCT_UNINSTALL_KEY}" "NoModify" 1
    WriteRegDWORD HKLM "${PRODUCT_UNINSTALL_KEY}" "NoRepair" 1
    WriteRegDWORD HKLM "${PRODUCT_UNINSTALL_KEY}" "EstimatedSize" 512000  ; ~500 MB

    ; ── Create environment variable for data directory ───────────────────
    WriteRegStr HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" \
        "NEXUSAI_DATA" "$APPDATA\${PRODUCT_NAME}"
SectionEnd

Section "Start Menu Shortcuts" SecShortcuts
    CreateDirectory "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}"
    CreateShortCut "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}\${PRODUCT_NAME}.lnk" \
        "$INSTDIR\${PRODUCT_NAME}.exe" "" "$INSTDIR\${PRODUCT_NAME}.exe" 0
    CreateShortCut "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}\${PRODUCT_NAME} (CLI).lnk" \
        "$INSTDIR\NexusAI_CLI.exe" "" "$INSTDIR\NexusAI_CLI.exe" 0
    CreateShortCut "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}\Uninstall ${PRODUCT_NAME}.lnk" \
        "$INSTDIR\Uninstall.exe" "" "$INSTDIR\Uninstall.exe" 0
SectionEnd

Section "Desktop Shortcut" SecDesktop
    CreateShortCut "$DESKTOP\${PRODUCT_NAME}.lnk" \
        "$INSTDIR\${PRODUCT_NAME}.exe" "" "$INSTDIR\${PRODUCT_NAME}.exe" 0
SectionEnd

Section "Launch on Windows Startup" SecStartup
    CreateShortCut "$SMSTARTUP\${PRODUCT_NAME}.lnk" \
        "$INSTDIR\${PRODUCT_NAME}.exe" "--background" "$INSTDIR\${PRODUCT_NAME}.exe" 0
SectionEnd

; ── Section descriptions ─────────────────────────────────────────────────────
!insertmacro MUI_FUNCTION_DESCRIPTION_BEGIN
    !insertmacro MUI_DESCRIPTION_TEXT ${SecCore} \
        "Core NexusAI application files (required)"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecShortcuts} \
        "Add NexusAI shortcuts to the Start Menu"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecDesktop} \
        "Create a NexusAI shortcut on the Desktop"
    !insertmacro MUI_DESCRIPTION_TEXT ${SecStartup} \
        "Automatically launch NexusAI when Windows starts (for background updates)"
!insertmacro MUI_FUNCTION_DESCRIPTION_END

; ── Language strings ─────────────────────────────────────────────────────────

LangString WelcomeTitle ${LANG_ENGLISH} "Welcome to NexusAI Setup"
LangString WelcomeText ${LANG_ENGLISH} "This wizard will guide you through installing NexusAI $\r$\n$\r$\n\
    NexusAI is an AI-powered accounting system that runs entirely locally.$\r$\n$\r$\n\
    $_CLICK to continue."

LangString WelcomeTitle ${LANG_POLISH} "Witamy w instalatorze NexusAI"
LangString WelcomeText ${LANG_POLISH} "Ten kreator przeprowadzi Cię przez instalację NexusAI.$\r$\n$\r$\n\
    NexusAI to system księgowy z AI działający w całości lokalnie.$\r$\n$\r$\n\
    Kliknij $_CLICK, aby kontynuować."

LangString FinishTitle ${LANG_ENGLISH} "NexusAI Setup Complete"
LangString FinishText ${LANG_ENGLISH} "NexusAI has been installed successfully.$\r$\n$\r$\n\
    On first launch, AI models will be downloaded automatically.$\r$\n\
    This may take a few minutes depending on your internet connection."

LangString FinishTitle ${LANG_POLISH} "Instalacja NexusAI zakończona"
LangString FinishText ${LANG_POLISH} "NexusAI został zainstalowany pomyślnie.$\r$\n$\r$\n\
    Przy pierwszym uruchomieniu modele AI zostaną pobrane automatycznie.$\r$\n\
    Może to potrwać kilka minut w zależności od połączenia internetowego."

; ── Installer initialization ────────────────────────────────────────────────

Function .onInit
    ; Check if already installed
    ReadRegStr $R0 HKLM "${PRODUCT_UNINSTALL_KEY}" "UninstallString"
    StrCmp $R0 "" done

    MessageBox MB_OKCANCEL|MB_ICONEXCLAMATION \
        "${PRODUCT_NAME} is already installed. $\n$\n\
        Click `OK` to remove the previous version first." \
        IDOK uninstall
    Abort

uninstall:
    ; Run uninstaller silently
    ExecWait '$R0 /S _?=$INSTDIR'
    Sleep 3000
done:
FunctionEnd

; ── Uninstaller section ─────────────────────────────────────────────────────

Section "Uninstall"
    ; Remove shortcuts
    Delete "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}\${PRODUCT_NAME}.lnk"
    Delete "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}\${PRODUCT_NAME} (CLI).lnk"
    Delete "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}\Uninstall ${PRODUCT_NAME}.lnk"
    RmDir "$SMPROGRAMS\${PRODUCT_STARTMENU_FOLDER}"
    Delete "$DESKTOP\${PRODUCT_NAME}.lnk"
    Delete "$SMSTARTUP\${PRODUCT_NAME}.lnk"

    ; Remove application files
    RmDir /r "$INSTDIR"

    ; Remove registry entries
    DeleteRegKey HKLM "${PRODUCT_UNINSTALL_KEY}"
    DeleteRegValue HKLM "SYSTEM\CurrentControlSet\Control\Session Manager\Environment" "NEXUSAI_DATA"

    ; Ask about removing user data
    MessageBox MB_YESNO|MB_ICONQUESTION \
        "Remove your personal data and settings?$\n$\n\
        (Models, databases, and configuration files in %APPDATA%)" \
        IDNO done

    RmDir /r "$APPDATA\${PRODUCT_NAME}"

done:
SectionEnd

; ── Custom uninstaller language strings ─────────────────────────────────────

LangString unConfirmTitle ${LANG_ENGLISH} "Uninstall NexusAI"
LangString unConfirmText ${LANG_ENGLISH} "Are you sure you want to completely remove NexusAI?"

LangString unConfirmTitle ${LANG_POLISH} "Odinstaluj NexusAI"
LangString unConfirmText ${LANG_POLISH} "Czy na pewno chcesz całkowicie usunąć NexusAI?"
