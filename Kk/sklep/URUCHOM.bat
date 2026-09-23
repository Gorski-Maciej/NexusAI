@echo off
setlocal
chcp 65001 >nul
title ChemiaMax - Sklep Kiosk
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

rem -- 3. Biblioteki sklepu - instaluja sie tylko przy PIERWSZYCH starcie
if not exist node_modules (
  echo  [1/2] Instaluje biblioteki sklepu - npm install
  echo        Pierwszy start trwa 1-2 minuty, czekaj...
  echo.
  call npm install --no-audit --no-fund
  if errorlevel 1 (
    echo.
    echo  [BLAD] npm install nie powiodl sie - sprawdz internet i sprobuj ponownie.
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
echo      Nie instaluj Node.js na szkolnym komputerze - zwykle brakuje
echo      praw administratora i stracisz czas.
echo.
echo      Uruchom sklep w maszynie wirtualnej - patrz instrukcja:
echo        INSTRUKCJA_EMAIL_VSCODE.md  -^>  ETAP 6 - MASZYNA WIRTUALNA
echo.
echo      To okno mozesz juz zamknac.
pause
exit /b 1
