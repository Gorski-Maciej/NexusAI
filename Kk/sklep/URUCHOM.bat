@echo off
setlocal
chcp 65001 >nul
title ChemiaMax - Sklep Kiosk

rem -- NAJWAZNIEJSZE: przejdz do katalogu tego pliku (dziala tez z pulpitu/ZIP)
cd /d "%~dp0"
if not exist package.json (
  echo  [BLAD] Brak package.json - uruchom ten plik z katalogu sklep.
  pause
  exit /b 1
)

echo.
echo  ==============================================
echo    ChemiaMax - sklep kiosk  ^|  localhost:3000
echo  ==============================================
echo.

rem -- 1. Czy Node.js jest na tym komputerze?
where node >nul 2>nul
if errorlevel 1 goto brak_node

rem -- 2. Czy sklep juz dziala (port 3000)?
netstat -ano 2>nul | findstr /C:":3000 " | findstr "LISTENING" >nul
if not errorlevel 1 (
  echo  [i] Sklep JUZ dziala - otwieram przegladarke...
  start "" http://localhost:3000
  timeout /t 2 /nobreak >nul
  exit /b 0
)

rem -- 3. Biblioteki sklepu - instaluja sie tylko przy PIERWSZYM starcie
if not exist node_modules (
  echo  [1/2] Pierwszy start: instaluje biblioteki sklepu ^(npm install^)
  echo        Trwa to 1-2 minuty, czekaj...
  echo.
  call npm install --no-audit --no-fund
  if errorlevel 1 (
    echo.
    echo  [BLAD] npm install nie powiodl sie - zwykle brak internetu.
    echo         Alternatywa: wyslij ZIP z folderem node_modules w srodku.
    pause
    exit /b 1
  )
)

rem -- 4. Start sklepu + automatyczne otwarcie przegladarki
echo  [2/2] Startuje sklep...
echo        Przegladarka otworzy sie SAMA na adres:  http://localhost:3000
echo        Zatrzymanie sklepu: Ctrl+C w tym oknie
echo.
start "" cmd /c "timeout /t 6 /nobreak >nul & start "" http://localhost:3000"
call npm start
echo.
echo  Sklep zatrzymany. Zamknij okno albo uruchom ponownie - URUCHOM.bat
pause
exit /b 0

:brak_node
echo  [!] NA TYM KOMPUTERZE NIE MA NODE.JS - nie da sie tu uruchomic sklepu.
echo.
echo      Nie probuj instalowac Node.js na szkolnym komputerze - zwykle
echo      brakuje praw administratora i stracisz czas.
echo.
echo      URUCHOM SKLEP W MASZYNIE WIRTUALNEJ (plan B, masz go na pendrive):
echo        1. Otworz VirtualBox i uruchom maszyne Ubuntu
echo           (login uczen, haslo admin1234)
echo        2. Przegraj folder sklep do maszyny
echo           (np. przez HTTP:  cd sklep ^&^& python3 -m http.server 8000)
echo        3. W maszynie:  wget -r -np -nH -R index.html http://IP_KOMPUTERA:8000
echo           albo przez shared folder / pendrive
echo        4. W maszynie:  cd sklep ^&^& bash start.sh
echo        5. Otworz w przegladarce maszyny:  http://localhost:3000
echo.
echo      Detale: INSTRUKCJA_EMAIL_VSCODE.md  ->  sekcja PROBLEMY pkt 1
echo.
echo      To okno mozesz juz zamknac.
pause
exit /b 1
