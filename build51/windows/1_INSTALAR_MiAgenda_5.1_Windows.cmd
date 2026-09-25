@echo off
setlocal EnableExtensions
chcp 65001 >nul
color F5
title INSTALACION - Mi Agenda 5.1
set "SRC=%~dp0"
set "APP=%LOCALAPPDATA%\MiAgenda-5.1"
set "DATADIR=%LOCALAPPDATA%\MiAgendaDatos"
if not defined LOCALAPPDATA (
  set "APP=%USERPROFILE%\AppData\Local\MiAgenda-5.1"
  set "DATADIR=%USERPROFILE%\AppData\Local\MiAgendaDatos"
)
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

echo.
echo ===============================================
echo       MI AGENDA 5.1 - INSTALACION WINDOWS
echo ===============================================
echo.
echo [1/6] Revisando archivos...
if not exist "%SRC%MiAgenda.html" goto :missing
if not exist "%SRC%MiAgendaLauncher.ps1" goto :missing
if not exist "%SRC%ABRIR_MiAgenda.vbs" goto :missing
if not exist "%SRC%datos_oficiales_iniciales.json" goto :missing

echo [2/6] Instalando aplicacion...
rem Solo se reemplaza la carpeta del programa. Los datos personales viven en MiAgendaDatos.
if exist "%APP%" rmdir /S /Q "%APP%" >nul 2>&1
if exist "%APP%" goto :fail
mkdir "%APP%" >nul 2>&1
if not exist "%APP%" goto :fail
copy /B /Y "%SRC%MiAgenda.html" "%APP%\MiAgenda.html" >nul || goto :fail
copy /B /Y "%SRC%MiAgendaLauncher.ps1" "%APP%\MiAgendaLauncher.ps1" >nul || goto :fail
copy /B /Y "%SRC%ABRIR_MiAgenda.vbs" "%APP%\ABRIR_MiAgenda.vbs" >nul || goto :fail
copy /B /Y "%SRC%datos_oficiales_iniciales.json" "%APP%\datos_oficiales_iniciales.json" >nul || goto :fail

echo [3/6] Verificando script...
set "APP_TO_TEST=%APP%\MiAgendaLauncher.ps1"
set "APPDIR=%APP%"
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; [void][scriptblock]::Create((Get-Content -LiteralPath $env:APP_TO_TEST -Raw -Encoding UTF8))" 2>nul
if errorlevel 1 goto :parsefail

echo [4/6] Creando acceso directo...
"%PS%" -NoProfile -ExecutionPolicy Bypass -Command "$d=[Environment]::GetFolderPath('Desktop');$w=New-Object -ComObject WScript.Shell;$s=$w.CreateShortcut((Join-Path $d 'Mi Agenda.lnk'));$s.TargetPath=(Join-Path $env:SystemRoot 'System32\wscript.exe');$s.Arguments='""'+(Join-Path $env:APPDIR 'ABRIR_MiAgenda.vbs')+'""';$s.WorkingDirectory=$env:APPDIR;$s.Description='Mi Agenda 5.1';$s.Save()" >nul 2>&1

echo [5/6] Probando instalacion...
"%PS%" -NoProfile -ExecutionPolicy Bypass -File "%APP%\MiAgendaLauncher.ps1" -NoUpdate -NoLaunch
if errorlevel 1 goto :smokefail
if not exist "%DATADIR%\MiAgenda_runtime.html" goto :smokefail

echo [6/6] Abriendo Mi Agenda...
if not defined MIAGENDA_TEST start "" wscript.exe "%APP%\ABRIR_MiAgenda.vbs"
echo.
echo INSTALACION COMPLETADA.
echo Se creo el acceso directo "Mi Agenda" en el Escritorio.
echo Tus datos se guardan aparte en MiAgendaDatos y no se borran al reinstalar.
echo.
if defined MIAGENDA_TEST exit /b 0
timeout /t 3 >nul
exit /b 0

:missing
echo ERROR: faltan archivos. Extrae el ZIP completo antes de instalar.
if defined MIAGENDA_TEST exit /b 2
pause
exit /b 2

:parsefail
echo ERROR: el script de inicio no supero la revision de sintaxis.
if defined MIAGENDA_TEST exit /b 3
pause
exit /b 3

:smokefail
echo ERROR: la aplicacion se copio, pero no supero la prueba de inicio.
if defined MIAGENDA_TEST exit /b 5
pause
exit /b 5

:fail
echo ERROR: Windows no pudo copiar los archivos de Mi Agenda.
if defined MIAGENDA_TEST exit /b 4
pause
exit /b 4
