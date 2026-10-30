@echo off
setlocal
chcp 65001 >nul
title PRUEBA DIRECTA - Mi Agenda 5.1
if not exist "%~dp0MiAgendaLauncher.ps1" (
 echo Faltan archivos. Extrae el ZIP completo.
 pause
 exit /b 2
)
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0MiAgendaLauncher.ps1"
