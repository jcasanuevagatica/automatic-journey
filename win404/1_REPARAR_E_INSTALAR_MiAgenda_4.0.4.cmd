@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>nul
title Mi Agenda 4.0.4 - Reparar e instalar
set "SRC=%~dp0"
set "APP=%LOCALAPPDATA%\MiAgenda-App"
if not defined LOCALAPPDATA set "APP=%USERPROFILE%\AppData\Local\MiAgenda-App"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "EXPECTED=af1c77752e8c7eb3e139c70423a1d9f7f91289ae019a8887f5cb1367e0dc7e48"
set "MIAGENDA_SOURCE=%SRC%MiAgenda.ps1"
set "MIAGENDA_INSTALLED=%APP%\MiAgenda.ps1"
set "HASH1=%TEMP%\MiAgenda_source_hash.txt"
set "HASH2=%TEMP%\MiAgenda_installed_hash.txt"

echo ==============================================
echo      MI AGENDA 4.0.4 - REPARAR E INSTALAR
echo ==============================================
echo.

if not exist "%MIAGENDA_SOURCE%" (
  echo ERROR: Falta MiAgenda.ps1 en esta carpeta.
  echo Debes EXTRAER TODO el ZIP antes de ejecutar este archivo.
  pause
  exit /b 10
)
if not exist "%PS%" (
  echo ERROR: No se encontro Windows PowerShell 5.1.
  pause
  exit /b 11
)

echo [1/7] Verificando el archivo nuevo antes de instalar...
del /Q "%HASH1%" >nul 2>nul
"%PS%" -NoLogo -NoProfile -Command "(Get-FileHash -LiteralPath $env:MIAGENDA_SOURCE -Algorithm SHA256).Hash.ToLowerInvariant() | Set-Content -LiteralPath $env:HASH1 -NoNewline -Encoding ascii"
if errorlevel 1 (
  echo ERROR: No se pudo calcular el SHA-256 del archivo nuevo.
  pause
  exit /b 12
)
set /p SOURCEHASH=<"%HASH1%"
if /I not "%SOURCEHASH%"=="%EXPECTED%" (
  echo ERROR: El archivo nuevo no coincide con la version verificada.
  echo Esperado: %EXPECTED%
  echo Obtenido: %SOURCEHASH%
  pause
  exit /b 13
)
findstr /L /C:"return$b" "%MIAGENDA_SOURCE%" >nul 2>nul
if not errorlevel 1 (
  echo ERROR: El paquete todavia contiene return$b. No se instalara.
  pause
  exit /b 14
)

echo [2/7] Cerrando la version anterior...
taskkill /F /IM powershell.exe /FI "WINDOWTITLE eq Mi Agenda*" >nul 2>nul

echo [3/7] Eliminando la copia anterior de la aplicacion...
if exist "%APP%" rmdir /S /Q "%APP%"
if exist "%APP%" (
  echo ERROR: No se pudo eliminar la copia anterior:
  echo %APP%
  echo Cierra Mi Agenda y vuelve a intentarlo.
  pause
  exit /b 15
)
mkdir "%APP%" >nul 2>nul
if not exist "%APP%" (
  echo ERROR: No se pudo crear la carpeta de instalacion.
  pause
  exit /b 16
)

echo [4/7] Copiando la version corregida...
copy /B /Y "%MIAGENDA_SOURCE%" "%MIAGENDA_INSTALLED%" >nul
if errorlevel 1 (
  echo ERROR: No se pudo copiar MiAgenda.ps1.
  pause
  exit /b 17
)
del /Q "%HASH2%" >nul 2>nul
"%PS%" -NoLogo -NoProfile -Command "(Get-FileHash -LiteralPath $env:MIAGENDA_INSTALLED -Algorithm SHA256).Hash.ToLowerInvariant() | Set-Content -LiteralPath $env:HASH2 -NoNewline -Encoding ascii"
if errorlevel 1 (
  echo ERROR: No se pudo calcular el SHA-256 instalado.
  pause
  exit /b 18
)
set /p INSTALLEDHASH=<"%HASH2%"
if /I not "%INSTALLEDHASH%"=="%EXPECTED%" (
  echo ERROR: Windows no copio correctamente la version nueva.
  echo Esperado: %EXPECTED%
  echo Instalado: %INSTALLEDHASH%
  pause
  exit /b 19
)
findstr /L /C:"return$b" "%MIAGENDA_INSTALLED%" >nul 2>nul
if not errorlevel 1 (
  echo ERROR: La copia instalada conserva return$b.
  pause
  exit /b 20
)

echo [5/7] Validando sintaxis...
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$t=$null;$e=$null;[System.Management.Automation.Language.Parser]::ParseFile($env:MIAGENDA_INSTALLED,[ref]$t,[ref]$e)|Out-Null;if($e.Count -gt 0){$e|Format-List *;exit 1}"
if errorlevel 1 (
  echo ERROR: La sintaxis no paso la validacion.
  pause
  exit /b 21
)

echo [6/7] Probando el motor...
"%PS%" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%MIAGENDA_INSTALLED%" -SyncOnly
if errorlevel 1 (
  echo ERROR: La prueba interna fallo.
  pause
  exit /b 22
)

> "%APP%\ABRIR_MiAgenda.cmd" echo @echo off
>>"%APP%\ABRIR_MiAgenda.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%%~dp0MiAgenda.ps1"
>>"%APP%\ABRIR_MiAgenda.cmd" echo if errorlevel 1 ^(echo.^& echo Mi Agenda termino con error %%ERRORLEVEL%%.^& pause^)

> "%APP%\REVISAR_VERSION.cmd" echo @echo off
>>"%APP%\REVISAR_VERSION.cmd" echo echo Debe aparecer una linea que contenga: return $b
>>"%APP%\REVISAR_VERSION.cmd" echo findstr /N /L /C:"return $b" "%%~dp0MiAgenda.ps1"
>>"%APP%\REVISAR_VERSION.cmd" echo echo.
>>"%APP%\REVISAR_VERSION.cmd" echo echo NO debe aparecer return$b pegado.
>>"%APP%\REVISAR_VERSION.cmd" echo findstr /N /L /C:"return$b" "%%~dp0MiAgenda.ps1"
>>"%APP%\REVISAR_VERSION.cmd" echo pause

echo [7/7] Creando acceso directo...
set "MIAGENDA_APP=%APP%"
"%PS%" -NoLogo -NoProfile -Command "$desktop=[Environment]::GetFolderPath('Desktop');$w=New-Object -ComObject WScript.Shell;$l=$w.CreateShortcut((Join-Path $desktop 'Mi Agenda.lnk'));$l.TargetPath=(Join-Path $env:MIAGENDA_APP 'ABRIR_MiAgenda.cmd');$l.WorkingDirectory=$env:MIAGENDA_APP;$l.IconLocation=$env:SystemRoot+'\System32\shell32.dll,44';$l.Save()"

echo.
echo ==============================================
echo       INSTALACION 4.0.4 CORRECTA
echo ==============================================
echo.
echo Hash instalado: %INSTALLEDHASH%
echo Carpeta: %APP%
echo.
echo Se abrira Mi Agenda.
timeout /t 2 /nobreak >nul
start "" "%APP%\ABRIR_MiAgenda.cmd"
exit /b 0
