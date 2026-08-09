@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>nul
title Mi Agenda 5.0 - Instalador

set "SRC=%~dp0"
set "APP=%LOCALAPPDATA%\MiAgenda-App"
set "DATA=%LOCALAPPDATA%\MiAgendaSegura"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"
set "EXPECTED=de2f109fec91a9d5f99e00f59da8c2fdff198b3ec1f3a8f3d19dc4372d5178e8"
set "HASHFILE=%TEMP%\MiAgenda_source_hash_%RANDOM%.txt"
set "INSTHASH=%TEMP%\MiAgenda_installed_hash_%RANDOM%.txt"

echo ==========================================================
echo            MI AGENDA 5.0 - INSTALACION SEGURA
echo ==========================================================
echo.
echo Esta instalacion NO elimina tus datos personales.
echo Los datos se conservan en:
echo %DATA%
echo.

if not exist "%SRC%MiAgenda.ps1" (
  echo ERROR: No se encontro MiAgenda.ps1 junto al instalador.
  echo.
  echo Haz clic derecho al ZIP, elige EXTRAER TODO y vuelve a ejecutar
  echo este instalador desde la carpeta INSTALAR extraida.
  pause
  exit /b 10
)

if not exist "%PS%" (
  echo ERROR: Windows PowerShell 5.1 no esta disponible en este equipo.
  pause
  exit /b 11
)

echo [1/8] Comprobando integridad del archivo original...
set "CHECKFILE=%SRC%MiAgenda.ps1"
set "OUTFILE=%HASHFILE%"
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$h=(Get-FileHash -LiteralPath $env:CHECKFILE -Algorithm SHA256).Hash.ToLowerInvariant();[IO.File]::WriteAllText($env:OUTFILE,$h,[Text.Encoding]::ASCII)"
if errorlevel 1 goto :hasherror
set /p SOURCEHASH=<"%HASHFILE%"
del /q "%HASHFILE%" >nul 2>nul
if /I not "%SOURCEHASH%"=="%EXPECTED%" (
  echo ERROR: El archivo no coincide con la version 5.0 verificada.
  echo Esperado: %EXPECTED%
  echo Obtenido: %SOURCEHASH%
  pause
  exit /b 12
)
findstr /L /C:"return$b" "%SRC%MiAgenda.ps1" >nul 2>nul
if not errorlevel 1 (
  echo ERROR: Se detecto el error antiguo return$b. Esta copia no se instalara.
  pause
  exit /b 13
)

echo [2/8] Validando sintaxis con Windows PowerShell 5.1...
set "CHECKFILE=%SRC%MiAgenda.ps1"
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$t=$null;$e=$null;[System.Management.Automation.Language.Parser]::ParseFile($env:CHECKFILE,[ref]$t,[ref]$e)|Out-Null;if($e.Count -gt 0){$e|%%{Write-Host ('Linea '+$_.Extent.StartLineNumber+': '+$_.Message)};exit 1}"
if errorlevel 1 (
  echo ERROR: La version descargada no supero la validacion de sintaxis.
  pause
  exit /b 14
)

echo [3/8] Probando el motor local cifrado...
"%PS%" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%SRC%MiAgenda.ps1" -SyncOnly
if errorlevel 1 (
  echo ERROR: La prueba interna de Mi Agenda fallo.
  echo Tus datos no han sido eliminados.
  pause
  exit /b 15
)

echo [4/8] Reemplazando solamente los archivos del programa...
if exist "%APP%" rmdir /S /Q "%APP%"
if exist "%APP%" (
  echo ERROR: No se pudo reemplazar la version anterior.
  echo Cierra Mi Agenda si esta abierta y vuelve a intentarlo.
  pause
  exit /b 16
)
mkdir "%APP%" >nul 2>nul
if not exist "%APP%" (
  echo ERROR: No se pudo crear la carpeta de instalacion.
  pause
  exit /b 17
)
copy /B /Y "%SRC%MiAgenda.ps1" "%APP%\MiAgenda.ps1" >nul
if errorlevel 1 (
  echo ERROR: No se pudo copiar el programa.
  pause
  exit /b 18
)

