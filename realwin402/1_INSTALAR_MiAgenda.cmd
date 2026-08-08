@echo off
setlocal EnableExtensions
chcp 65001 >nul 2>nul
title Mi Agenda 4.0.2 - Instalador

set "SRC=%~dp0"
set "APP=%LOCALAPPDATA%\MiAgenda-App"
set "PS=%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe"

if not defined LOCALAPPDATA set "APP=%USERPROFILE%\AppData\Local\MiAgenda-App"

echo ==============================================
echo         MI AGENDA 4.0.2 - INSTALADOR
echo ==============================================
echo.

if not exist "%PS%" (
  echo ERROR: No se encontro Windows PowerShell 5.1.
  echo Ruta esperada:
  echo %PS%
  echo.
  pause
  exit /b 2
)

if not exist "%SRC%MiAgenda.ps1" (
  echo ERROR: No se encontro MiAgenda.ps1 junto al instalador.
  echo.
  echo Esto normalmente ocurre cuando se intenta ejecutar el instalador
  echo directamente desde dentro del archivo ZIP.
  echo.
  echo SOLUCION:
  echo 1. Cierra esta ventana.
  echo 2. Haz clic derecho al ZIP y selecciona "Extraer todo".
  echo 3. Abre la carpeta INSTALAR ya extraida.
  echo 4. Ejecuta otra vez 1_INSTALAR_MiAgenda.cmd.
  echo.
  echo Carpeta desde la que Windows lo intento ejecutar:
  echo %SRC%
  echo.
  pause
  exit /b 10
)

if not exist "%APP%" md "%APP%"
if not exist "%APP%" (
  echo ERROR: Windows no permitio crear la carpeta de instalacion:
  echo %APP%
  echo.
  pause
  exit /b 11
)

echo [1/4] Copiando Mi Agenda...
copy /Y "%SRC%MiAgenda.ps1" "%APP%\MiAgenda.ps1" >nul
if errorlevel 1 (
  echo ERROR: No se pudo copiar MiAgenda.ps1 a:
  echo %APP%
  echo.
  pause
  exit /b 12
)

> "%APP%\ABRIR_MiAgenda.cmd" echo @echo off
>>"%APP%\ABRIR_MiAgenda.cmd" echo setlocal
>>"%APP%\ABRIR_MiAgenda.cmd" echo set "PS=%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe"
>>"%APP%\ABRIR_MiAgenda.cmd" echo if not exist "%%PS%%" ^(echo No se encontro Windows PowerShell.^& pause^& exit /b 2^)
>>"%APP%\ABRIR_MiAgenda.cmd" echo "%%PS%%" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%%~dp0MiAgenda.ps1"
>>"%APP%\ABRIR_MiAgenda.cmd" echo set "RC=%%ERRORLEVEL%%"
>>"%APP%\ABRIR_MiAgenda.cmd" echo if not "%%RC%%"=="0" ^(echo.^& echo Mi Agenda termino con error %%RC%%.^& pause^)
>>"%APP%\ABRIR_MiAgenda.cmd" echo exit /b %%RC%%

> "%APP%\SINCRONIZAR_AHORA.cmd" echo @echo off
>>"%APP%\SINCRONIZAR_AHORA.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%%~dp0MiAgenda.ps1" -SyncOnly
>>"%APP%\SINCRONIZAR_AHORA.cmd" echo if errorlevel 1 pause

> "%APP%\DIAGNOSTICO_MiAgenda.cmd" echo @echo off
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo chcp 65001 ^>nul 2^>nul
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo ==============================================
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo       MI AGENDA - DIAGNOSTICO WINDOWS
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo ==============================================
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo.
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo APP=%%~dp0
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo LOCALAPPDATA=%%LOCALAPPDATA%%
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo POWERSHELL=%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo.
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo if not exist "%%~dp0MiAgenda.ps1" echo ERROR: Falta MiAgenda.ps1
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo if not exist "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" echo ERROR: Falta Windows PowerShell
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo.
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%%~dp0MiAgenda.ps1"
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo.
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo echo Codigo de salida: %%ERRORLEVEL%%
>>"%APP%\DIAGNOSTICO_MiAgenda.cmd" echo pause

> "%APP%\DESINSTALAR_MiAgenda.cmd" echo @echo off
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo setlocal
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo "%%SystemRoot%%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -Command "$p=[Environment]::GetFolderPath('Desktop');Remove-Item -LiteralPath (Join-Path $p 'Mi Agenda.lnk') -Force -ErrorAction SilentlyContinue"
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo echo Los datos personales de la agenda NO se borran.
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo echo Para borrar solo la aplicacion, cierra Mi Agenda y elimina esta carpeta:
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo echo %%LOCALAPPDATA%%\MiAgenda-App
>>"%APP%\DESINSTALAR_MiAgenda.cmd" echo pause

echo [2/4] Verificando que los archivos instalados existan...
for %%F in ("%APP%\MiAgenda.ps1" "%APP%\ABRIR_MiAgenda.cmd" "%APP%\SINCRONIZAR_AHORA.cmd" "%APP%\DIAGNOSTICO_MiAgenda.cmd") do (
  if not exist %%F (
    echo ERROR: Falta el archivo %%~nxF
    pause
    exit /b 13
  )
)

echo [3/4] Probando el motor de Mi Agenda...
"%PS%" -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File "%APP%\MiAgenda.ps1" -SyncOnly
if errorlevel 1 (
  echo.
  echo ERROR: El motor de Mi Agenda no supero la prueba inicial.
  echo Ejecuta despues:
  echo %APP%\DIAGNOSTICO_MiAgenda.cmd
  echo.
  pause
  exit /b 14
)

echo [4/4] Creando acceso directo en el Escritorio...
"%PS%" -NoLogo -NoProfile -Command "$ErrorActionPreference='Stop';$app=$env:LOCALAPPDATA+'\MiAgenda-App';if(-not $env:LOCALAPPDATA){$app=$env:USERPROFILE+'\AppData\Local\MiAgenda-App'};$desktop=[Environment]::GetFolderPath('Desktop');$shell=New-Object -ComObject WScript.Shell;$lnk=$shell.CreateShortcut((Join-Path $desktop 'Mi Agenda.lnk'));$lnk.TargetPath=(Join-Path $app 'ABRIR_MiAgenda.cmd');$lnk.WorkingDirectory=$app;$lnk.IconLocation=$env:SystemRoot+'\System32\shell32.dll,44';$lnk.Save()"
if errorlevel 1 (
  echo AVISO: No se pudo crear el acceso directo.
  echo Puedes abrir la agenda directamente desde:
  echo %APP%\ABRIR_MiAgenda.cmd
)

echo.
echo ==============================================
echo            INSTALACION CORRECTA
echo ==============================================
echo.
echo Aplicacion instalada en:
echo %APP%
echo.
echo Se abrira Mi Agenda ahora.
echo.
start "" "%APP%\ABRIR_MiAgenda.cmd"
timeout /t 2 /nobreak >nul
exit /b 0