echo [5/8] Verificando la copia instalada...
set "CHECKFILE=%APP%\MiAgenda.ps1"
set "OUTFILE=%INSTHASH%"
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$h=(Get-FileHash -LiteralPath $env:CHECKFILE -Algorithm SHA256).Hash.ToLowerInvariant();[IO.File]::WriteAllText($env:OUTFILE,$h,[Text.Encoding]::ASCII)"
if errorlevel 1 goto :hasherror
set /p INSTALLEDHASH=<"%INSTHASH%"
del /q "%INSTHASH%" >nul 2>nul
if /I not "%INSTALLEDHASH%"=="%EXPECTED%" (
  echo ERROR: La copia instalada no coincide con el original.
  pause
  exit /b 19
)
findstr /L /C:"return$b" "%APP%\MiAgenda.ps1" >nul 2>nul
if not errorlevel 1 (
  echo ERROR: Se encontro una copia antigua despues de instalar.
  pause
  exit /b 20
)

echo [6/8] Creando accesos seguros...
>"%APP%\ABRIR_MiAgenda.cmd" echo @echo off
>>"%APP%\ABRIR_MiAgenda.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%%~dp0MiAgenda.ps1"
>>"%APP%\ABRIR_MiAgenda.cmd" echo if errorlevel 1 ^(echo.^& echo Mi Agenda termino con error %%ERRORLEVEL%%.^& pause^)

>"%APP%\SINCRONIZAR_AHORA.cmd" echo @echo off
>>"%APP%\SINCRONIZAR_AHORA.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%%~dp0MiAgenda.ps1" -SyncOnly

>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo @echo off
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo ===== DIAGNOSTICO MI AGENDA 5.0 =====
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo Carpeta: %%~dp0
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -Command "Get-FileHash -LiteralPath '%%~dp0MiAgenda.ps1' -Algorithm SHA256; $t=$null;$e=$null;[System.Management.Automation.Language.Parser]::ParseFile('%%~dp0MiAgenda.ps1',[ref]$t,[ref]$e)^|Out-Null; if($e.Count){$e^|Format-List *}else{Write-Host 'Sintaxis: OK'}"
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo pause

>"%APP%\DESINSTALAR_MiAgenda.cmd" echo @echo off
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo echo Esto elimina el PROGRAMA, pero conserva tus datos en %%LOCALAPPDATA%%\MiAgendaSegura.
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo pause
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo schtasks /Delete /TN "Mi Agenda - Sincronizacion" /F ^>nul 2^>nul
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo del /q "%%USERPROFILE%%\Desktop\Mi Agenda.lnk" ^>nul 2^>nul
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo start "" cmd /c "timeout /t 2 /nobreak ^>nul ^& rmdir /S /Q \"%%LOCALAPPDATA%%\MiAgenda-App\""

set "APPDIR=%APP%"
"%PS%" -NoLogo -NoProfile -ExecutionPolicy Bypass -Command "$desktop=[Environment]::GetFolderPath('Desktop');$w=New-Object -ComObject WScript.Shell;$l=$w.CreateShortcut((Join-Path $desktop 'Mi Agenda.lnk'));$l.TargetPath=(Join-Path $env:APPDIR 'ABRIR_MiAgenda.cmd');$l.WorkingDirectory=$env:APPDIR;$l.IconLocation=$env:SystemRoot+'\System32\shell32.dll,44';$l.Save()"

echo [7/8] Configurando sincronizacion periodica opcional...
schtasks /Create /TN "Mi Agenda - Sincronizacion" /SC MINUTE /MO 15 /TR "\"%APP%\SINCRONIZAR_AHORA.cmd\"" /F >nul 2>nul
if errorlevel 1 (
  echo Aviso: Windows no permitio crear la tarea automatica.
  echo Mi Agenda igualmente sincronizara mientras este abierta.
) else (
  echo Sincronizacion periodica configurada cada 15 minutos.
)

echo [8/8] Finalizando...
echo.
echo ==========================================================
echo           MI AGENDA 5.0 INSTALADA CORRECTAMENTE
echo ==========================================================
echo.
echo Version verificada: %INSTALLEDHASH%
echo Programa: %APP%
echo Datos personales: %DATA%
echo.
echo La interfaz rosa aprobada se abrira ahora.
timeout /t 2 /nobreak >nul
start "" "%APP%\ABRIR_MiAgenda.cmd"
exit /b 0

:hasherror
echo ERROR: No fue posible comprobar la integridad del archivo.
del /q "%HASHFILE%" "%INSTHASH%" >nul 2>nul
pause
exit /b 21
